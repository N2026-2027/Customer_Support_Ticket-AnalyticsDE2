
  
    
    

    create  table
      "support_200k"."main_marts"."mart_operations_sla__dbt_tmp"
  
    as (
      

-- Dashboard 1 & 2: Operations Overview + Channel Performance

with base as (
    select * from "support_200k"."main_staging"."stg_tickets"
),

per_channel as (
    select
        ticket_channel,
        priority                            as ticket_priority,
        status                              as ticket_status,
        category                            as ticket_type,

        -- Ajuste de nombres de columnas de fecha
        extract('dow'   from ticket_created_date) as day_of_week,
        strftime(ticket_created_date, '%A')       as day_name,
        extract('month' from ticket_created_date) as month_num,
        strftime(ticket_created_date, '%B')       as month_name,
        extract('year'  from ticket_created_date) as year,

        -- Ajuste de nombres de columnas métricas
        first_response_time_hours           as first_response_hrs,
        resolution_time_hours               as resolution_hrs,
        customer_satisfaction_score         as satisfaction_rating,

        -- SLA flags
        case when resolution_time_hours <= 24 then 1 else 0 end    as resolved_under_24h,
        case when status in ('open','pending customer response')
             then 1 else 0 end                                     as is_backlog,
        case when priority = 'critical'
              and status != 'closed' then 1 else 0 end             as is_critical_unresolved

    from base
)

select
    ticket_channel,
    ticket_priority,
    ticket_status,
    ticket_type,
    day_of_week,
    day_name,
    month_num,
    month_name,
    year,

    count(*)                                  as total_tickets,
    avg(first_response_hrs)                   as avg_first_response_hrs,
    avg(resolution_hrs)                       as avg_resolution_hrs,
    avg(satisfaction_rating)                  as avg_satisfaction,

    sum(resolved_under_24h)                   as tickets_resolved_under_24h,
    round(
        100.0 * sum(resolved_under_24h) / nullif(count(*), 0), 1
    )                                         as pct_resolved_under_24h,

    sum(is_backlog)                           as backlog_count,
    sum(is_critical_unresolved)               as critical_unresolved_count,

    round(
        100.0 * sum(is_critical_unresolved)
            / nullif(sum(case when ticket_priority='critical' then 1 else 0 end), 0)
    , 1)                                      as pct_critical_unresolved

from per_channel
group by 1,2,3,4,5,6,7,8,9
    );
  
  