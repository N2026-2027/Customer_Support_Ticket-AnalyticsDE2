
  
    
    

    create  table
      "support_200k"."main_marts"."fct_tickets__dbt_tmp"
  
    as (
      

-- ============================================================
-- fact_tickets — Tabla de hechos central (Solo dataset 200k)
-- ============================================================

WITH base AS (
    SELECT
        cast(ticket_id                   as varchar)  as ticket_id,
        cast(customer_email              as varchar)  as customer_email,
        cast(product                     as varchar)  as product,
        cast(ticket_channel              as varchar)  as channel,
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
        cast('200k'                      as varchar)  as dataset_source
    FROM "support_200k"."main_staging"."stg_tickets_200k"
),

enriched AS (
    SELECT
        b.*,
        c.customer_sk,
        p.product_sk,
        tt.ticket_type_sk,
        b.ticket_created_date AS date_id
    FROM base b
    LEFT JOIN "support_200k"."main_marts"."dim_customer"    c  ON b.customer_email = c.customer_email
    LEFT JOIN "support_200k"."main_marts"."dim_product"     p  ON b.product        = p.product
                                             AND COALESCE(b.channel, 'unknown') = p.channel
    LEFT JOIN "support_200k"."main_marts"."dim_ticket_type" tt ON b.category       = tt.category
                                             AND b.priority        = tt.priority
)

SELECT
    md5(cast(coalesce(cast(ticket_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dataset_source as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS ticket_sk,

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
    CASE
        WHEN sla_breached = FALSE THEN 'SLA_Cumplido'
        WHEN sla_breached = TRUE  THEN 'SLA_Incumplido'
        ELSE 'SLA_Cumplido'
    END AS sla_status,

    CASE
        WHEN status IN ('closed', 'resolved') THEN TRUE
        ELSE FALSE
    END AS is_resolved,

    CASE
        WHEN customer_satisfaction_score >= 4 THEN 'satisfied'
        WHEN customer_satisfaction_score >= 3 THEN 'neutral'
        WHEN customer_satisfaction_score IS NOT NULL THEN 'unsatisfied'
        ELSE 'unknown'
    END AS satisfaction_band

FROM enriched
    );
  
  