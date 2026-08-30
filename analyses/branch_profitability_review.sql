with latest_month as (

    select max(month_end_date) as month_end_date
    from {{ ref('fct_monthly_branch_pnl') }}

)

select
    branch_id,
    branch_name,
    region_name,
    funded_loan_count,
    funded_amount,
    total_revenue,
    total_cost,
    profit_amount,
    profit_margin_bps,
    month_over_month_profit_variance
from {{ ref('fct_monthly_branch_pnl') }}
where month_end_date = (select month_end_date from latest_month)
order by profit_amount desc
