select
    loans.loan_id,
    count(hierarchy.branch_id) as hierarchy_assignment_count
from {{ ref('stg_lending__loans') }} as loans
left join {{ ref('int_organization__month_end_hierarchy') }} as hierarchy
    on
        loans.branch_id = hierarchy.branch_id
        and loans.month_end_date = hierarchy.month_end_date
group by loans.loan_id
having count(hierarchy.branch_id) != 1
