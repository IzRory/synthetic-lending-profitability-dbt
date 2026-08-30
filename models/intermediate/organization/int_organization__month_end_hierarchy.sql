with branch_months as (

    select distinct
        branch_id,
        month_end_date
    from {{ ref('stg_lending__loans') }}

),

current_snapshot_rows as (

    select
        branch_id,
        branch_name,
        region_id,
        region_name,
        effective_start_date,
        effective_end_date
    from {{ ref('snap_branch_hierarchy') }}
    where dbt_valid_to is null

),

resolved as (

    select
        branch_months.branch_id,
        branch_months.month_end_date,
        hierarchy.branch_name,
        hierarchy.region_id,
        hierarchy.region_name,
        hierarchy.effective_start_date,
        hierarchy.effective_end_date,
        row_number() over (
            partition by branch_months.branch_id, branch_months.month_end_date
            order by hierarchy.effective_start_date desc
        ) as assignment_rank
    from branch_months
    left join current_snapshot_rows as hierarchy
        on
            branch_months.branch_id = hierarchy.branch_id
            and branch_months.month_end_date >= hierarchy.effective_start_date
            and branch_months.month_end_date <= coalesce(hierarchy.effective_end_date, cast('9999-12-31' as date))

)

select
    branch_id,
    month_end_date,
    branch_name,
    region_id,
    region_name,
    effective_start_date,
    effective_end_date
from resolved
where assignment_rank = 1
