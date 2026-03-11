-- This model attempts to use the deprecated insert_by_period materialization
-- BREAKING: insert_by_period was removed from dbt_utils 1.0.0 and moved to experimental-features repo

{{ config(
    materialized="table", 
    tags=['package_breaking_change', 'materialization'], 
    meta={'period': 'day', 'timestamp_field': 'ordered_at', 'start_date': '2023-01-01', 'stop_date': '2024-12-31'}
) }}

select
    ordered_at as order_date,
    customer_id,
    count(*) as order_count,
    sum(order_total) as daily_total
from {{ ref('stg_orders') }}

{% if is_incremental() %}
    where ordered_at >= (select max(ordered_at) from {{ this }})
{% endif %}

group by ordered_at, customer_id