select distinct
    partner_id,
    case partner_id
        when 'PT01' then 'Alpine Community Partners'
        when 'PT02' then 'Blue Mesa Housing Group'
        when 'PT03' then 'Cedar Peak Network'
        when 'PT04' then 'Highland Access Alliance'
        when 'PT05' then 'Juniper Home Partners'
    end as partner_name
from {{ ref('stg_partners__statements') }}
