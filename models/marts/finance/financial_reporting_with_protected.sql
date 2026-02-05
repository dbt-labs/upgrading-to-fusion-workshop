{{ config(
    materialized="table", 
    description="Financial reporting model with protected access - ", 
    meta={'restrict_access': True, 'access_level': 'protected'}
) }}

-- This model references protected models from packages and has restrict-access: true

with 
-- Simulated protected data (would normally come from restricted access models)
protected_customer_data as (
    -- This simulates data that would come from protected/restricted models
    -- In a real scenario, this would reference models with access restrictions
    select 
        customer_id,
        customer_name,
        lifetime_spend,
        first_ordered_at,
        last_ordered_at,
        
        -- Simulated protected/sensitive fields that would come from protected models
        'REDACTED' as ssn_hash,
        'REDACTED' as credit_score,
        'PROTECTED' as payment_method_details,
        
        -- Mark as protected data
        'PROTECTED_MODEL_DATA' as data_classification,
        current_timestamp as access_logged_at
        
    from {{ ref('customers') }}
    where lifetime_spend > 500  -- Only high-value customers for financial reporting
),

-- Simulated sensitive revenue data (would normally be access-restricted)
protected_revenue_data as (
    -- This simulates sensitive financial data with restricted access
    -- In production, this would come from models with access controls
    select 
        o.order_id,
        o.customer_id,
        o.order_total,
        o.ordered_at,
        
        -- Simulated sensitive financial metrics
        o.order_total * 0.15 as estimated_profit_margin,
        o.order_total * 0.05 as commission_amount,
        
        -- Protected classification
        'FINANCIAL_SENSITIVE' as data_classification,
        'RESTRICTED_ACCESS' as access_level
        
    from {{ ref('orders') }} o
    where o.order_total > 100  -- Only significant revenue transactions
),

-- Combine protected data sources
combined_protected_data as (
    select
        pcd.customer_id,
        pcd.customer_name,
        pcd.lifetime_spend,
        pcd.ssn_hash,
        pcd.credit_score,
        pcd.payment_method_details,
        
        -- Aggregate protected revenue metrics
        sum(prd.order_total) as total_protected_revenue,
        sum(prd.estimated_profit_margin) as total_estimated_profit,
        sum(prd.commission_amount) as total_commission,
        count(prd.order_id) as protected_transaction_count,
        
        -- Access control metadata
        'FINANCIAL_REPORTING_TEAM' as authorized_access_group,
        'PII_AND_FINANCIAL' as data_sensitivity_level,
        current_timestamp as report_generated_at,
        '{{ run_started_at }}' as dbt_run_id
        
    from protected_customer_data pcd
    left join protected_revenue_data prd on pcd.customer_id = prd.customer_id
    group by 
        pcd.customer_id,
        pcd.customer_name,
        pcd.lifetime_spend,
        pcd.ssn_hash,
        pcd.credit_score,
        pcd.payment_method_details
),

-- Final protected financial report
final_protected_report as (
    select
        *,
        
        -- Calculate protected financial ratios
        case 
            when lifetime_spend > 0 then total_estimated_profit / lifetime_spend
            else 0
        end as profit_margin_ratio,
        
        case 
            when protected_transaction_count > 0 then total_protected_revenue / protected_transaction_count
            else 0
        end as avg_protected_transaction_value,
        
        -- Risk assessment (protected calculation)
        case 
            when credit_score = 'REDACTED' then 'PROTECTED_ASSESSMENT'
            when total_estimated_profit > 1000 then 'HIGH_VALUE_SECURE'
            when total_estimated_profit > 500 then 'MEDIUM_VALUE_SECURE'
            else 'STANDARD_SECURE'
        end as risk_tier,
        
        -- Compliance and audit fields
        'SOX_COMPLIANT' as compliance_status,
        'QUARTERLY_FINANCIAL_REVIEW' as report_purpose,
        md5(concat(customer_id, report_generated_at)) as audit_hash
        
    from combined_protected_data
)

select * from final_protected_report

-- Additional access control comment
-- This model contains PII and financial data requiring special access permissions
-- Access logged for compliance purposes
