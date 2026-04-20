

-- ============================================================
-- mart_repeat_customers
-- Pregunta central: ¿Hay clientes que abren múltiples tickets?
-- ============================================================

with base as (
    select * from "support_200k"."main"."stg_tickets"
),

-- Número de tickets por cliente (Agrupado por Email)
customer_ticket_counts as (
    select
        customer_email, -- Identificador único definitivo
        customer_name,
        customer_gender,
        customer_age,
        count(*)                                                    as ticket_count,
        count(distinct product)                                     as products_with_issues,
        count(distinct category)                                    as issue_type_variety,

        -- Satisfacción promedio del cliente
        avg(customer_satisfaction_score)                            as avg_satisfaction,
        min(customer_satisfaction_score)                            as min_satisfaction,

        -- ¿Tiene tickets sin resolver? (Basado en status real)
        sum(case when status != 'closed' then 1 else 0 end)         as unresolved_count,

        -- ¿Alguna vez fue Critical?
        max(case when priority = 'critical' then 1 else 0 end)      as had_critical,

        -- Canal y Producto más frecuentes
        mode() within group (order by channel)                      as preferred_channel,
        mode() within group (order by product)                      as most_complained_product,

        -- Rango de fechas de actividad (Usando ticket_created_date)
        min(ticket_created_date)                                    as first_ticket,
        max(ticket_created_date)                                    as last_ticket

    from base
    group by 1,2,3,4
),

-- Segmentación de riesgo de churn
segmented as (
    select
        *,
        case
            when ticket_count >= 3 then 'Recurrente frecuente (3+)'
            when ticket_count = 2  then 'Recurrente (2 tickets)'
            else                        'Primera vez'
        end                                                         as recurrence_segment,

        case
            when ticket_count >= 2
             and (min_satisfaction <= 2 or unresolved_count >= 1
                  or had_critical = 1)
                then '🔴 Churn inminente'
            when ticket_count >= 2
             and avg_satisfaction < 3
                then '🟡 Riesgo de churn'
            when ticket_count >= 2
                then '🟠 Recurrente estable'
            else    '🟢 Sin señales'
        end                                                         as churn_risk
    from customer_ticket_counts
)

select
    customer_email,
    customer_name,
    customer_gender,
    customer_age,
    ticket_count,
    products_with_issues,
    issue_type_variety,
    round(avg_satisfaction, 2)  as avg_satisfaction,
    min_satisfaction,
    unresolved_count,
    had_critical,
    preferred_channel,
    most_complained_product,
    first_ticket,
    last_ticket,
    recurrence_segment,
    churn_risk
from segmented
order by ticket_count desc, avg_satisfaction asc