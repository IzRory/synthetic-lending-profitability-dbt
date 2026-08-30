select
    cast(nullif(trim(commission_id), '') as varchar) as commission_id,
    cast(nullif(trim(loan_id), '') as varchar) as loan_id,
    cast(commission_month as date) as commission_month,
    cast(commission_amount as decimal(18, 2)) as commission_amount,
    upper(cast(nullif(trim(commission_type), '') as varchar)) as commission_type
from {{ source('raw_costs', 'commissions') }}
