select
    loans.loan_id,
    loans.funded_date,
    loans.month_end_date,
    loans.branch_id,
    hierarchy.branch_name,
    hierarchy.region_id,
    hierarchy.region_name,
    loans.program_id,
    programs.program_name,
    programs.product_family,
    loans.partner_id,
    case loans.partner_id
        when 'PT01' then 'Alpine Community Partners'
        when 'PT02' then 'Blue Mesa Housing Group'
        when 'PT03' then 'Cedar Peak Network'
        when 'PT04' then 'Highland Access Alliance'
        when 'PT05' then 'Juniper Home Partners'
    end as partner_name,
    loans.funded_amount,
    loans.base_margin_bps,
    loans.origination_fee_amount,
    loans.loan_status,
    loans.created_at,
    loans.updated_at
from {{ ref('stg_lending__loans') }} as loans
left join {{ ref('stg_lending__programs') }} as programs
    on
        loans.program_id = programs.program_id
        and loans.funded_date >= programs.effective_start_date
        and loans.funded_date <= coalesce(programs.effective_end_date, cast('9999-12-31' as date))
left join {{ ref('int_organization__month_end_hierarchy') }} as hierarchy
    on
        loans.branch_id = hierarchy.branch_id
        and loans.month_end_date = hierarchy.month_end_date
