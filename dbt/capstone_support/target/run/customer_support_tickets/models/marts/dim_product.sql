
  
    
    

    create  table
      "support_200k"."main_marts"."dim_product__dbt_tmp"
  
    as (
      

WITH base AS (
    SELECT DISTINCT
        product,
        -- Usamos el nombre real que viene del staging: ticket_channel
        COALESCE(ticket_channel, 'unknown') as channel_name
    FROM "support_200k"."main_staging"."stg_tickets_200k"
)

SELECT
    md5(cast(coalesce(cast(product as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(channel_name as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS product_sk,
    product,
    channel_name as channel
FROM base
    );
  
  