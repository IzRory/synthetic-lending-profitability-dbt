select *
from {{ ref('fct_loan_profitability') }}
where
    base_revenue is null
    or origination_fee_amount is null
    or partner_revenue_amount is null
    or margin_adjustment_amount is null
    or commission_amount is null
    or override_amount is null
    or credit_cost_amount is null
    or trueup_amount is null
    or allocated_operating_cost is null
