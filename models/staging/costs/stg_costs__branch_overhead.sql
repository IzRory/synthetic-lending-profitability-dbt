select
    cast(month_end_date as date) as month_end_date,
    cast(nullif(trim(branch_id), '') as varchar) as branch_id,
    cast(monthly_branch_overhead as decimal(18, 2)) as monthly_branch_overhead,
    upper(cast(nullif(trim(overhead_basis), '') as varchar)) as overhead_basis
from {{ source('raw_costs', 'branch_overhead') }}
