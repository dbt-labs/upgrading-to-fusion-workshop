{{
  config(
    materialized='view',
    description='Model demonstrating advanced Snowflake features'
  )
}}

-- Advanced Snowflake data warehouse features and operations

WITH base_orders AS (
  SELECT 
    id as order_id,
    customer as customer_id,
    ordered_at as order_date,
    store_id,
    subtotal,
    tax_paid,
    order_total
  FROM {{ source('jaffle_shop', 'raw_orders') }}
),

documented_unsupported_features AS (
  SELECT 
    order_id,
    customer_id,
    order_date,
    order_total,
    
    -- Time Travel capabilities
    -- AT(TIMESTAMP => '2024-01-01 00:00:00'::timestamp)
    -- BEFORE(STATEMENT => 'statement_id')
    'time_travel_feature' as time_travel_demo,
    
    -- System clustering functions
    -- SYSTEM$CLUSTERING_INFORMATION('table_name')
    -- SYSTEM$CLUSTERING_DEPTH('table_name')
    'clustering_functions' as clustering_demo,
    
    -- COPY command operations
    -- COPY INTO @stage/path FROM (SELECT * FROM table) FILE_FORMAT = (TYPE = 'PARQUET')
    'copy_commands' as copy_demo,
    
    -- External functions
    -- GET_WEATHER_DATA(address)
    -- ENCRYPT_DECRYPT_DATA(data, 'decrypt')
    'external_functions' as external_demo,
    
    -- Stored procedure calls
    -- CALL sp_calculate_metrics(parameter)
    'stored_procedures' as procedure_demo,
    
    -- DDL in queries
    -- CREATE SCHEMA IF NOT EXISTS temp_schema
    -- ALTER WAREHOUSE 'name' SET WAREHOUSE_SIZE = 'LARGE'
    'ddl_operations' as ddl_demo,
    
    -- Advanced semi-structured functions
    -- PARSE_JSON(column)['nested']['property']
    -- column:path[0].property::STRING
    'semi_structured_functions' as json_demo,
    
    -- LATERAL FLATTEN operations
    -- LATERAL FLATTEN(input => PARSE_JSON(column), path => 'items') f
    'lateral_flatten' as flatten_demo,
    
    -- Account usage views
    -- SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY.QUERY_TEXT
    'account_usage_views' as metadata_demo,
    
    -- Data sharing syntax
    -- SHARE.SHARED_DATABASE.TABLE.column
    'data_sharing' as sharing_demo,
    
    -- Dynamic table creation
    -- CREATE OR REPLACE DYNAMIC TABLE name TARGET_LAG = '5 minutes'
    'dynamic_tables' as dynamic_demo
    
  FROM base_orders
  WHERE order_id IS NOT NULL
),

migration_guidance AS (
  SELECT 
    *,
    
    -- Migration recommendations
    'Replace with standard SQL equivalents' as time_travel_migration,
    'Use dbt materializations instead of COPY' as copy_migration,
    'Implement in application layer' as external_function_migration,
    'Use dbt hooks or run-operation for DDL' as ddl_migration,
    'Simplify or use dbt JSON functions' as json_migration,
    'Consider alternative approach or wait for support' as advanced_migration
    
  FROM documented_unsupported_features
)

SELECT * FROM migration_guidance

-- DOCUMENTED PATTERNS USING ADVANCED SNOWFLAKE FEATURES:
-- 1. Time Travel: AT(TIMESTAMP), BEFORE(STATEMENT)
-- 2. System Functions: SYSTEM$CLUSTERING_*, SYSTEM$QUERY_*
-- 3. COPY Commands: COPY INTO @stage/path FROM table
-- 4. External Functions: Custom UDFs requiring external setup
-- 5. Stored Procedures: CALL procedure_name(params)
-- 6. DDL in Models: CREATE/ALTER/DROP statements
-- 7. Account Usage: SNOWFLAKE.ACCOUNT_USAGE.* views
-- 8. Advanced Semi-Structured: Complex JSON path operations
-- 9. Data Sharing: SHARE.DATABASE.TABLE syntax
-- 10. Dynamic Tables: TARGET_LAG configurations

-- MIGRATION STRATEGY:
-- - Replace time travel with incremental models
-- - Use dbt materializations instead of raw COPY
-- - Move external functions to application layer
-- - Use dbt hooks for DDL operations
-- - Simplify JSON operations or use dbt utils
-- - Implement alternative approaches for unsupported features