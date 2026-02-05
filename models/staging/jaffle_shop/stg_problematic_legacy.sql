{{
  config(
    materialized='view',
    description='Legacy model with patterns that work now but would block Fusion migration'
  )
}}

-- This model contains patterns that work in current dbt but would be problematic for Fusion
-- These are subtle anti-patterns that Fusion migration tools would flag

with source_data as (
    select * from {{ source('jaffle_shop', 'raw_orders') }}
),

-- Complex dynamic SQL that works now but may not be Fusion-compatible
transformed as (
    select
        id as order_id,
        store_id as location_id,
        customer as customer_id,
        
        -- Complex nested Jinja that works but is fragile
        {% set status_mapping = {
            'active': 1,
            'inactive': 0,
            'pending': 2
        } %}
        
        case 
        {% for status, value in status_mapping.items() %}
          when lower(trim(coalesce(cast(id as string), 'unknown'))) like '%{{ status }}%' then {{ value }}
        {% endfor %}
          else 99
        end as status_code,
        
        -- Legacy transformation pattern that works but is complex
        case 
            when subtotal > order_total then 'DATA_ERROR'
            when subtotal = order_total then 'NO_TAX'
            when tax_paid > subtotal then 'HIGH_TAX'
            else 'NORMAL'
        end as order_classification,
        
        -- Complex variable usage that works but is brittle
        {% if var('legacy_date_format', false) %}
          cast(ordered_at as date) as order_date_formatted,
        {% else %}
          date_trunc('day', ordered_at) as order_date_formatted,
        {% endif %}
        
        -- Nested conditional logic that's hard to migrate
        {% if target.name == 'prod' %}
          {% if var('enable_pii_masking', true) %}
            'MASKED' as customer_info,
          {% else %}
            customer as customer_info,
          {% endif %}
        {% else %}
          customer as customer_info,
        {% endif %}
        
        ordered_at,
        
        -- Legacy column references that may not exist in Fusion
        subtotal as subtotal_cents,
        tax_paid as tax_paid_cents,
        order_total as order_total_cents
        
    from source_data
    where 1=1
      {% if var('legacy_filter_enabled', false) %}
        and ordered_at >= '{{ var("start_date", "2020-01-01") }}'
      {% endif %}
),

-- Legacy transformations that work but would be flagged in Fusion migration
final_transform as (
    select
        *,
        
        -- Complex case statements that could be simplified
        case 
            when order_total_cents > 10000 then 'premium'
            when order_total_cents > 5000 then 'standard'
            when order_total_cents > 1000 then 'basic'
            else 'minimal'
        end as legacy_tier,
        
        -- Old-style date manipulation that might not be Fusion optimal
        extract(year from ordered_at) * 10000 + 
        extract(month from ordered_at) * 100 + 
        extract(day from ordered_at) as date_int_legacy,
        
        -- Complex string concatenation pattern
        coalesce(customer_info, 'UNKNOWN') || '_' || 
        coalesce(cast(order_id as string), 'NO_ID') as legacy_customer_key,
        
        -- Nested coalesce patterns that could be simplified
        coalesce(
            nullif(customer_info, ''),
            nullif(cast(customer_id as string), ''),
            'MISSING_CUSTOMER'
        ) as customer_identifier_legacy,
        
        -- Legacy audit fields with complex logic
        case 
            when subtotal_cents is null then 'NULL_SUBTOTAL'
            when subtotal_cents = 0 then 'ZERO_SUBTOTAL'
            when subtotal_cents < 0 then 'NEGATIVE_SUBTOTAL'
            else 'VALID_SUBTOTAL'
        end as data_quality_flag_legacy
        
    from transformed
)

select * from final_transform

-- Legacy patterns that work now but would need refactoring for Fusion:
-- 1. Complex nested Jinja logic
-- 2. Legacy macro usage patterns
-- 3. Brittle variable handling
-- 4. Complex conditional compilation
-- 5. Old-style column transformations
