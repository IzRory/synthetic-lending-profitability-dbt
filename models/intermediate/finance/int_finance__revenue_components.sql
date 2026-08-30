with partner_revenue as (

    select
        loan_id,
        sum(partner_revenue_amount) as partner_revenue_amount
    from {{ ref('stg_partners__statements') }}
    group by loan_id

),

margin_adjustments as (

    select
        loan_id,
        sum(margin_adjustment_amount) as margin_adjustment_amount
    from {{ ref('stg_costs__margin_adjustments') }}
    group by loan_id

)

select
    loans.loan_id,
    loans.funded_amount * loans.base_margin_bps / 10000.0 as base_revenue,
    loans.origination_fee_amount,
    coalesce(partner_revenue.partner_revenue_amount, 0.0) as partner_revenue_amount,
    coalesce(margin_adjustments.margin_adjustment_amount, 0.0) as margin_adjustment_amount
from {{ ref('stg_lending__loans') }} as loans
left join partner_revenue
    on loans.loan_id = partner_revenue.loan_id
left join margin_adjustments
    on loans.loan_id = margin_adjustments.loan_id
