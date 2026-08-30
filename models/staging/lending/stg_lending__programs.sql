select
    cast(nullif(trim(program_id), '') as varchar) as program_id,
    cast(nullif(trim(program_name), '') as varchar) as program_name,
    upper(cast(nullif(trim(product_family), '') as varchar)) as product_family,
    cast(default_margin_bps as decimal(10, 2)) as default_margin_bps,
    cast(effective_start_date as date) as effective_start_date,
    cast(effective_end_date as date) as effective_end_date
from {{ source('raw_lending', 'programs') }}
