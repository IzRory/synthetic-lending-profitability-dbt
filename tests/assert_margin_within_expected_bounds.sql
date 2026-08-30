select *
from {{ ref('fct_loan_profitability') }}
where
    profit_margin_bps < -1500
    or profit_margin_bps > 1500
