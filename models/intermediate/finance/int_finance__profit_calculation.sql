with calculated as (

    select
        *,
        base_revenue
        + origination_fee_amount
        + partner_revenue_amount
        + margin_adjustment_amount as total_revenue,
        commission_amount
        + override_amount
        + credit_cost_amount
        + trueup_amount as direct_cost
    from {{ ref('int_finance__loan_components') }}

),

profit as (

    select
        *,
        direct_cost + allocated_operating_cost as total_cost,
        total_revenue - (direct_cost + allocated_operating_cost) as profit_amount
    from calculated

)

select
    *,
    {{ safe_divide('profit_amount', 'funded_amount') }} * 10000.0 as profit_margin_bps,
    case
        when profit_amount > 0 then 'PROFITABLE'
        when profit_amount = 0 then 'BREAK_EVEN'
        else 'UNPROFITABLE'
    end as profitability_status
from profit
