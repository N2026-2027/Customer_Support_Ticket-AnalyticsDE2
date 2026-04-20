{{ config(materialized='table') }}

-- FIX: GROUP BY limpio — first_response_time_hours, resolution_time_hours
-- y customer_satisfaction_score son métricas, van en avg(), NO en GROUP BY.

with base as (
    select * from {{ ref('stg_tickets') }}
),

enriched as (
    select
        *,
        extract('year'  from ticket_created_date)::integer  as part_year,
        extract('month' from ticket_created_date)::integer  as part_month,
        case when status in ('open','pending customer response')
             then 1 else 0 end                              as is_backlog,
        case when priority = 'critical'
              and status != 'closed'
             then 1 else 0 end                              as is_critical_unresolved
    from base
)

select
    part_year,
    part_month,
    ticket_channel,
    priority                                    as ticket_priority,
    status                                      as ticket_status,
    category                                    as ticket_type,
    ticket_subject,
    count(*)                                    as total_tickets,
    avg(first_response_time_hours)              as avg_first_response_hrs,
    avg(resolution_time_hours)                  as avg_resolution_hrs,
    avg(customer_satisfaction_score)            as avg_satisfaction,
    sum(is_backlog)                             as backlog_count,
    sum(is_critical_unresolved)                 as critical_unresolved_count,
    round(
        100.0 * sum(is_critical_unresolved)
            / nullif(sum(case when priority='critical' then 1 end), 0)
    , 1)                                        as pct_critical_unresolved
from enriched
group by
    part_year, part_month, ticket_channel,
    priority, status, category, ticket_subject
order by part_year, part_month, ticket_channel
