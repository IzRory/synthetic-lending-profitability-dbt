{% snapshot snap_branch_hierarchy %}

{{
    config(
        target_schema=target.schema,
        unique_key="branch_id || '|' || cast(effective_start_date as varchar)",
        strategy='check',
        check_cols=['branch_name', 'region_id', 'region_name', 'effective_end_date', 'is_active']
    )
}}

    select
        branch_id,
        branch_name,
        region_id,
        region_name,
        effective_start_date,
        effective_end_date,
        is_active
    from {{ ref('stg_lending__branch_hierarchy') }}

{% endsnapshot %}
