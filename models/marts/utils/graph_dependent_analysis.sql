{{
  config(
    materialized='table',
    description='Advanced model using graph object for dynamic analysis'
  )
}}

-- Advanced model using dbt graph object for dynamic analysis
-- Demonstrates complex introspection and graph operations

{% if execute and graph %}

WITH model_analysis AS (
  {% set model_list = [] %}
  {% for node_id, node in graph.nodes.items() %}
    {% if node.resource_type == 'model' and node.package_name == 'jaffle_shop' %}
      {% set model_info = {
        'model_name': node.name,
        'model_id': node_id,
        'sql_length': node.raw_sql | length,
        'dependency_count': node.depends_on.nodes | length,
        'materialization': node.config.materialized,
        'tags': node.tags | join(',') if node.tags else 'none'
      } %}
      {% do model_list.append(model_info) %}
    {% endif %}
  {% endfor %}
  
  -- Generate a table from the graph metadata
  {% for model in model_list %}
    SELECT 
      '{{ model.model_name }}' as model_name,
      '{{ model.model_id }}' as model_unique_id,
      {{ model.sql_length }} as sql_length,
      {{ model.dependency_count }} as dependency_count,
      '{{ model.materialization }}' as materialization,
      '{{ model.tags }}' as tags,
      CURRENT_TIMESTAMP as analyzed_at
    {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
),

sql_complexity_analysis AS (
  SELECT 
    model_name,
    model_unique_id,
    sql_length,
    dependency_count,
    materialization,
    tags,
    analyzed_at,
    
    -- Calculate complexity scores based on graph analysis
    CASE 
      WHEN sql_length > 2000 THEN 'HIGH'
      WHEN sql_length > 1000 THEN 'MEDIUM'
      ELSE 'LOW'
    END as sql_complexity,
    
    CASE 
      WHEN dependency_count > 5 THEN 'HIGH'
      WHEN dependency_count > 2 THEN 'MEDIUM'
      ELSE 'LOW'
    END as dependency_complexity,
    
    -- Overall risk score based on graph properties
    CASE 
      WHEN sql_length > 2000 AND dependency_count > 5 THEN 'CRITICAL'
      WHEN sql_length > 1000 OR dependency_count > 3 THEN 'HIGH'
      WHEN materialization = 'table' AND dependency_count > 2 THEN 'MEDIUM'
      ELSE 'LOW'
    END as migration_risk
    
  FROM model_analysis
),

graph_relationships AS (
  {% set relationships = [] %}
  {% for node_id, node in graph.nodes.items() %}
    {% if node.resource_type == 'model' and node.package_name == 'jaffle_shop' %}
      {% for dep in node.depends_on.nodes %}
        {% if dep.startswith('model.jaffle_shop') %}
          {% set relationship = {
            'parent_model': dep.split('.')[-1],
            'child_model': node.name,
            'relationship_type': 'model_dependency'
          } %}
          {% do relationships.append(relationship) %}
        {% endif %}
      {% endfor %}
    {% endif %}
  {% endfor %}
  
  -- Create relationship mapping
  {% for rel in relationships %}
    SELECT 
      '{{ rel.parent_model }}' as parent_model,
      '{{ rel.child_model }}' as child_model,
      '{{ rel.relationship_type }}' as relationship_type,
      CURRENT_TIMESTAMP as relationship_analyzed_at
    {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
),

lineage_depth_analysis AS (
  -- Calculate lineage depth using recursive graph traversal
  WITH RECURSIVE lineage_tree AS (
    -- Base case: models with no dependencies
    SELECT 
      model_name,
      model_name as root_model,
      0 as depth_level
    FROM sql_complexity_analysis s
    WHERE NOT EXISTS (
      SELECT 1 
      FROM graph_relationships r 
      WHERE r.child_model = s.model_name
    )
    
    UNION ALL
    
    -- Recursive case: models with dependencies
    SELECT 
      r.child_model as model_name,
      l.root_model,
      l.depth_level + 1 as depth_level
    FROM graph_relationships r
    JOIN lineage_tree l ON r.parent_model = l.model_name
    WHERE l.depth_level < 10  -- Prevent infinite recursion
  )
  
  SELECT 
    model_name,
    MAX(depth_level) as max_lineage_depth,
    COUNT(DISTINCT root_model) as root_model_count
  FROM lineage_tree
  GROUP BY model_name
)

-- Final analysis combining graph metadata with business logic
SELECT 
  s.model_name,
  s.model_unique_id,
  s.sql_length,
  s.dependency_count,
  s.materialization,
  s.tags,
  s.sql_complexity,
  s.dependency_complexity,
  s.migration_risk,
  
  -- Lineage information
  COALESCE(l.max_lineage_depth, 0) as lineage_depth,
  COALESCE(l.root_model_count, 1) as root_dependencies,
  
  -- Graph-based recommendations
  CASE 
    WHEN s.migration_risk = 'CRITICAL' THEN 'Requires manual review and testing'
    WHEN s.migration_risk = 'HIGH' THEN 'High priority for migration validation'
    WHEN s.materialization = 'incremental' THEN 'Test incremental logic carefully'
    ELSE 'Standard migration process'
  END as migration_recommendation,
  
  -- Risk factors based on graph analysis
  ARRAY_CONSTRUCT(
    CASE WHEN s.sql_length > 2000 THEN 'COMPLEX_SQL' END,
    CASE WHEN s.dependency_count > 5 THEN 'HIGH_DEPENDENCIES' END,
    CASE WHEN l.max_lineage_depth > 3 THEN 'DEEP_LINEAGE' END,
    CASE WHEN s.materialization IN ('incremental', 'snapshot') THEN 'STATEFUL_MATERIALIZATION' END
  ) as risk_factors,
  
  s.analyzed_at

FROM sql_complexity_analysis s
LEFT JOIN lineage_depth_analysis l ON s.model_name = l.model_name

{% else %}

-- Fallback when graph is not available or not executing
SELECT 
  'graph_not_available' as model_name,
  'N/A' as model_unique_id,
  0 as sql_length,
  0 as dependency_count,
  'unknown' as materialization,
  'none' as tags,
  'UNKNOWN' as sql_complexity,
  'UNKNOWN' as dependency_complexity,
  'UNKNOWN' as migration_risk,
  0 as lineage_depth,
  0 as root_dependencies,
  'Graph analysis not available' as migration_recommendation,
  ARRAY_CONSTRUCT('GRAPH_UNAVAILABLE') as risk_factors,
  CURRENT_TIMESTAMP as analyzed_at

{% endif %}
