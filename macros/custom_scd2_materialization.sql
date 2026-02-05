{% materialization scd_type2, default %}
  {%- set identifier = model['alias'] -%}
  {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
  {%- set target_relation = api.Relation.create(identifier=identifier, schema=schema, database=database, type='table') -%}
  
  {%- set unique_key = config.get('unique_key') -%}
  {%- set updated_at = config.get('updated_at', 'updated_at') -%}
  {%- set start_date = config.get('start_date', 'valid_from') -%}
  {%- set end_date = config.get('end_date', 'valid_to') -%}
  
  -- Custom SCD Type 2 materialization for slowly changing dimensions
  -- This implements slowly changing dimension logic with versioning
  
  {{ run_hooks(pre_hooks) }}
  
  {% if not unique_key %}
    {{ exceptions.raise_compiler_error("SCD Type 2 materialization requires 'unique_key' config") }}
  {% endif %}
  
  {% call statement('create_scd_table') -%}
    {% if old_relation is none %}
      -- Initial load: create table with SCD columns
      CREATE TABLE {{ target_relation }} AS (
        SELECT 
          *,
          {{ updated_at }} as {{ start_date }},
          '9999-12-31'::date as {{ end_date }},
          True as is_current,
          1 as version_number,
          '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::timestamp as dbt_created_at,
          '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::timestamp as dbt_updated_at
        FROM (
          {{ sql }}
        ) as model_data
      )
    {% else %}
      -- Incremental SCD logic
      CREATE OR REPLACE TEMPORARY TABLE {{ target_relation }}_new_data AS (
        SELECT 
          *,
          '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::timestamp as dbt_run_timestamp
        FROM (
          {{ sql }}
        ) as model_data
      );
      
      -- Close out changed records
      UPDATE {{ target_relation }}
      SET 
        {{ end_date }} = current_date - 1,
        is_current = False,
        dbt_updated_at = '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::timestamp
      WHERE is_current = True
        AND {{ unique_key }} IN (
          SELECT {{ unique_key }}
          FROM {{ target_relation }}_new_data new_data
          WHERE NOT EXISTS (
            SELECT 1 
            FROM {{ target_relation }} existing
            WHERE existing.{{ unique_key }} = new_data.{{ unique_key }}
              AND existing.is_current = True
              -- Compare all non-system columns for changes
              {% for column in adapter.get_columns_in_relation(ref(model.name)) %}
                {% if column.name not in [start_date, end_date, 'is_current', 'version_number', 'dbt_created_at', 'dbt_updated_at'] %}
                  AND (existing.{{ column.name }} = new_data.{{ column.name }} 
                       OR (existing.{{ column.name }} IS NULL AND new_data.{{ column.name }} IS NULL))
                {% endif %}
              {% endfor %}
          )
        );
      
      -- Insert new and changed records
      INSERT INTO {{ target_relation }} (
        SELECT 
          new_data.*,
          CURRENT_DATE as {{ start_date }},
          '9999-12-31'::date as {{ end_date }},
          True as is_current,
          COALESCE(max_version.max_version, 0) + 1 as version_number,
          CASE 
            WHEN existing.{{ unique_key }} IS NULL 
            THEN '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::timestamp
            ELSE existing.dbt_created_at
          END as dbt_created_at,
          '{{ run_started_at.strftime("%Y-%m-%d %H:%M:%S") }}'::timestamp as dbt_updated_at
        FROM {{ target_relation }}_new_data new_data
        LEFT JOIN (
          SELECT 
            {{ unique_key }},
            MAX(version_number) as max_version,
            MIN(dbt_created_at) as dbt_created_at
          FROM {{ target_relation }}
          GROUP BY {{ unique_key }}
        ) max_version ON new_data.{{ unique_key }} = max_version.{{ unique_key }}
        LEFT JOIN {{ target_relation }} existing 
          ON new_data.{{ unique_key }} = existing.{{ unique_key }} 
          AND existing.is_current = True
        WHERE existing.{{ unique_key }} IS NULL  -- New records
           OR NOT EXISTS (  -- Changed records
             SELECT 1 
             FROM {{ target_relation }} existing_check
             WHERE existing_check.{{ unique_key }} = new_data.{{ unique_key }}
               AND existing_check.is_current = True
               {% for column in adapter.get_columns_in_relation(ref(model.name)) %}
                 {% if column.name not in [start_date, end_date, 'is_current', 'version_number', 'dbt_created_at', 'dbt_updated_at'] %}
                   AND (existing_check.{{ column.name }} = new_data.{{ column.name }} 
                        OR (existing_check.{{ column.name }} IS NULL AND new_data.{{ column.name }} IS NULL))
                 {% endif %}
               {% endfor %}
           )
      );
      
      DROP TABLE {{ target_relation }}_new_data;
    {% endif %}
  {%- endcall %}
  
  {% call statement('scd_table_stats') -%}
    SELECT 
      COUNT(*) as total_records,
      COUNT(CASE WHEN is_current THEN 1 END) as current_records,
      COUNT(DISTINCT {{ unique_key }}) as unique_entities,
      MAX(version_number) as max_version
    FROM {{ target_relation }}
  {%- endcall %}
  
  {% set stats = load_result('scd_table_stats')['data'][0] %}
  {% set status_message %}
    SCD Type 2 table {{ target_relation }} updated:
    - Total records: {{ stats[0] }}
    - Current records: {{ stats[1] }}
    - Unique entities: {{ stats[2] }}
    - Max version: {{ stats[3] }}
  {% endset %}
  
  {{ log(status_message, info=True) }}
  
  {{ run_hooks(post_hooks) }}
  
  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}
