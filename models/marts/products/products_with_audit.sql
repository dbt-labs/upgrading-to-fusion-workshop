{{
  config(
    materialized='table',
    description='Products model that would use custom audit_table materialization in production - '
  )
}}

-- The audit_table materialization creates both the main table and an audit table with metadata

with products as (
    select * from {{ ref('products') }}
),

order_items as (
    select * from {{ ref('order_items') }}
),

orders as (
    select * from {{ ref('orders') }}
),

-- Enhanced product analytics with audit trail requirements
product_performance as (
    select
        p.product_id,
        p.product_name,
        p.product_type,
        p.product_description,
        p.product_price,
        
        -- Sales metrics
        count(distinct oi.order_id) as total_orders,
        count(oi.order_item_id) as total_items_sold,
        sum(oi.product_price) as total_revenue,
        avg(oi.product_price) as avg_selling_price,
        
        -- Performance indicators that require audit tracking
        case 
            when count(oi.order_item_id) > 100 then 'High Performer'
            when count(oi.order_item_id) > 50 then 'Medium Performer'
            when count(oi.order_item_id) > 10 then 'Low Performer'
            else 'No Sales'
        end as performance_tier,
        
        -- Financial metrics requiring audit compliance
        sum(oi.product_price) / nullif(count(oi.order_item_id), 0) as revenue_per_unit,
        
        -- Time-based metrics (using order timestamp as proxy)
        min(o.ordered_at) as first_sale_date,
        max(o.ordered_at) as last_sale_date,
        
        -- Calculated audit fields that need to be tracked
        current_timestamp as record_created_at,
        '{{ run_started_at }}' as dbt_run_timestamp,
        '{{ var("audit_user", "system") }}' as audit_created_by
        
    from products p
    left join order_items oi on p.product_id = oi.product_id
    left join orders o on oi.order_id = o.order_id
    group by 
        p.product_id,
        p.product_name,
        p.product_type,
        p.product_description,
        p.product_price
),

-- Add additional business logic that benefits from audit tracking
final_with_classifications as (
    select
        *,
        
        -- Revenue classifications for business reporting
        case 
            when total_revenue >= 1000 then 'Revenue Driver'
            when total_revenue >= 500 then 'Solid Contributor'
            when total_revenue >= 100 then 'Minor Contributor'
            else 'Minimal Impact'
        end as revenue_classification,
        
        -- Inventory priority based on performance
        case 
            when performance_tier = 'High Performer' then 1
            when performance_tier = 'Medium Performer' then 2
            when performance_tier = 'Low Performer' then 3
            else 4
        end as inventory_priority,
        
        -- Data quality flags for audit purposes
        case 
            when product_price is null then 'Missing Price'
            when total_items_sold = 0 then 'No Sales Data'
            when avg_selling_price != product_price then 'Price Variance'
            else 'Data Quality OK'
        end as data_quality_flag
        
    from product_performance
)

select * from final_with_classifications
