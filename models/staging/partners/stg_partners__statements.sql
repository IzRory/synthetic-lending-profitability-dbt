select
    cast(nullif(trim(statement_id), '') as varchar) as statement_id,
    cast(nullif(trim(loan_id), '') as varchar) as loan_id,
    cast(nullif(trim(partner_id), '') as varchar) as partner_id,
    cast(partner_revenue_amount as decimal(18, 2)) as partner_revenue_amount,
    cast(statement_month as date) as statement_month,
    cast(received_at as timestamp) as received_at
from {{ source('raw_partners', 'statements') }}
