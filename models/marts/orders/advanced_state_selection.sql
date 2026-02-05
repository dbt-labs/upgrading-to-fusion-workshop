{{
  config(
    materialized='table',
    description='Advanced customer analytics with state-based processing'
  )
}}

-- Advanced customer analytics using state-based selection for efficient processing

WITH state_dependent_logic AS (
  SELECT 
    order_id,
    customer_id,
    ordered_at,
    order_total,
    
    -- Logic that would typically be selected with state:modified+
    CASE 
      WHEN order_total > 100 THEN 'high_value'
      WHEN order_total > 50 THEN 'medium_value'
      ELSE 'low_value'
    END as order_category,
    
    -- SOFT BLOCKER: State-dependent processing patterns
    -- Would typically use: dbt run --select state:modified+
    -- Would check: {{ var('is_state_refresh', false) }}
    'state_modified_pattern' as selection_pattern
    
  FROM {{ ref('orders') }}
  WHERE ordered_at >= CURRENT_DATE - INTERVAL '1 year'
),

state_based_aggregations AS (
  SELECT 
    customer_id,
    COUNT(*) as total_orders,
    SUM(order_total) as total_spent,
    AVG(order_total) as avg_order_value,
    MAX(ordered_at) as last_order_date,
    
    -- Pattern that would benefit from state:modified selection
    CASE 
      WHEN COUNT(*) > 10 THEN 'frequent_customer'
      WHEN COUNT(*) > 5 THEN 'regular_customer'
      ELSE 'occasional_customer'
    END as customer_segment
    
  FROM state_dependent_logic
  GROUP BY customer_id
),

final_state_output AS (
  SELECT 
    s.*,
    a.customer_segment,
    a.total_orders,
    a.avg_order_value,
    
    -- DOCUMENTED: State selection patterns not fully supported in Fusion
    -- Would use: state:modified, state:modified+, state:new
    -- Would benefit from: slim CI, state-based deployments
    'requires_state_selection_migration' as fusion_migration_note
    
  FROM state_dependent_logic s
  LEFT JOIN state_based_aggregations a ON s.customer_id = a.customer_id
)

SELECT * FROM final_state_output
WHERE ordered_at IS NOT NULL

-- MIGRATION GUIDANCE FOR FUSION:
-- 1. Replace state:modified with explicit date filters
-- 2. Use incremental models instead of state selection
-- 3. Implement explicit change detection logic
-- 4. Consider using dbt-utils' incremental strategies
-- 5. Plan for full-refresh patterns in CI/CD

-- PATTERNS DEMONSTRATED:
-- - Complex conditional logic dependent on historical data
-- - Aggregations that would benefit from partial rebuilds
-- - Customer segmentation requiring full dataset context
-- - Time-based filtering commonly used with state selection