
  
  create view "support_200k"."main"."stg_all_tickets__dbt_tmp" as (
    

-- Eliminamos el UNION ALL y apuntamos solo al que funciona
select 
    ticket_id,
    customer_email,
    '200k' as dataset_source
from "support_200k"."main"."stg_tickets_200k"
  );
