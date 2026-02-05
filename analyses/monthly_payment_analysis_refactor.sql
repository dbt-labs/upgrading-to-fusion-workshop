-- This model demonstrates a PIVOT pattern refactored for Fusion compatibility
-- Uses explicit CASE statements instead of PIVOT (ANY) for static column definition
-- Fusion can now introspect the fixed column structure

{{ config(
    tags=['fusion_compatible', 'pivot_explicit', 'monthly_analysis'], 
    meta={'materialized': 'view'}
) }}

with monthly_payment_data as (
    select 
        date_trunc('month', o.ordered_at) as order_month,
        -- Simulate payment methods based on order patterns
        case 
            when hash(o.order_id) % 3 = 0 then 'credit_card'
            when hash(o.order_id) % 3 = 1 then 'debit_card'
            else 'paypal'
        end as payment_method,
        -- Simulate order totals based on items
        sum(p.product_price * 0.01) as payment_method_revenue,  -- Convert cents to dollars
        count(*) as transaction_count
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_order_items') }} i on o.order_id = i.order_id
    join {{ ref('stg_products') }} p on i.product_id = p.product_id
    where o.ordered_at >= to_timestamp('2023-01-01', 'YYYY-MM-DD')
    group by 
        date_trunc('month', o.ordered_at),
        case 
            when hash(o.order_id) % 3 = 0 then 'credit_card'
            when hash(o.order_id) % 3 = 1 then 'debit_card'
            else 'paypal'
        end
),

-- FIXED: Explicit pivot with known payment methods
-- Static columns allow Fusion introspection to succeed
monthly_revenue_by_payment_method as (
    select
        order_month,
        sum(case when payment_method = 'credit_card' then payment_method_revenue else 0 end) as credit_card_revenue,
        sum(case when payment_method = 'debit_card' then payment_method_revenue else 0 end) as debit_card_revenue,
        sum(case when payment_method = 'paypal' then payment_method_revenue else 0 end) as paypal_revenue,
        sum(case when payment_method not in ('credit_card', 'debit_card', 'paypal') then payment_method_revenue else 0 end) as other_revenue,
        sum(payment_method_revenue) as total_revenue,
        sum(transaction_count) as total_transactions
    from monthly_payment_data
    group by order_month
)

select 
    order_month,
    credit_card_revenue,
    debit_card_revenue,
    paypal_revenue,
    other_revenue,
    total_revenue,
    total_transactions
from monthly_revenue_by_payment_method
order by order_month