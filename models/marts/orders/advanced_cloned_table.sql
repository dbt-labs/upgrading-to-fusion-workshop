{{
  config(
    materialized='view',
    description='Efficient table cloning for analytics'
  )
}}

-- High-performance table cloning for analytics workloads

SELECT 
  order_id,
  customer_id,
  ordered_at,
  order_total,
  'cloned_from_orders' as source_info
FROM {{ ref('orders') }}

-- In production, this would use: materialized='clone_table'
-- But custom materializations are not supported in Fusion
