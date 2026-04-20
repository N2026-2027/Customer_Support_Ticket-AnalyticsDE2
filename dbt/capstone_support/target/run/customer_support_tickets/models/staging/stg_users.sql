
  
  create view "support_200k"."main_staging"."stg_users__dbt_tmp" as (
    

with raw_users as (
    -- Cambiamos el nombre de la fuente según tu nuevo sources.yml
    select * from "support_200k"."main"."customer_support_tickets_200k"
)

select
    -- IMPORTANTE: Si la tabla de 200k ya es snake_case, no necesita comillas dobles
    md5(cast(coalesce(cast(customer_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(customer_email as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as customer_id,
    lower(trim(customer_name)) as customer_name,
    lower(trim(customer_email)) as customer_email,
    lower(trim(customer_gender)) as customer_gender,
    cast(customer_age as integer) as customer_age,
    current_timestamp as _ingested_at
from raw_users
-- Agregamos group by para tener usuarios únicos sin duplicados
group by 1,2,3,4,5,6
  );
