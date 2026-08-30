select
    cast(nullif(trim(credit_transaction_id), '') as varchar) as credit_transaction_id,
    cast(nullif(trim(loan_id), '') as varchar) as loan_id,
    cast(transaction_date as date) as transaction_date,
    cast(credit_cost_amount as decimal(18, 2)) as credit_cost_amount,
    upper(cast(nullif(trim(transaction_type), '') as varchar)) as transaction_type
from {{ source('raw_costs', 'credit_transactions') }}
