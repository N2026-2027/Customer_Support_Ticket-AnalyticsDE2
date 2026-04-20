
  
    
    

    create  table
      "support_200k"."main_marts"."mart_ticket_funnel__dbt_tmp"
  
    as (
      

-- ============================================================
-- mart_ticket_funnel
-- Pregunta central: ¿Cómo fluyen los tickets por el pipeline de soporte?
-- ============================================================

with base as (
    select * from "support_200k"."main_staging"."stg_tickets"
),

-- Funnel por dimensiones cruzadas
funnel as (
    select
        ticket_channel,
        category                                                    as ticket_type,
        priority                                                    as ticket_priority,
        ticket_subject,

        count(*)                                                    as total_tickets,

        -- Estado actual (Ajustado a los nombres de staging)
        sum(case when status = 'open'    then 1 else 0 end)         as count_open,
        sum(case when status = 'pending customer response'
                               then 1 else 0 end)                   as count_pending,
        sum(case when status = 'closed'  then 1 else 0 end)         as count_closed,

        -- Conversión
        round(100.0 * sum(case when status='closed' then 1 else 0 end)
              / count(*), 1)                                        as pct_closed,

        round(100.0 * sum(case when status='open' then 1 else 0 end)
              / count(*), 1)                                        as pct_stuck_open,

        -- Tickets que tuvieron primera respuesta (salieron de Open)
        sum(case when not is_open_no_response then 1 else 0 end)    as got_first_response,

        round(100.0 * sum(case when not is_open_no_response then 1 else 0 end)
              / count(*), 1)                                        as pct_got_response,

        -- Satisfacción de los que sí cerraron
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
    );
  
  