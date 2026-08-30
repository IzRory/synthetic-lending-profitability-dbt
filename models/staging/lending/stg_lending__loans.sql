select
    cast(nullif(trim(loan_id), '') as varchar) as loan_id,
    cast(funded_date as date) as funded_date,
    cast(month_end_date as date) as month_end_date,
    cast(nullif(trim(branch_id), '') as varchar) as branch_id,
    cast(nullif(trim(program_id), '') as varchar) as program_id,
    cast(nullif(trim(partner_id), '') as varchar) as partner_id,
    cast(funded_amount as decimal(18, 2)) as funded_amount,
    cast(base_margin_bps as decimal(10, 2)) as base_margin_bps,
    cast(origination_fee_amount as decimal(18, 2)) as origination_fee_amount,
    upper(cast(nullif(trim(status), '') as varchar)) as loan_status,
    cast(created_at as timestamp) as created_at,
    cast(updated_at as timestamp) as updated_at
from {{ source('raw_lending', 'loans') }}
