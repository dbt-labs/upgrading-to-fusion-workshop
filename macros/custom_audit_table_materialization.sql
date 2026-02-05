{% materialization audit_table, default -%}
  {# Custom materialization that creates an audit table with tracking metadata #}

  {%- set identifier = model['alias'] -%}
  {%- set target_relation = api.Relation.create(
      identifier=identifier,
      schema=schema,
      database=database,
      type='table'
  ) -%}

  {%- set audit_identifier = identifier ~ '_audit' -%}
  {%- set audit_relation = api.Relation.create(
      identifier=audit_identifier,
      schema=schema,
      database=database,
      type='table'
  ) -%}

  {%- set tmp_identifier = model['name'] + '__dbt_tmp' -%}
  {%- set tmp_relation = api.Relation.create(
      identifier=tmp_identifier,
      schema=schema,
      database=database,
      type='table'
  ) -%}

  {{ log("Building audit table materialization for " ~ target_relation) }}

  {# Create the main table first #}
  {{ run_hooks(pre_hooks) }}

  -- Build model in temp table
  {% call statement('main') -%}
    {{ create_table_as(false, tmp_relation, sql) }}
  {%- endcall %}

  -- Create audit table with metadata
  {% set audit_sql %}
    select 
      '{{ run_started_at }}' as audit_run_timestamp,
      '{{ target.name }}' as audit_target_name,
      '{{ model.unique_id }}' as audit_model_id,
      count(*) as audit_row_count,
      current_timestamp as audit_created_at,
      '{{ invocation_id }}' as audit_invocation_id,
      'audit_table_materialization' as audit_materialization_type
    from {{ tmp_relation }}
  {% endset %}

  {% call statement('create_audit_table') -%}
    {{ create_table_as(false, audit_relation, audit_sql) }}
  {%- endcall %}

  -- Swap tables atomically
  {% call statement('rename_tmp_table') -%}
    {{ adapter.rename_relation(tmp_relation, target_relation) }}
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {% set status_message %}
    Created audit table {{ target_relation }} with audit metadata in {{ audit_relation }}
  {% endset %}

  {{ log(status_message) }}

  {{ return({'relations': [target_relation, audit_relation]}) }}

{%- endmaterialization %}
