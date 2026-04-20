

-- ============================================================
-- fct_tickets — Tabla de hechos central del Star Schema
-- Granularidad: 1 fila = 1 ticket
--
-- SIMPLIFICADO: solo lee del dataset 200k (el principal).
-- SIN UNION ALL → elimina el error VARCHAR != INTEGER [58.0]
-- que ocurría al intentar combinar schemas distintos.
--
-- El dataset original (18k) queda disponible en stg_tickets
-- para consultas directas desde los marts o Streamlit.
-- ============================================================

with base as (
    select
        cast(ticket_id                   as varchar)  as ticket_id,
        cast(customer_email              as varchar)  as customer_email,
        cast(product                     as varchar)  as product,
        cast(channel                     as varchar)  as channel,
        cast(category                    as varchar)  as category,
        cast(priority                    as varchar)  as priority,
        cast(status                      as varchar)  as status,
        cast(ticket_created_date         as date)     as ticket_created_date,
        cast(ticket_resolved_date        as date)     as ticket_resolved_date,
        cast(first_response_time_hours   as double)   as first_response_time_hours,
        cast(resolution_time_hours       as double)   as resolution_time_hours,
        cast(customer_satisfaction_score as double)   as customer_satisfaction_score,
        cast(issue_complexity_score      as integer)  as issue_complexity_score,
        cast(escalated                   as boolean)  as escalated,
        cast(sla_breached                as boolean)  as sla_breached,
        cast(previous_tickets            as integer)  as previous_tickets,
        cast(dataset_source              as varchar)  as dataset_source
    from "support_200k"."main_staging"."stg_tickets_200k"
),

enriched as (
    select
        b.*,
        c.customer_sk,
        p.product_sk,
        tt.ticket_type_sk,
        b.ticket_created_date as date_id
    from base b
    left join "support_200k"."main_marts"."dim_customer"    c  on b.customer_email = c.customer_email
    left join "support_200k"."main_marts"."dim_product"     p  on b.product        = p.product
                                             and coalesce(b.channel, 'unknown') = p.channel
    left join "support_200k"."main_marts"."dim_ticket_type" tt on b.category       = tt.category
                                             and b.priority        = tt.priority
)

select
    md5(cast(coalesce(cast(ticket_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dataset_source as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as ticket_sk,

    -- FKs a dimensiones
    ticket_id,
    customer_sk,
    product_sk,
    ticket_type_sk,
    date_id,
    dataset_source,

    -- Atributos
    status,
    ticket_created_date,
    ticket_resolved_date,

    -- Métricas
    first_response_time_hours,
    resolution_time_hours,
    customer_satisfaction_score,
    issue_complexity_score,
    previous_tickets,

    -- Flags
    escalated,
    sla_breached,

    -- Calculados
    case
        when sla_breached = false then 'SLA_Cumplido'
        when sla_breached = true  then 'SLA_Incumplido'
        else 'SLA_Cumplido'
    end as sla_status,

    case
        when status in ('closed', 'resolved') then true
        else false
    end as is_resolved,

    case
        when customer_satisfaction_score >= 4 then 'satisfied'
        when customer_satisfaction_score >= 3 then 'neutral'
        when customer_satisfaction_score is not null then 'unsatisfied'
        else 'unknown'
    end as satisfaction_band

from enriched