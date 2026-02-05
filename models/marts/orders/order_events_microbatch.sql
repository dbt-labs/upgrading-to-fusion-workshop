{{
  config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='order_id',
    description='High-frequency event stream processing model'
  )
}}

-- Event-driven order processing with time-based batching
-- Processes orders in daily batches for optimal performance

with order_events as (
    select
        order_id,
        customer_id,
        location_id,
        ordered_at as event_timestamp,
        'order_placed' as event_type,
        order_total as event_value,
        
        -- Generate additional event metadata for microbatch processing
        date_trunc('hour', ordered_at) as event_hour,
        extract(epoch from ordered_at) as event_epoch,
        row_number() over (partition by order_id order by ordered_at) as event_sequence
        
    from {{ ref('orders') }}
    
    {% if is_incremental() %}
        -- Standard incremental filter (would be microbatch in production)
        where ordered_at > (select max(event_timestamp) from {{ this }})
    {% endif %}
),

-- Simulate derived events that would be common in streaming architectures
derived_events as (
    select
        order_id,
        customer_id,
        location_id,
        dateadd('minute', 5, event_timestamp) as event_timestamp,
        'payment_processed' as event_type,
        event_value,
        event_hour,
        event_epoch + 300 as event_epoch,
        event_sequence + 1 as event_sequence
        
    from order_events
    
    union all
    
    select
        order_id,
        customer_id,
        location_id,
        dateadd('hour', 1, event_timestamp) as event_timestamp,
        'order_fulfilled' as event_type,
        event_value,
        dateadd('hour', 1, event_hour) as event_hour,
        event_epoch + 3600 as event_epoch,
        event_sequence + 2 as event_sequence
        
    from order_events
),

-- Combine all events for microbatch processing
all_events as (
    select * from order_events
    union all
    select * from derived_events
),

-- Add microbatch-specific aggregations and window functions
final_events as (
    select
        *,
        
        -- Microbatch-specific metrics that leverage the hourly batching
        count(*) over (
            partition by event_hour, event_type
        ) as events_in_batch,
        
        sum(event_value) over (
            partition by event_hour
            order by event_timestamp
            rows between unbounded preceding and current row
        ) as running_total_in_batch,
        
        -- Flag late-arriving events (common in streaming scenarios)
        case 
            when event_timestamp < event_hour then true
            else false
        end as is_late_event,
        
        -- Microbatch processing metadata
        current_timestamp as batch_processed_at,
        '{{ run_started_at }}' as batch_run_id
        
    from all_events
)

select * from final_events
