{{
    config(
        materialized='incremental',
        unique_key='loan_id',
        incremental_strategy='delete+insert'
    )
}}

select
    loan_id,
    funded_date,
    month_end_date,
    branch_id,
    region_id,
    program_id,
    partner_id,
    round(funded_amount, 2) as funded_amount,
    round(base_revenue, 2) as base_revenue,
    round(origination_fee_amount, 2) as origination_fee_amount,
    round(partner_revenue_amount, 2) as partner_revenue_amount,
    round(margin_adjustment_amount, 2) as margin_adjustment_amount,
    round(total_revenue, 2) as total_revenue,
    round(commission_amount, 2) as commission_amount,
    round(override_amount, 2) as override_amount,
    round(credit_cost_amount, 2) as credit_cost_amount,
    round(trueup_amount, 2) as trueup_amount,
    round(direct_cost, 2) as direct_cost,
    round(allocated_operating_cost, 2) as allocated_operating_cost,
    round(total_cost, 2) as total_cost,
    round(profit_amount, 2) as profit_amount,
    round(profit_margin_bps, 2) as profit_margin_bps,
    profitability_status,
    source_updated_at,
    current_timestamp as dbt_updated_at
from {{ ref('int_finance__profit_calculation') }}
{% if is_incremental() %}
    where source_updated_at > (select coalesce(max(source_updated_at), cast('1900-01-01' as timestamp)) from {{ this }})
{% endif %}
