select
    program_id,
    program_name,
    product_family,
    default_margin_bps,
    effective_start_date,
    effective_end_date
from {{ ref('stg_lending__programs') }}
