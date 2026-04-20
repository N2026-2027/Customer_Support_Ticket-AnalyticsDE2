
  
    
    

    create  table
      "support_200k"."main"."mart_cx_satisfaction__dbt_tmp"
  
    as (
      

-- Dashboard 3: Priority Matrix + CX
-- Responde:
--   - Correlación edad-satisfacción
--   - Canal con mayor satisfacción
--   - Producto con más quejas críticas
--   - Diferencia de satisfacción por género
--   - Tickets con mayor resolution_time_hours → peor rating

with base as (
    select * from "support_200k"."main"."stg_tickets"
),

enriched as (
    select
        *,
        case
            when customer_age < 25               then 'Gen Z (<25)'
            when customer_age between 25 and 34  then 'Millennial (25-34)'
            when customer_age between 35 and 44  then 'Gen X (35-44)'
            when customer_age between 45 and 59  then 'Boomer (45-59)'
            else                                      'Senior (60+)'
        end as age_segment,

        -- Bucket de resolución (CORREGIDO: resolution_time_hours)
        case
            when resolution_time_hours < 6   then '0-6h'
            when resolution_time_hours < 24  then '6-24h'
            when resolution_time_hours < 72  then '1-3 days'
            else                                  '3+ days'
        end as resolution_bucket

    from base
)

select
    channel as ticket_channel,
    priority as ticket_priority,
    category as ticket_type,
    status as ticket_status,
    product as product_purchased,
    customer_gender,
    age_segment,
    resolution_bucket,

    count(*)                           as total_tickets,
    avg(customer_satisfaction_score)   as avg_satisfaction,
    avg(resolution_time_hours)         as avg_resolution_hrs,
    avg(first_response_time_hours)     as avg_first_response_hrs,

    -- Para Priority Matrix heatmap
    sum(case when priority = 'critical' then 1 else 0 end) as critical_count,
    sum(case when status   = 'closed'   then 1 else 0 end) as closed_count,

    round(
        100.0 * sum(case when status='closed' then 1 else 0 end) / count(*)
    , 1) as pct_closed

from enriched
group by 1,2,3,4,5,6,7,8
    );
  
  