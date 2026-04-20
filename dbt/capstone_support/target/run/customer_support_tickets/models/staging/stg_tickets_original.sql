
  
  create view "support_200k"."main"."stg_tickets_original__dbt_tmp" as (
    SELECT 
    ticket_id,
    customer_name,
    category,
    priority,
    status,
    resolution_time_hours,
    'original' as dataset_source
FROM "support_200k"."main"."customer_support_tickets_200k"
  );
