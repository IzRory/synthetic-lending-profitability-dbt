with modeled as (

    select
        month_end_date,
        branch_id,
        count(*) as modeled_loan_count,
        sum(funded_amount) as modeled_funded_amount
    from {{ ref('stg_lending__loans') }}
    group by month_end_date, branch_id

)

select
    coalesce(modeled.month_end_date, statements.month_end_date) as month_end_date,
    coalesce(modeled.branch_id, statements.branch_id) as branch_id,
    coalesce(modeled.modeled_loan_count, 0) as modeled_loan_count,
    coalesce(statements.statement_loan_count, 0) as statement_loan_count,
    coalesce(modeled.modeled_funded_amount, 0.0) as modeled_funded_amount,
    coalesce(statements.statement_funded_amount, 0.0) as statement_funded_amount,
    coalesce(modeled.modeled_loan_count, 0) - coalesce(statements.statement_loan_count, 0) as loan_count_variance,
    coalesce(modeled.modeled_funded_amount, 0.0)
    - coalesce(statements.statement_funded_amount, 0.0) as funded_amount_variance,
    abs(
        coalesce(modeled.modeled_funded_amount, 0.0)
        - coalesce(statements.statement_funded_amount, 0.0)
    ) <= 0.01 as funded_amount_reconciles,
    coalesce(modeled.modeled_loan_count, 0) = coalesce(statements.statement_loan_count, 0) as loan_count_reconciles
from modeled
full outer join {{ ref('stg_lending__funding_statements') }} as statements
    on
        modeled.month_end_date = statements.month_end_date
        and modeled.branch_id = statements.branch_id
