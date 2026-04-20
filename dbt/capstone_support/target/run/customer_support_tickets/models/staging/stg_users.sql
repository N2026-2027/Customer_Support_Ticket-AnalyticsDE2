
  
  create view "support_200k"."main"."stg_users__dbt_tmp" as (
    

with source as (
    select * from "support_200k"."main"."customer_support_tickets_200k"
)

select
    distinct
    -- Cambiado a minúsculas y sin comillas innecesarias si el motor ya las reconoce así
    md5(cast(coalesce(cast(customer_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(customer_email as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as user_id,
    customer_name as name,
    customer_email as email
from source -- Usá la CTE 'source' que definiste arriba en lugar de llamar al source de nuevo
  );
