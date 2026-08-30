select
    cast(nullif(trim(override_id), '') as varchar) as override_id,
    cast(nullif(trim(loan_id), '') as varchar) as loan_id,
    cast(override_month as date) as override_month,
    cast(override_amount as decimal(18, 2)) as override_amount,
    upper(cast(nullif(trim(override_type), '') as varchar)) as override_type
from {{ source('raw_costs', 'overrides') }}
