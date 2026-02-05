{% materialization clone_table, default %}
  {% set target_relation = this %}
  {% set source_relation = config.get('source_relation') %}
  
  {%- if not source_relation -%}
    {{ exceptions.raise_compiler_error("Clone materialization requires 'source_relation' config") }}
  {%- endif -%}
  
  {% set existing_relation = load_relation(this) %}
  
  -- Custom materialization for cloning tables
  -- This is a soft blocker as custom materializations are not supported in Fusion
  
  {% call statement('main') -%}
    
    {%- if existing_relation is not none -%}
      {{ log("Dropping existing relation: " ~ existing_relation, info=True) }}
      DROP {{ existing_relation.type }} IF EXISTS {{ existing_relation }};
    {%- endif -%}
    
    -- Create clone using warehouse-specific syntax
    {% if target.type == 'snowflake' %}
      CREATE TABLE {{ target_relation }} CLONE {{ source_relation }}
    {% elif target.type == 'databricks' %}
      CREATE TABLE {{ target_relation }} SHALLOW CLONE {{ source_relation }}
    {% elif target.type == 'bigquery' %}
      CREATE TABLE {{ target_relation }} CLONE {{ source_relation }}
    {% else %}
      -- Fallback for other warehouses
      CREATE TABLE {{ target_relation }} AS SELECT * FROM {{ source_relation }}
    {% endif %}
    
  {%- endcall %}

  {% set status_message %}
    Created clone table {{ target_relation }} from {{ source_relation }}
  {% endset %}
  
  {{ log(status_message, info=True) }}
  
  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}
