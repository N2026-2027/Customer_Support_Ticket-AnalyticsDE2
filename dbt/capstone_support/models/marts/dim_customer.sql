-- models/marts/dim_customer.sql
-- Dimensión de clientes (SCD Type 1 — última fila gana)

{{ config(materialized='table') }}

WITH ranked AS (
    SELECT
        customer_email,
        customer_name,
        customer_age,
        customer_gender,
        subscription_type,
        customer_tenure_months,
        customer_segment,
        region,
        preferred_contact_time,
        payment_method,
        language,
        dataset_source,
        ROW_NUMBER() OVER (
            PARTITION BY customer_email
            ORDER BY customer_tenure_months DESC NULLS LAST
        ) AS rn
    FROM {{ ref('stg_tickets_200k') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['customer_email']) }}   AS customer_sk,  -- PK surrogate
    customer_email,                                                                -- NK
    customer_name,
    customer_age,
    CASE
        WHEN customer_age < 25 THEN 'Gen Z'
        WHEN customer_age < 40 THEN 'Millennial'
        WHEN customer_age < 55 THEN 'Gen X'
        ELSE 'Boomer+'
    END                                                          AS age_cohort,
    customer_gender,
    COALESCE(subscription_type, 'unknown')                       AS subscription_type,
    customer_tenure_months,
    CASE
        WHEN customer_tenure_months < 6  THEN 'new'
        WHEN customer_tenure_months < 24 THEN 'established'
        ELSE 'loyal'
    END                                                          AS tenure_band,
    COALESCE(customer_segment, 'unknown')                        AS customer_segment,
    COALESCE(region, 'unknown')                                  AS region,
    COALESCE(preferred_contact_time, 'unknown')                  AS preferred_contact_time,
    COALESCE(payment_method, 'unknown')                          AS payment_method,
    COALESCE(language, 'unknown')                                AS language,
    dataset_source
FROM ranked
WHERE rn = 1
