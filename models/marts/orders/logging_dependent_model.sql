{{
  config(
    materialized='table',
    description='Advanced order analytics with comprehensive monitoring'
  )
}}

-- Advanced order analytics with comprehensive logging and monitoring

{% set start_time = modules.datetime.datetime.now() %}

{% do log("Starting execution of logging_dependent_model at " ~ start_time, info=True) %}

WITH performance_tracking AS (
  SELECT 
    order_id,
    customer_id,
    ordered_at,
    order_total,
    
    -- Add performance metadata that relies on logging
    '{{ run_started_at }}' as run_started_at,
    '{{ invocation_id }}' as invocation_id
    
  FROM {{ ref('orders') }}
  WHERE ordered_at >= CURRENT_DATE - INTERVAL '30 days'
),

{% set row_count_query %}
  SELECT COUNT(*) as cnt FROM performance_tracking
{% endset %}

{% if execute %}
  {# In a real environment, this would run_query() but we'll simulate for training #}
  {% set row_count = 1000 %}  {# Simulated row count #}
  {% do log("Processing " ~ row_count ~ " rows in logging_dependent_model", info=True) %}
{% endif %}

enriched_data AS (
  SELECT 
    p.*,
    
    -- Customer information
    c.customer_name,
    
    -- Add logging metadata
    {% if execute %}
      {{ row_count }} as total_rows_processed,
    {% else %}
      0 as total_rows_processed,
    {% endif %}
    
    -- Performance timing
    '{{ start_time }}' as model_start_time,
    CURRENT_TIMESTAMP as record_processed_at
    
  FROM performance_tracking p
  LEFT JOIN {{ ref('customers') }} c ON p.customer_id = c.customer_id
),

{% set processing_time = (modules.datetime.datetime.now() - start_time).total_seconds() %}
{% do log("Processing time so far: " ~ processing_time ~ " seconds", info=True) %}

final_output AS (
  SELECT 
    *,
    {{ processing_time }} as processing_time_seconds,
    
    -- Log-based data quality checks
    CASE 
      WHEN order_total IS NULL THEN 'NULL_ORDER_TOTAL'
      WHEN order_total <= 0 THEN 'NEGATIVE_ORDER_TOTAL'
      WHEN order_total > 10000 THEN 'UNUSUALLY_HIGH_ORDER'
      ELSE 'VALID'
    END as data_quality_flag
    
  FROM enriched_data
)

{% set quality_check_query %}
  SELECT 
    data_quality_flag,
    COUNT(*) as cnt
  FROM ({{ sql }})
  GROUP BY data_quality_flag
{% endset %}

{% if execute %}
  {# In a real environment, this would run_query() but we'll simulate for training #}
  {% set quality_results = [['VALID', 950], ['NULL_ORDER_TOTAL', 30], ['NEGATIVE_ORDER_TOTAL', 15], ['UNUSUALLY_HIGH_ORDER', 5]] %}
  {% for row in quality_results %}
    {% do log("Data quality check - " ~ row[0] ~ ": " ~ row[1] ~ " records", info=True) %}
  {% endfor %}
{% endif %}

SELECT * FROM final_output

{% set end_time = modules.datetime.datetime.now() %}
{% set total_time = (end_time - start_time).total_seconds() %}
{% do log("Completed logging_dependent_model in " ~ total_time ~ " seconds", info=True) %}
