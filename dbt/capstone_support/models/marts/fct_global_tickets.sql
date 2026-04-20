{{ config(materialized='table') }}

-- ============================================================
-- fct_global_tickets — Vista desnormalizada para Streamlit
-- Une fact_tickets con todas las dimensiones.
-- Schema de salida: main_marts (configurado en dbt_project.yml)
-- Las páginas Streamlit consultan: main_marts.fct_global_tickets
-- ============================================================

SELECT
    -- ── FACT ────────────────────────────────────────────────
    f.ticket_sk,
    f.ticket_id,
    f.dataset_source,
    f.status,
    f.sla_status,
    f.sla_breached,
    f.escalated,
    f.is_resolved,
    f.satisfaction_band,
    f.first_response_time_hours,
    f.resolution_time_hours,
    f.customer_satisfaction_score,
    f.issue_complexity_score,
    f.previous_tickets,
    f.ticket_resolved_date,
    f.ticket_created_date,

    -- ── DIM DATE ────────────────────────────────────────────
    d.year,
    d.month,
    d.quarter,
    d.month_name,
    d.day_name,
    d.is_weekend,

    -- ── DIM CUSTOMER ────────────────────────────────────────
    c.customer_email,
    c.customer_name,
    c.customer_age,
    c.age_cohort,
    c.customer_gender,
    c.subscription_type,
    c.customer_tenure_months,
    c.tenure_band,
    c.customer_segment,
    c.region,
    c.preferred_contact_time,
    c.payment_method,
    c.language,

    -- ── DIM PRODUCT ─────────────────────────────────────────
    p.product,
    p.channel,
    p.operating_system,
    p.browser,
    p.channel_type,

    -- ── DIM TICKET TYPE ─────────────────────────────────────
    tt.category,
    tt.priority,
    tt.priority_rank

FROM {{ ref('fct_tickets') }}          f
LEFT JOIN {{ ref('dim_date') }}         d  ON f.date_id        = d.date_id
LEFT JOIN {{ ref('dim_customer') }}     c  ON f.customer_sk    = c.customer_sk
LEFT JOIN {{ ref('dim_product') }}      p  ON f.product_sk     = p.product_sk
LEFT JOIN {{ ref('dim_ticket_type') }}  tt ON f.ticket_type_sk = tt.ticket_type_sk