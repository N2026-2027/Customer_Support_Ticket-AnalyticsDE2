

-- ============================================================
-- mart_operations_sla_partitioned
-- ============================================================

with base as (
    select * from "support_200k"."main"."stg_tickets"
),

enriched as (
    select
        *,
        -- CORRECCIÓN: purchase_date no existe, usamos ticket_created_date
        extract('year'  from ticket_created_date)::integer  as part_year,
        extract('month' from ticket_created_date)::integer  as part_month,

        -- SLA flags (Ajustados a columnas reales: status y priority)
        case when status in ('open','pending customer response')
             then 1 else 0 end                         as is_backlog,
        case when priority = 'critical'
              and status != 'closed' then 1 else 0 end as is_critical_unresolved

    from base
)

select
    -- ── Columnas de partición y cluster key
    part_year,
    part_month,
    channel as ticket_channel,          

    -- ── Dimensiones (mapeadas a nombres reales)
    priority as ticket_priority,
    status as ticket_status,
    category as ticket_type,
    category as ticket_subject, -- Usado como proxy de subject

    -- ── Métricas (basadas en columnas confirmadas)
    count(*)                                 as total_tickets,
    avg(first_response_time_hours)           as avg_first_response_hrs,
    avg(resolution_time_hours)               as avg_resolution_hrs,
    avg(customer_satisfaction_score)         as avg_satisfaction,
    sum(is_backlog)                          as backlog_count,
    sum(is_critical_unresolved)              as critical_unresolved_count,

    round(
        100.0 * sum(is_critical_unresolved)
            / nullif(sum(case when priority='critical' then 1 end), 0)
    , 1)                                     as pct_critical_unresolved

from enriched
group by 1,2,3,4,5,6,7
order by part_year, part_month, ticket_channel