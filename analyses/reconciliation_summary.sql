select
    month_end_date,
    count(*) as branch_count,
    sum(case when funded_amount_reconciles then 0 else 1 end) as funding_amount_exceptions,
    sum(case when loan_count_reconciles then 0 else 1 end) as loan_count_exceptions,
    round(sum(funded_amount_variance), 2) as net_funded_amount_variance,
    sum(loan_count_variance) as net_loan_count_variance
from {{ ref('int_finance__funding_reconciliation') }}
group by month_end_date
order by month_end_date
