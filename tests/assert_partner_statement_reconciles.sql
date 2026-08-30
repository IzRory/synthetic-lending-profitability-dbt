select *
from {{ ref('int_finance__partner_reconciliation') }}
where
    loan_count_variance != 0
    or abs(revenue_variance) > 0.01
