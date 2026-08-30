select
    cast(nullif(trim(trueup_id), '') as varchar) as trueup_id,
    cast(nullif(trim(loan_id), '') as varchar) as loan_id,
    cast(posting_month as date) as posting_month,
    cast(trueup_amount as decimal(18, 2)) as trueup_amount,
    upper(cast(nullif(trim(trueup_reason), '') as varchar)) as trueup_reason
from {{ source('raw_costs', 'trueups') }}
