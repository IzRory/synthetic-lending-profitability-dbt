select *
from {{ ref('fct_loan_profitability') }}
where round(abs(total_revenue - total_cost - profit_amount), 2) > 0.01
