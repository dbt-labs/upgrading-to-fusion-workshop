-- Collection of deprecated macro patterns that will trigger warnings

{% macro deprecated_adapter_macro() %}
  {# DEPRECATED: Using old adapter macro patterns #}
  
  -- DEPRECATED: Direct adapter calls without dispatch
  {% set current_timestamp = adapter.dispatch('current_timestamp') %}
  
  -- DEPRECATED: Old adapter.get_relation syntax
  {% set relation = adapter.get_relation(
    database=target.database,
    schema=target.schema, 
    identifier='some_table'
  ) %}
  
  -- DEPRECATED: Using adapter._get_catalog without proper error handling
  {% set catalog = adapter._get_catalog(relation) %}
  
  {{ current_timestamp }}
{% endmacro %}

{% macro deprecated_var_usage() %}
  {# DEPRECATED: Using var() without defaults #}
  
  -- DEPRECATED: No default value provided
  {% set env = var('environment') %}  {# Should have default #}
  
  -- DEPRECATED: Using var with non-standard default syntax
  {% set debug_mode = var('debug', false) %}  {# Old syntax #}
  
  -- DEPRECATED: Complex var expressions without proper handling
  {% set complex_var = var('base_url') + '/api/v1' %}  {# Should be in separate steps #}
  
  '{{ env }}_{{ debug_mode }}'
{% endmacro %}

{% macro deprecated_ref_patterns() %}
  {# DEPRECATED: Old ref() usage patterns #}
  
  -- DEPRECATED: Using ref without quotes in some contexts
  {% set table_name = ref(customers) %}  {# Should be ref('customers') #}
  
  -- DEPRECATED: Dynamic ref construction
  {% set model_name = 'customers' %}
  {% set dynamic_ref = ref(model_name) %}  {# May cause issues #}
  
  -- DEPRECATED: Ref in loop without proper handling
  {% set models = ['customers', 'orders', 'products'] %}
  {% for model in models %}
    {{ ref(model) }}  {# Should be more careful with loops #}
  {% endfor %}
  
{% endmacro %}

{% macro deprecated_this_usage() %}
  {# DEPRECATED: Old 'this' object usage patterns #}
  
  -- DEPRECATED: Direct this.database access without checks
  {% set db = this.database %}
  
  -- DEPRECATED: String concatenation with this
  {% set full_name = this.database + '.' + this.schema + '.' + this.identifier %}
  
  -- DEPRECATED: Using this in inappropriate contexts
  {% if this %}
    CREATE TABLE {{ this }} AS SELECT 1 as col
  {% endif %}
  
  {{ full_name }}
{% endmacro %}

{% macro deprecated_run_query_patterns() %}
  {# DEPRECATED: Old run_query usage without proper error handling #}
  
  -- DEPRECATED: run_query without execute check
  {% set result = run_query("SELECT COUNT(*) FROM information_schema.tables") %}
  
  -- DEPRECATED: Using run_query results without validation
  {% set count = result.columns[0].values()[0] %}
  
  -- DEPRECATED: Complex queries in run_query without proper escaping
  {% set complex_query %}
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = '{{ target.schema }}'
      AND table_name LIKE 'prefix_%'
  {% endset %}
  
  {% set tables = run_query(complex_query) %}
  
  {{ count }}
{% endmacro %}

{% macro deprecated_graph_usage() %}
  {# DEPRECATED: Using graph object without proper checks #}
  
  -- DEPRECATED: Direct graph access without execute/graph checks
  {% set node_count = graph.nodes | length %}
  
  -- DEPRECATED: Iterating graph without safeguards
  {% for node_id, node in graph.nodes.items() %}
    {% if node.resource_type == 'model' %}
      -- DEPRECATED: Using raw_sql directly
      {% set sql_length = node.raw_sql | length %}
    {% endif %}
  {% endfor %}
  
  -- DEPRECATED: Graph operations in inappropriate contexts
  {% if graph %}
    {% set models = graph.nodes.values() | selectattr('resource_type', 'equalto', 'model') | list %}
  {% endif %}
  
  {{ node_count }}
{% endmacro %}

{% macro deprecated_target_patterns() %}
  {# DEPRECATED: Old target object usage #}
  
  -- DEPRECATED: Direct target comparisons without string conversion
  {% if target.name == prod %}  {# Should be 'prod' #}
    SELECT 'production' as environment
  {% endif %}
  
  -- DEPRECATED: Target concatenation without proper handling
  {% set env_prefix = target.name + '_' + target.schema %}
  
  -- DEPRECATED: Using target in inappropriate loops or contexts
  {% for env in ['dev', 'staging', 'prod'] %}
    {% if target.name == env %}
      -- Do something
    {% endif %}
  {% endfor %}
  
  {{ env_prefix }}
{% endmacro %}

{% macro deprecated_module_usage() %}
  {# DEPRECATED: Direct module access without proper handling #}
  
  -- DEPRECATED: modules.datetime without error handling
  {% set now = modules.datetime.datetime.now() %}
  
  -- DEPRECATED: modules.re without checking availability
  {% set pattern = modules.re.compile('\\d+') %}
  
  -- DEPRECATED: Complex module operations
  {% set formatted_date = modules.datetime.datetime.strptime('2024-01-01', '%Y-%m-%d') %}
  
  '{{ now }}'
{% endmacro %}

{# DEPRECATED: Macro definition patterns #}

-- DEPRECATED: Macro without proper documentation
{% macro undocumented_macro(param1, param2) %}
  {{ param1 }} + {{ param2 }}
{% endmacro %}

-- DEPRECATED: Macro with unrestricted parameters
{% macro unsafe_macro(sql_fragment) %}
  SELECT * FROM {{ sql_fragment }}  {# Potential SQL injection #}
{% endmacro %}

-- DEPRECATED: Recursive macro without proper safeguards
{% macro potentially_recursive_macro(depth=0) %}
  {% if depth < 10 %}
    {{ potentially_recursive_macro(depth + 1) }}
  {% endif %}
{% endmacro %}
