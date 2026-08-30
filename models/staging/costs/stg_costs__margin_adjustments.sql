select
    cast(nullif(trim(margin_adjustment_id), '') as varchar) as margin_adjustment_id,
    cast(nullif(trim(loan_id), '') as varchar) as loan_id,
    cast(adjustment_month as date) as adjustment_month,
    cast(margin_adjustment_amount as decimal(18, 2)) as margin_adjustment_amount,
    upper(cast(nullif(trim(adjustment_reason), '') as varchar)) as adjustment_reason
from {{ source('raw_costs', 'margin_adjustments') }}
