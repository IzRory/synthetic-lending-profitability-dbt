select
    cast(nullif(trim(branch_id), '') as varchar) as branch_id,
    cast(nullif(trim(branch_name), '') as varchar) as branch_name,
    cast(nullif(trim(region_id), '') as varchar) as region_id,
    cast(nullif(trim(region_name), '') as varchar) as region_name,
    cast(effective_start_date as date) as effective_start_date,
    cast(effective_end_date as date) as effective_end_date,
    cast(is_active as boolean) as is_active
from {{ source('raw_lending', 'branch_hierarchy') }}
