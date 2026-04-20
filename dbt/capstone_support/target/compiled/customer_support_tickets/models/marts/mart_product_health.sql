

-- ============================================================
-- mart_product_health
-- Pregunta central: ¿Qué productos generan más dolor al cliente?
-- ============================================================

with base as (
    select * from "support_200k"."main_staging"."stg_tickets"
),

product_stats as (
    select
        product_purchased,
        ticket_subject,
        category                                                   as ticket_type,
        priority                                                   as ticket_priority,
        status                                                     as ticket_status,
        ticket_channel,

        count(*)                                                   as total_tickets,
        avg(customer_satisfaction_score)                           as avg_satisfaction,

        -- Tasa de resolución (solo cerrados)
        round(
            100.0 * sum(case when status = 'closed' then 1 else 0 end)
            / count(*)
        , 1)                                                       as pct_resolved,

        -- Tickets que nunca tuvieron respuesta
        sum(case when is_open_no_response then 1 else 0 end)       as no_response_count,

        round(
            100.0 * sum(case when is_open_no_response then 1 else 0 end)
            / count(*)
        , 1)                                                       as pct_no_response,

        -- Tickets críticos
        sum(case when priority = 'critical' then 1 else 0 end) as critical_count,

        round(
            100.0 * sum(case when priority = 'critical' then 1 else 0 end)
            / count(*)
        , 1)                                                       as pct_critical,

        -- Peor escenario: crítico + sin resolver
        sum(case
                when priority = 'critical'
                 and status != 'closed' then 1 else 0
            end)                                                   as critical_unresolved,

        -- Hora promedio de respuesta (usando las columnas de tiempo de staging)
        avg(first_response_time_hours)                            as avg_response_hour,
        avg(resolution_time_hours)                                as avg_resolution_hour,

        -- Health score: 0 (peor) a 100 (mejor)
        round(
            (
                (100.0 * sum(case when status='closed' then 1 else 0 end) / count(*)) * 0.5
                + coalesce(avg(customer_satisfaction_score), 3) / 5.0 * 100.0 * 0.5
            )
        , 1)                                                       as health_score

    from base
    group by 1,2,3,4,5,6
),

-- Clasificación de riesgo por producto (agrupado)
product_risk as (
    select
        product_purchased,
        avg(pct_resolved)     as avg_pct_resolved,
        avg(avg_satisfaction) as avg_satisfaction,
        sum(critical_unresolved) as total_critical_unresolved,
        sum(total_tickets)    as total_tickets,
        avg(health_score)     as avg_health_score,
        case
            when avg(pct_resolved) < 30 and avg(avg_satisfaction) < 3
                then '🔴 Alto riesgo'
            when avg(pct_resolved) < 45 or avg(avg_satisfaction) < 2.5
                then '🟡 Riesgo medio'
            else '🟢 Estable'
        end                   as risk_level
    from product_stats
    group by 1
)

select
    ps.*,
    pr.avg_health_score       as product_avg_health,
    pr.risk_level
from product_stats ps
left join product_risk pr using (product_purchased)
order by critical_unresolved desc, total_tickets desc