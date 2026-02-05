{{ config(
    description="Model demonstrating common YAML validation errors for Fusion training", 
    post_hook="update {{ this }} set processed_at = current_timestamp()", 
    unique_key="customer_id",
    materialized="table",
    indexes=[{'columns': ['customer_id'], 'type': 'hash'}], 
    persist_docs={'relation': True, 'columns': True}, 
    meta={'materialised': 'table', 'tag': ['yaml_validation_error', 'fusion_training']}
) }}
-- ABOVE
-- YAML VALIDATION ERROR: Should be 'materialized' (British vs American spelling)
-- YAML VALIDATION ERROR: Should be 'tags' (plural)
-- YAML VALIDATION ERROR: Should be 'indexes' under model config, not here
-- Model with intentional YAML validation errors for training purposes
-- These errors will be caught by Fusion's stricter validation

with customer_data as (
    select 
        customer_id,
        customer_name,
        first_ordered_at as first_order_date,
        last_ordered_at as most_recent_order_date,
        count_lifetime_orders,
        lifetime_spend_pretax,
        lifetime_tax_paid,
        lifetime_spend,
        customer_type
    from {{ ref('customers') }}
),

enriched as (
    select 
        *,
        case 
            when lifetime_spend >= 1000 then 'High Value'
            when lifetime_spend >= 500 then 'Medium Value' 
            else 'Low Value'
        end as value_segment,
        current_timestamp() as analysis_timestamp,
        null::timestamp as processed_at  -- Column for post-hook update
    from customer_data
)

select * from enriched