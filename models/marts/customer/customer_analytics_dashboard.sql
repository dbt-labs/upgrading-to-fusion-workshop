{{ config(
    description="Critical analytics dashboard data that depends on Python-based customer segmentation",
    materialized="table"
) }}

-- This model would create a critical path dependency on the Python model in production,
-- analytics pipeline would depend on Python-based segmentation

-- For demo purposes, we'll simulate the Python model output
with customer_segments as (
    select 
        customer_id,
        case 
            when customer_id like '%1' then 'High Value'
            when customer_id like '%2' then 'Medium Value' 
            when customer_id like '%3' then 'Low Value'
            else 'VIP'
        end as segment,
        0.75 as segment_score,
        1 as cluster_id
    from {{ ref('customers') }}
),

customers as (
    select * from {{ ref('customers') }}
),

orders as (
    select * from {{ ref('orders') }}
),

-- Aggregate order metrics by segment
segment_performance as (
    select
        cs.segment,
        count(distinct c.customer_id) as customer_count,
        avg(c.lifetime_spend) as avg_lifetime_spend,
        sum(c.lifetime_spend) as total_segment_revenue,
        avg(c.count_lifetime_orders) as avg_orders_per_customer,
        avg(cs.segment_score) as avg_segment_score,
        
        -- Recent order activity (last 90 days simulation)
        count(case when o.ordered_at >= current_date - interval '90 days' then o.order_id end) as recent_orders,
        sum(case when o.ordered_at >= current_date - interval '90 days' then o.order_total else 0 end) as recent_revenue
        
    from customer_segments cs
    left join customers c on cs.customer_id = c.customer_id
    left join orders o on c.customer_id = o.customer_id
    group by cs.segment
),

-- Calculate segment growth rates and other advanced metrics
segment_analytics as (
    select
        *,
        total_segment_revenue / nullif(customer_count, 0) as revenue_per_customer,
        recent_revenue / nullif(recent_orders, 0) as avg_recent_order_value,
        case 
            when segment = 'VIP' then 1.0
            when segment = 'High Value' then 0.8
            when segment = 'Medium Value' then 0.5
            else 0.2
        end as retention_probability,
        
        -- Calculated fields that would be used in business intelligence dashboards
        case 
            when avg_lifetime_spend > 1000 then 'Premium'
            when avg_lifetime_spend > 500 then 'Standard' 
            else 'Basic'
        end as tier
        
    from segment_performance
)

select 
    segment,
    customer_count,
    avg_lifetime_spend,
    total_segment_revenue,
    avg_orders_per_customer,
    avg_segment_score,
    recent_orders,
    recent_revenue,
    revenue_per_customer,
    avg_recent_order_value,
    retention_probability,
    tier,
    
    -- Critical business metrics that downstream dashboards depend on
    current_timestamp as last_updated,
    'python_segmentation_v1' as segmentation_model_version
    
from segment_analytics
order by total_segment_revenue desc
