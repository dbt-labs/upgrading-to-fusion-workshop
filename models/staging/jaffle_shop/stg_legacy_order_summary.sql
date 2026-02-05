{{ config(
    materialized="view", 
    description="Legacy order summary model scheduled for deprecation - ", 
    meta={'deprecation_date': '2024-06-01', 'deprecation_reason': 'This model uses legacy business logic and will be replaced by new order analytics models'}
) }}


-- Models with deprecation dates may not be fully supported in Fusion migration

with legacy_order_data as (
    select * from {{ source('jaffle_shop', 'raw_orders') }}
),

-- Legacy business logic that is being phased out
legacy_order_summary as (
    select
        id as order_id,
        customer as customer_id,
        store_id as location_id,
        
        -- Legacy calculation methods (deprecated)
        subtotal / 100.0 as subtotal_dollars_legacy,
        tax_paid / 100.0 as tax_dollars_legacy,
        order_total / 100.0 as total_dollars_legacy,
        
        -- Old date formatting approach (deprecated but Snowflake compatible)
        to_char(ordered_at, 'YYYY-MM-DD') as order_date_legacy,
        to_char(ordered_at, 'YYYY-MM') as order_month_legacy,
        to_char(ordered_at, 'YYYY') as order_year_legacy,
        
        -- Legacy categorization logic being replaced
        case 
            when order_total > 5000 then 'LARGE'  -- Old threshold
            when order_total > 2000 then 'MEDIUM' 
            else 'SMALL'
        end as legacy_order_size,
        
        -- Old naming conventions (deprecated)
        ordered_at as order_timestamp_legacy,
        current_timestamp as processed_timestamp_legacy,
        
        -- Legacy flags and indicators
        case when subtotal > 0 then 1 else 0 end as has_items_legacy,
        case when tax_paid > 0 then 1 else 0 end as has_tax_legacy,
        
        -- Deprecated metadata
        'LEGACY_SYSTEM_v1' as source_system_version,
        'DEPRECATED_MODEL' as model_status,
        '{{ this.name }}' as legacy_model_name
        
    from legacy_order_data
),

-- Additional legacy transformations scheduled for removal
final_legacy_output as (
    select
        *,
        
        -- Legacy metrics that don't align with new business requirements
        subtotal_dollars_legacy + tax_dollars_legacy as computed_total_legacy,
        
        -- Old performance indicators
        case 
            when legacy_order_size = 'LARGE' then 100
            when legacy_order_size = 'MEDIUM' then 50
            else 10
        end as legacy_points_value,
        
        -- Deprecated audit fields
        '{{ run_started_at }}' as legacy_processed_at,
        'SCHEDULED_FOR_DEPRECATION' as deprecation_status,
        '2024-06-01' as scheduled_removal_date,
        
        -- Legacy hash for backward compatibility (will be removed)
        md5(concat(order_id, customer_id, order_date_legacy)) as legacy_order_hash
        
    from legacy_order_summary
)

select * from final_legacy_output

/*
 * DEPRECATION NOTICE:
 * This model is scheduled for removal on 2024-06-01
 * Please migrate to using the new order analytics models in marts/
 * Contact the Analytics team for migration assistance
 */
