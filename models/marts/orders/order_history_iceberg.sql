{{
  config(
    materialized='table',
    description='Historical order data that would use Iceberg table format in production - '
  )
}}

-- Iceberg tables provide advanced features like time travel, schema evolution, and optimized performance

with orders_base as (
    select * from {{ ref('orders') }}
),

order_items as (
    select * from {{ ref('order_items') }}
),

customers as (
    select * from {{ ref('customers') }}
),

-- Enhanced order history with Iceberg-specific optimizations
order_history as (
    select
        o.order_id,
        o.customer_id,
        o.location_id,
        o.ordered_at,
        date_trunc('day', o.ordered_at) as order_date,  -- Iceberg partition key
        
        -- Order financials
        o.subtotal,
        o.tax_paid,
        o.order_total,
        
        -- Customer context
        c.customer_name,
        c.customer_type,
        c.first_ordered_at,
        c.lifetime_spend,
        
        -- Order item aggregations
        count(oi.order_item_id) as item_count,
        sum(oi.product_price) as total_product_value,
        
        -- Iceberg-optimized analytical columns
        row_number() over (partition by o.customer_id order by o.ordered_at) as customer_order_sequence,
        lag(o.ordered_at) over (partition by o.customer_id order by o.ordered_at) as previous_order_date,
        lead(o.ordered_at) over (partition by o.customer_id order by o.ordered_at) as next_order_date,
        
        -- Time-based analytics for Iceberg time travel queries
        extract(year from o.ordered_at) as order_year,
        extract(month from o.ordered_at) as order_month,
        extract(quarter from o.ordered_at) as order_quarter,
        extract(dayofweek from o.ordered_at) as order_day_of_week,
        
        -- Data versioning for Iceberg schema evolution
        current_timestamp as record_created_at,
        '{{ run_started_at }}' as dbt_run_id,
        'v2.0' as schema_version,
        
        -- Iceberg-specific metadata columns
        case 
            when o.order_total > 1000 then 'high_value'
            when o.order_total > 500 then 'medium_value'
            else 'standard_value'
        end as order_value_tier,
        
        -- Complex nested data that would benefit from Iceberg's schema evolution
        -- Using Snowflake-compatible JSON construction
        object_construct(
            'order_metrics',
            object_construct(
                'subtotal', o.subtotal,
                'tax_paid', o.tax_paid,
                'item_count', count(oi.order_item_id)
            ),
            'customer_metrics',
            object_construct(
                'customer_type', c.customer_type,
                'lifetime_orders', c.count_lifetime_orders,
                'lifetime_value', c.lifetime_spend
            )
        ) as order_metadata_json
        
    from orders_base o
    left join customers c on o.customer_id = c.customer_id
    left join order_items oi on o.order_id = oi.order_id
    group by 
        o.order_id,
        o.customer_id,
        o.location_id,
        o.ordered_at,
        o.subtotal,
        o.tax_paid,
        o.order_total,
        c.customer_name,
        c.customer_type,
        c.first_ordered_at,
        c.lifetime_spend,
        c.count_lifetime_orders
),

-- Final dataset optimized for Iceberg performance features
final_iceberg_optimized as (
    select
        *,
        
        -- Additional computed columns that leverage Iceberg's performance
        datediff('day', previous_order_date, order_date) as days_since_last_order,
        case 
            when previous_order_date is null then 'first_order'
            when datediff('day', previous_order_date, order_date) <= 30 then 'frequent_buyer'
            when datediff('day', previous_order_date, order_date) <= 90 then 'regular_buyer'
            else 'infrequent_buyer'
        end as purchase_frequency_segment,
        
        -- Iceberg supports efficient UPSERT operations
        order_id as merge_key,
        row_number() over (partition by order_id order by record_created_at desc) as version_number
        
    from order_history
)

select * from final_iceberg_optimized
