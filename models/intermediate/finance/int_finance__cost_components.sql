with credit_costs as (

    select
        loan_id,
        sum(credit_cost_amount) as credit_cost_amount
    from {{ ref('stg_costs__credit_transactions') }}
    group by loan_id

),

commissions as (

    select
        loan_id,
        sum(commission_amount) as commission_amount
    from {{ ref('stg_costs__commissions') }}
    group by loan_id

),

overrides as (

    select
        loan_id,
        sum(override_amount) as override_amount
    from {{ ref('stg_costs__overrides') }}
    group by loan_id

),

trueups as (

    select
        loan_id,
        sum(trueup_amount) as trueup_amount
    from {{ ref('stg_costs__trueups') }}
    group by loan_id

)

select
    loans.loan_id,
    coalesce(commissions.commission_amount, 0.0) as commission_amount,
    coalesce(overrides.override_amount, 0.0) as override_amount,
    coalesce(credit_costs.credit_cost_amount, 0.0) as credit_cost_amount,
    coalesce(trueups.trueup_amount, 0.0) as trueup_amount
from {{ ref('stg_lending__loans') }} as loans
left join credit_costs
    on loans.loan_id = credit_costs.loan_id
left join commissions
    on loans.loan_id = commissions.loan_id
left join overrides
    on loans.loan_id = overrides.loan_id
left join trueups
    on loans.loan_id = trueups.loan_id
