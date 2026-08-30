with branch_month as (

    select
        profitability.month_end_date,
        profitability.branch_id,
        max(hierarchy.branch_name) as branch_name,
        profitability.region_id,
        max(hierarchy.region_name) as region_name,
        count(*) as funded_loan_count,
        round(sum(profitability.funded_amount), 2) as funded_amount,
        round(sum(profitability.total_revenue), 2) as total_revenue,
        round(sum(profitability.direct_cost), 2) as direct_cost,
        round(sum(profitability.allocated_operating_cost), 2) as allocated_operating_cost,
        round(sum(profitability.total_cost), 2) as total_cost,
        round(sum(profitability.profit_amount), 2) as profit_amount,
        round({{ safe_divide('sum(profitability.profit_amount)', 'sum(profitability.funded_amount)') }} * 10000.0, 2)
            as profit_margin_bps,
        bool_and(reconciliation.funded_amount_reconciles) as funded_amount_reconciles,
        bool_and(reconciliation.loan_count_reconciles) as loan_count_reconciles
    from {{ ref('fct_loan_profitability') }} as profitability
    left join {{ ref('int_organization__month_end_hierarchy') }} as hierarchy
        on
            profitability.branch_id = hierarchy.branch_id
            and profitability.month_end_date = hierarchy.month_end_date
    left join {{ ref('int_finance__funding_reconciliation') }} as reconciliation
        on
            profitability.branch_id = reconciliation.branch_id
            and profitability.month_end_date = reconciliation.month_end_date
    group by
        profitability.month_end_date,
        profitability.branch_id,
        profitability.region_id

)

select
    *,
    lag(funded_amount) over (partition by branch_id order by month_end_date) as prior_month_funded_amount,
    lag(profit_amount) over (partition by branch_id order by month_end_date) as prior_month_profit_amount,
    lag(profit_margin_bps) over (partition by branch_id order by month_end_date) as prior_month_profit_margin_bps,
    round(
        profit_amount - lag(profit_amount) over (partition by branch_id order by month_end_date),
        2
    ) as month_over_month_profit_variance
from branch_month
