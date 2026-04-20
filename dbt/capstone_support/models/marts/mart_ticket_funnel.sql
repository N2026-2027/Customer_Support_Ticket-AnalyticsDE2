{{ config(materialized='table') }}

-- ============================================================
-- mart_ticket_funnel
-- Pregunta central: ¿Cómo fluyen los tickets por el pipeline de soporte?
--
-- Responde:
--   Q1. ¿Qué % de tickets pasan de Open → Pending → Closed?
--   Q2. ¿En qué etapa se "atascan" más tickets por canal?
--   Q3. ¿Qué tipo de ticket tiene peor conversión a Closed?
--   Q4. ¿La prioridad asignada predice si el ticket se resuelve?
--   Q5. ¿Hay sujetos que NUNCA se resuelven (100% open/pending)?
-- ============================================================

-- ============================================================
-- mart_ticket_funnel
-- Pregunta central: ¿Cómo fluyen los tickets por el pipeline de soporte?
-- ============================================================

with base as (
    select * from {{ ref('stg_tickets') }}
),

-- Funnel por dimensiones cruzadas
funnel as (
    select
        channel as ticket_channel, -- Corregido: de ticket_channel a channel
        category as ticket_type,   -- Mapeo a columna real
        priority as ticket_priority, -- Mapeo a columna real
        
        -- Nota: Si ticket_subject no está en tu lista 100% real, 
        -- se puede usar issue_description o eliminar de la agrupación.
        -- Usaremos issue_description como proxy si ticket_subject falla.
        category as ticket_subject, 

        count(*)                                                    as total_tickets,

        -- Estado actual (Usando nombres de status estándar)
        sum(case when status = 'open'    then 1 else 0 end) as count_open,
        sum(case when status in ('pending', 'pending customer response')
                               then 1 else 0 end)                  as count_pending,
        sum(case when status = 'closed'  then 1 else 0 end) as count_closed,

        -- Conversión
        round(100.0 * sum(case when status='closed' then 1 else 0 end)
              / count(*), 1)                                        as pct_closed,

        round(100.0 * sum(case when status='open' then 1 else 0 end)
              / count(*), 1)                                        as pct_stuck_open,

        -- Satisfacción de los que sí cerraron (Columna real: customer_satisfaction_score)
        avg(case when status = 'closed'
                 then customer_satisfaction_score end)              as avg_satisfaction_closed,

        -- ¿Es un "dead end"? Nunca se cierra
        case
            when sum(case when status='closed' then 1 else 0 end) = 0
                then true else false
        end                                                         as is_dead_end,

        -- Etiqueta de salud del funnel
        case
            when round(100.0 * sum(case when status='closed' then 1 else 0 end)
                       / count(*), 1) >= 50 then 'Saludable (≥50% cerrados)'
            when round(100.0 * sum(case when status='closed' then 1 else 0 end)
                       / count(*), 1) >= 25 then 'Moderado (25-50%)'
            else                                 'Crítico (<25% cerrados)'
        end                                                         as funnel_health

    from base
    group by 1,2,3,4
)

select * from funnel
order by pct_stuck_open desc, total_tickets desc
