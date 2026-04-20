{{ config(materialized='view') }}

with raw_users as (
    -- Cambiamos el nombre de la fuente según tu nuevo sources.yml
    select * from {{ source('raw_200k', 'customer_support_tickets_200k') }}
)

select
    -- IMPORTANTE: Si la tabla de 200k ya es snake_case, no necesita comillas dobles
    {{ dbt_utils.generate_surrogate_key(['customer_name', 'customer_email']) }} as customer_id,
    lower(trim(customer_name)) as customer_name,
    lower(trim(customer_email)) as customer_email,
    lower(trim(customer_gender)) as customer_gender,
    cast(customer_age as integer) as customer_age,
    current_timestamp as _ingested_at
from raw_users
-- Agregamos group by para tener usuarios únicos sin duplicados
group by 1,2,3,4,5,6
