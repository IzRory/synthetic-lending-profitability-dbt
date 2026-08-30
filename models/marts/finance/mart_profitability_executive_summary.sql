with region_month as (

    select
        month_end_date,
        region_id,
        max(region_name) as region_name,
        sum(funded_loan_count) as funded_loan_count,
        round(sum(funded_amount), 2) as funded_amount,
        round(sum(total_revenue), 2) as total_revenue,
        round(sum(total_cost), 2) as total_cost,
        round(sum(profit_amount), 2) as profit_amount,
        round({{ safe_divide('sum(profit_amount)', 'sum(funded_amount)') }} * 10000.0, 2) as profit_margin_bps
    from {{ ref('fct_monthly_branch_pnl') }}
    group by month_end_date, region_id

),

company_month as (

    select
        month_end_date,
        'COMPANY' as region_id,
        'Summit Ridge Lending' as region_name,
        sum(funded_loan_count) as funded_loan_count,
        round(sum(funded_amount), 2) as funded_amount,
        round(sum(total_revenue), 2) as total_revenue,
        round(sum(total_cost), 2) as total_cost,
        round(sum(profit_amount), 2) as profit_amount,
        round({{ safe_divide('sum(profit_amount)', 'sum(funded_amount)') }} * 10000.0, 2) as profit_margin_bps
    from {{ ref('fct_monthly_branch_pnl') }}
    group by month_end_date

),

combined as (

    select * from region_month
    union all
    select * from company_month

),

with_prior_month as (

    select
        *,
        lag(funded_amount) over (partition by region_id order by month_end_date) as prior_month_funded_amount,
        lag(profit_amount) over (partition by region_id order by month_end_date) as prior_month_profit_amount,
        lag(profit_margin_bps) over (partition by region_id order by month_end_date) as prior_month_profit_margin_bps
    from combined

)

select
    *,
    round(funded_amount - prior_month_funded_amount, 2) as funded_amount_variance,
    round(profit_amount - prior_month_profit_amount, 2) as profit_amount_variance,
    round(profit_margin_bps - prior_month_profit_margin_bps, 2) as profit_margin_bps_variance
from with_prior_month
