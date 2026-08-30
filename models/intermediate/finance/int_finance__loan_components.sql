with monthly_loan_counts as (

    select
        month_end_date,
        branch_id,
        count(*) as monthly_branch_funded_loan_count
    from {{ ref('int_finance__loans_enriched') }}
    group by month_end_date, branch_id

)

select
    loans.loan_id,
    loans.funded_date,
    loans.month_end_date,
    loans.branch_id,
    loans.branch_name,
    loans.region_id,
    loans.region_name,
    loans.program_id,
    loans.program_name,
    loans.product_family,
    loans.partner_id,
    loans.partner_name,
    loans.funded_amount,
    revenue.base_revenue,
    revenue.origination_fee_amount,
    revenue.partner_revenue_amount,
    revenue.margin_adjustment_amount,
    loan_costs.commission_amount,
    loan_costs.override_amount,
    loan_costs.credit_cost_amount,
    loan_costs.trueup_amount,
    overhead.monthly_branch_overhead,
    monthly_loan_counts.monthly_branch_funded_loan_count,
    {{ safe_divide(
        'overhead.monthly_branch_overhead',
        'monthly_loan_counts.monthly_branch_funded_loan_count'
    ) }} as allocated_operating_cost,
    loans.updated_at as source_updated_at
from {{ ref('int_finance__loans_enriched') }} as loans
left join {{ ref('int_finance__revenue_components') }} as revenue
    on loans.loan_id = revenue.loan_id
left join {{ ref('int_finance__cost_components') }} as loan_costs
    on loans.loan_id = loan_costs.loan_id
left join {{ ref('stg_costs__branch_overhead') }} as overhead
    on
        loans.month_end_date = overhead.month_end_date
        and loans.branch_id = overhead.branch_id
left join monthly_loan_counts
    on
        loans.month_end_date = monthly_loan_counts.month_end_date
        and loans.branch_id = monthly_loan_counts.branch_id
