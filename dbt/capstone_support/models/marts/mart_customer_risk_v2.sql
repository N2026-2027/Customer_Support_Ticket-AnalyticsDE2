{{ config(
    materialized='table',
    schema='marts'
) }}

/*
  mart_customer_risk_v2.sql
  ─────────────────────────
  Segmentación de riesgo por cliente basada en:
    · Tasa de SLA breach        (peso 40 %)
    · Tasa de escalamiento      (peso 30 %)
    · CSAT promedio invertido   (peso 30 %)

  Fuente: support_200k.duckdb → main.customer_support_tickets_200k
  Referencia staging: stg_tickets_200k_v2
*/

with customer_metrics as (
    select
        customer_email,
        customer_name,
        customer_segment,
        subscription_type,
        region,

        count(*)                                                        as total_tickets,

        -- SLA breach rate (0 → 1)
        round(
            1.0 * sum(case when lower(trim(sla_breached)) = 'yes' then 1 else 0 end)
            / nullif(count(*), 0), 4
        )                                                               as sla_breach_rate,

        -- Escalation rate (0 → 1)
        round(
            1.0 * sum(case when lower(trim(escalated)) = 'yes' then 1 else 0 end)
            / nullif(count(*), 0), 4
        )                                                               as escalation_rate,

        -- CSAT promedio (1–5; lo invertimos para que 1=peor → mayor riesgo)
        round(avg(customer_satisfaction_score::double), 4)              as avg_csat,

        round(avg(resolution_time_hours), 2)                           as avg_resolution_hours,
        max(ticket_created_date)                                        as last_ticket_date,
        count(case when lower(trim(status)) in ('open','in progress') then 1 end)
                                                                        as open_tickets

    from {{ source('raw_200k', 'customer_support_tickets_200k') }}
    where customer_email is not null
    group by 1, 2, 3, 4, 5
    having count(*) >= 1
),

scored as (
    select
        *,

        -- Score de riesgo 0–100
        -- SLA breach (40 pts) + escalation (30 pts) + CSAT invertido (30 pts)
        round(
            (sla_breach_rate * 40)
            + (escalation_rate * 30)
            + ((1 - (avg_csat - 1) / 4.0) * 30),   -- normaliza 1–5 → 0–1, invertido
        2)                                                              as risk_score

    from customer_metrics
),

classified as (
    select
        *,
        case
            when risk_score >= 75 then 'Critical'
            when risk_score >= 55 then 'High'
            when risk_score >= 35 then 'Medium'
            else                       'Low'
        end                                                             as risk_tier,

        -- Ranking dentro de su segmento
        rank() over (
            partition by customer_segment
            order by risk_score desc
        )                                                               as risk_rank_in_segment

    from scored
)

select
    {{ dbt_utils.generate_surrogate_key(['customer_email']) }}          as customer_sk,
    customer_email,
    customer_name,
    customer_segment,
    subscription_type,
    region,
    total_tickets,
    open_tickets,
    sla_breach_rate,
    escalation_rate,
    avg_csat,
    avg_resolution_hours,
    last_ticket_date,
    risk_score,
    risk_tier,
    risk_rank_in_segment
from classified
order by risk_score desc
