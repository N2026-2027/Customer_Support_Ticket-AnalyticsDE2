{{ config(materialized='view') }}

with source as (
    select * from {{ source('raw_data', 'customer_support_tickets_200k') }}
)

select
    distinct
    -- Cambiado a minúsculas y sin comillas innecesarias si el motor ya las reconoce así
    {{ dbt_utils.generate_surrogate_key(['customer_name', 'customer_email']) }} as user_id,
    customer_name as name,
    customer_email as email
from source -- Usá la CTE 'source' que definiste arriba en lugar de llamar al source de nuevo
