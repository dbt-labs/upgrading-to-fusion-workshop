{{
  config(
    materialized='view',
    description='Legacy customer data processing with complex patterns'
  )
}}

-- Legacy customer data with various processing patterns and complex logic

WITH base_data AS (
  SELECT 
    id as customer_id,
    name as customer_name,
    SPLIT_PART(name, ' ', 1) as first_name,
    SPLIT_PART(name, ' ', 2) as last_name,
    LOWER(REPLACE(name, ' ', '.')) || '@example.com' as email,
    
    -- DOCUMENTED PARSE FAILURES (would break compilation if uncommented):
    -- 1. Undefined variables: var('undefined_variable')
    -- 2. Invalid macro calls: invalid_macro_call('param1', param2  [missing closing paren]
    -- 3. Recursive references: ref('stg_legacy_parse_failure') 
    -- 4. Malformed Jinja: [percent-brace] if undefined_var [percent-brace]...[percent-brace] else if bad_syntax
    -- 5. Incomplete CASE: CASE WHEN x > 1 WHEN y ELSE END
    -- 6. Bad loops: [percent-brace] for item in undefined_list [percent-brace] [brace-brace] item.bad_prop [brace-brace] [percent-brace] endfor [percent-brace]
    -- 7. Missing parentheses: WHERE (condition AND other_condition [missing closing paren]
    -- 8. Undefined columns: source_column_that_doesnt_exist
    
    CURRENT_TIMESTAMP as created_at,
    'parse_failure_demo' as model_type
    
  FROM {{ source('jaffle_shop', 'raw_customers') }}
  WHERE id IS NOT NULL
    AND name IS NOT NULL
),

documented_issues AS (
  SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    created_at,
    model_type,
    
    -- Document the types of issues that would prevent parsing:
    ARRAY_CONSTRUCT(
      'undefined_variables',
      'malformed_jinja_syntax', 
      'circular_references',
      'incomplete_sql_statements',
      'missing_closing_brackets',
      'invalid_macro_calls',
      'undefined_column_references',
      'recursive_model_dependencies'
    ) as parse_failure_types,
    
    -- Demonstrate the business impact of parse failures
    'Critical blocker - prevents all compilation' as impact_level,
    'Must be fixed before any dbt operations can proceed' as remediation_priority
    
  FROM base_data
)

-- Final working query that documents but doesn't break compilation
SELECT 
  customer_id,
  first_name,
  last_name, 
  email,
  created_at,
  model_type,
  parse_failure_types,
  impact_level,
  remediation_priority,
  
  -- Additional metadata about parse failure patterns
  'Legacy technical debt accumulated over time' as root_cause,
  'Systematic code review and refactoring required' as solution_approach
  
FROM documented_issues

-- This model now compiles successfully while documenting all the patterns
-- that would cause parse failures in a real legacy environment