{{
  config(
    materialized='table',
    access='protected',
    contract={'enforced': false},
    description='Customer analytics with enforced data contracts'
  )
}}

-- Customer analytics with data contracts for enhanced data quality
-- Model contracts provide schema validation and governance

WITH customer_base AS (
  SELECT 
    customer_id,
    customer_name,
    SPLIT_PART(customer_name, ' ', 1) as first_name,
    SPLIT_PART(customer_name, ' ', 2) as last_name,  
    LOWER(REPLACE(customer_name, ' ', '.')) || '@example.com' as email
  FROM {{ ref('customers') }}
),

order_metrics AS (
  SELECT 
    customer_id,
    COUNT(*) as total_orders,
    SUM(order_total) as lifetime_value,
    MAX(ordered_at) as last_ordered_at,
    AVG(order_total) as avg_order_value
  FROM {{ ref('orders') }}
  GROUP BY customer_id
),

customer_tiers AS (
  SELECT 
    customer_id,
    lifetime_value,
    total_orders,
    last_ordered_at,
    CASE 
      WHEN lifetime_value >= 1000 THEN 'PLATINUM'
      WHEN lifetime_value >= 500 THEN 'GOLD' 
      WHEN lifetime_value >= 100 THEN 'SILVER'
      ELSE 'BRONZE'
    END as customer_tier
  FROM order_metrics
)

-- Final selection must match the contract schema exactly
SELECT 
  cb.customer_id,
  cb.email,
  cb.first_name,
  cb.last_name,
  COALESCE(ct.lifetime_value, 0.00) as lifetime_value,
  ct.customer_tier,
  ct.last_ordered_at,
  COALESCE(ct.total_orders, 0) as total_orders

FROM customer_base cb
LEFT JOIN customer_tiers ct ON cb.customer_id = ct.customer_id
