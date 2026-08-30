with modeled as (

    select
        loans.month_end_date,
        loans.partner_id,
        count(*) as modeled_loan_count,
        sum(revenue.partner_revenue_amount) as modeled_partner_revenue
    from {{ ref('stg_lending__loans') }} as loans
    inner join {{ ref('int_finance__revenue_components') }} as revenue
        on loans.loan_id = revenue.loan_id
    where loans.partner_id is not null
    group by loans.month_end_date, loans.partner_id

),

statements as (

    select
        statement_month as month_end_date,
        partner_id,
        count(distinct loan_id) as statement_loan_count,
        sum(partner_revenue_amount) as statement_partner_revenue
    from {{ ref('stg_partners__statements') }}
    group by statement_month, partner_id

)

select
    coalesce(modeled.month_end_date, statements.month_end_date) as month_end_date,
    coalesce(modeled.partner_id, statements.partner_id) as partner_id,
    coalesce(modeled.modeled_loan_count, 0) as modeled_loan_count,
    coalesce(statements.statement_loan_count, 0) as statement_loan_count,
    coalesce(modeled.modeled_partner_revenue, 0.0) as modeled_partner_revenue,
    coalesce(statements.statement_partner_revenue, 0.0) as statement_partner_revenue,
    coalesce(modeled.modeled_loan_count, 0) - coalesce(statements.statement_loan_count, 0) as loan_count_variance,
    coalesce(modeled.modeled_partner_revenue, 0.0)
    - coalesce(statements.statement_partner_revenue, 0.0) as revenue_variance
from modeled
full outer join statements
    on
        modeled.month_end_date = statements.month_end_date
        and modeled.partner_id = statements.partner_id
