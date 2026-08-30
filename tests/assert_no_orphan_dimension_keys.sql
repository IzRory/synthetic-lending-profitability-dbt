select
    profitability.loan_id,
    profitability.branch_id,
    profitability.region_id,
    profitability.program_id,
    profitability.partner_id
from {{ ref('fct_loan_profitability') }} as profitability
left join {{ ref('dim_branch') }} as branches
    on profitability.branch_id = branches.branch_id
left join {{ ref('dim_program') }} as programs
    on profitability.program_id = programs.program_id
left join {{ ref('dim_partner') }} as partners
    on profitability.partner_id = partners.partner_id
where
    branches.branch_id is null
    or profitability.region_id is null
    or programs.program_id is null
    or (profitability.partner_id is not null and partners.partner_id is null)
