select *
from {{ ref('int_finance__funding_reconciliation') }}
where loan_count_variance != 0
