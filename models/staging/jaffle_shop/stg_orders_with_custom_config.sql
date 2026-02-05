{{ config(
    materialized="table", 
    meta={'add_row_number': True, 'add_hash_key': True, 'business_unit': 'ecommerce', 'enable_audit_fields': True}
) }}

{#- 
  This model uses completely custom organizational configs that Fusion doesn't support.
  These are made-up configs for adding computed columns.
  Trainees need to:
  1. Move custom configs (add_row_number, add_hash_key, business_unit, enable_audit_fields) to meta 
  2. Update the add_custom_columns macro to reference config.get('meta')
-#}

select 
  id,
  customer,
  ordered_at,
  store_id,
  subtotal,
  tax_paid,
  order_total
  
  {{ add_custom_columns() }}
  
from {{ source('jaffle_shop', 'raw_orders') }}