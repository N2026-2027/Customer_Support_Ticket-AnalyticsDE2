{{ config(materialized='view') }}

-- Eliminamos el UNION ALL y apuntamos solo al que funciona
select 
    ticket_id,
    customer_email,
    '200k' as dataset_source
from {{ ref('stg_tickets_200k') }}
