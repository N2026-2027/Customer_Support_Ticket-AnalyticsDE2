{{ config(materialized='table') }}

-- ============================================================
-- mart_channel_efficiency (Basado en fct_tickets)
-- ============================================================

with base as (
    select * from {{ ref('fct_tickets') }}
),

-- Global benchmarks para comparar
global_bench as (
    select
        count(*)                                                as g_total,
        avg(customer_satisfaction_score)                        as g_avg_sat,
        round(100.0 * sum(case when is_resolved = TRUE then 1 else 0 end)
              / count(*), 1)                                   as g_pct_closed
    from base
),

channel_metrics as (
    select
        b.channel as ticket_channel,
        -- Traemos info de la categoría (puedes unir con dim_ticket_type si prefieres nombres)
        b.status as ticket_status,
        b.priority as ticket_priority,

        count(*)                                                as total_tickets,

        -- Volumen relativo
        round(100.0 * count(*) / max(g.g_total), 1)            as pct_of_all_tickets,

        -- Resolución
        sum(case when b.is_resolved = TRUE then 1 else 0 end)  as resolved_count,
        round(100.0 * sum(case when b.is_resolved = TRUE then 1 else 0 end)
              / count(*), 1)                                   as pct_resolved,

        -- Satisfacción
        avg(b.customer_satisfaction_score)                     as avg_satisfaction,

        -- Críticos sin resolver
        sum(case when b.priority='critical'
                  and b.is_resolved = FALSE then 1 else 0 end) as critical_open,

        -- Comparación vs benchmark global
        round(
            (100.0 * sum(case when b.is_resolved = TRUE then 1 else 0 end) / count(*))
            - max(g.g_pct_closed)
        , 1)                                                   as resolution_vs_global,

        round(
            coalesce(avg(b.customer_satisfaction_score), 3) - max(g.g_avg_sat)
        , 2)                                                   as satisfaction_vs_global,

        -- Eficiencia compuesta
        case
            when round(100.0 * sum(case when b.is_resolved = TRUE then 1 else 0 end)
                       / count(*), 1) > max(g.g_pct_closed)
             and coalesce(avg(b.customer_satisfaction_score),3) > max(g.g_avg_sat)
                then '⭐ Mejor que promedio'
            when round(100.0 * sum(case when b.is_resolved = TRUE then 1 else 0 end)
                       / count(*), 1) < max(g.g_pct_closed)
             and coalesce(avg(b.customer_satisfaction_score),3) < max(g.g_avg_sat)
                then '⚠️ Peor que promedio'
            else '➡️ Promedio'
        end                                                    as channel_rating

    from base b
    cross join global_bench g
    group by 1,2,3
)

select * from channel_metrics
order by ticket_channel, pct_resolved asc
