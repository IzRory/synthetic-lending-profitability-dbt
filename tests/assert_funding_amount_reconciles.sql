select *
from {{ ref('int_finance__funding_reconciliation') }}
where abs(funded_amount_variance) > 0.01
