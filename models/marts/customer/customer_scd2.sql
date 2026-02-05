{{
  config(
    materialized='table',
    description='SCD Type 2 customer history tracking'
  )
}}

-- Slowly Changing Dimension Type 2 for customer history

WITH customer_metrics AS (
  SELECT 
    c.customer_id,
    c.customer_name,
    SPLIT_PART(c.customer_name, ' ', 1) as first_name,
    SPLIT_PART(c.customer_name, ' ', 2) as last_name,
    LOWER(REPLACE(c.customer_name, ' ', '.')) || '@example.com' as email,
    
    -- Calculate current customer metrics
    COUNT(o.order_id) as total_orders,
    SUM(o.order_total) as lifetime_value,
    AVG(o.order_total) as avg_order_value,
    MIN(o.ordered_at) as first_ordered_at,
    MAX(o.ordered_at) as last_ordered_at,
    
    -- Customer tier based on spending
    CASE 
      WHEN SUM(o.order_total) >= 1000 THEN 'PLATINUM'
      WHEN SUM(o.order_total) >= 500 THEN 'GOLD'
      WHEN SUM(o.order_total) >= 100 THEN 'SILVER'
      ELSE 'BRONZE'
    END as customer_tier,
    
    -- Activity status
    CASE 
      WHEN MAX(o.ordered_at) >= CURRENT_DATE - INTERVAL '30 days' THEN 'ACTIVE'
      WHEN MAX(o.ordered_at) >= CURRENT_DATE - INTERVAL '90 days' THEN 'AT_RISK'
      ELSE 'INACTIVE'
    END as activity_status,
    
    -- Risk score
    CASE 
      WHEN COUNT(o.order_id) = 1 AND MAX(o.ordered_at) < CURRENT_DATE - INTERVAL '60 days' THEN 'HIGH'
      WHEN AVG(o.order_total) < 20 THEN 'MEDIUM'
      ELSE 'LOW'
    END as risk_score
    
  FROM {{ ref('customers') }} c
  LEFT JOIN {{ ref('orders') }} o ON c.customer_id = o.customer_id
  GROUP BY c.customer_id, c.customer_name
)

SELECT 
  customer_id,
  first_name,
  last_name,
  email,
  total_orders,
  lifetime_value,
  avg_order_value,
  first_ordered_at,
  last_ordered_at,
  customer_tier,
  activity_status,
  risk_score
FROM customer_metrics
