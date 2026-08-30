select
    branch_id,
    branch_name,
    region_id as current_region_id,
    region_name as current_region_name,
    effective_start_date as current_assignment_start_date
from {{ ref('stg_lending__branch_hierarchy') }}
where is_active
