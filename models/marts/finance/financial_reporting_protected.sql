{{ config(
    materialized="table", 
    access="private", 
    group="finance", 
    contract={'enforced': True}, 
    description="Protected financial reporting model with enhanced governance", 
    meta={'deprecation_date': '2024-08-01'}
) }}

-- Financial reporting with advanced governance features:
-- 1. Private access restrictions for data security
-- 2. Finance model group organization
-- 3. Deprecation date for lifecycle management
-- 4. Model contracts for data quality

SELECT 
  o.order_id,
  o.order_total as revenue_amount,
  o.ordered_at,
  o.customer_id
  
FROM {{ ref('orders') }} o
WHERE o.order_total IS NOT NULL
  AND o.order_total >= 0
  AND o.ordered_at IS NOT NULL
