
  
    
    

    create  table
      "support_200k"."main"."mart_product_health__dbt_tmp"
  
    as (
      

-- ============================================================
-- mart_product_health
-- Pregunta central: ¿Qué productos generan más dolor al cliente?
-- ============================================================

with base as (
    select * from "support_200k"."main"."stg_tickets"
),

product_stats as (
    select
        product, -- Corregido: product_purchased -> product
        category as ticket_type, -- Mapeo a columna real
        priority as ticket_priority, -- Mapeo a columna real
        status as ticket_status, -- Mapeo a columna real
        channel as ticket_channel, -- Mapeo a columna real

        count(*)                                                   as total_tickets,
        avg(customer_satisfaction_score)                           as avg_satisfaction,

        -- Tasa de resolución (solo cerrados)
        round(
            100.0 * sum(case when status = 'closed' then 1 else 0 end)
            / count(*)
        , 1)                                                       as pct_resolved,

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

        -- Tiempos promedio
        avg(first_response_time_hours)                             as avg_first_response_hrs,
        avg(resolution_time_hours)                                 as avg_resolution_hrs,

        -- Health score: 0 (peor) a 100 (mejor)
        round(
            (
                (100.0 * sum(case when status='closed' then 1 else 0 end) / count(*)) * 0.5
                + coalesce(avg(customer_satisfaction_score), 3) / 5.0 * 100.0 * 0.5
            )
        , 1)                                                       as health_score

    from base
    group by 1,2,3,4,5
),

-- Clasificación de riesgo por producto (agrupado)
product_risk as (
    select
        product,
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
left join product_risk pr using (product)
order by critical_unresolved desc, total_tickets desc
    );
  
  