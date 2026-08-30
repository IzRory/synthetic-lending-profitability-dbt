select
    cast(month_end_date as date) as month_end_date,
    cast(nullif(trim(branch_id), '') as varchar) as branch_id,
    cast(statement_loan_count as integer) as statement_loan_count,
    cast(statement_funded_amount as decimal(18, 2)) as statement_funded_amount,
    upper(cast(nullif(trim(statement_source), '') as varchar)) as statement_source
from {{ source('raw_lending', 'funding_statements') }}
