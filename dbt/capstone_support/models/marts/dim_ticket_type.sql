{{ config(materialized='table') }}

WITH base AS (
    SELECT DISTINCT
        -- Usamos los nombres reales que vienen de stg_tickets_200k
        ticket_type as category,
        ticket_priority as priority
    FROM {{ ref('stg_tickets_200k') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['category', 'priority']) }} AS ticket_type_sk,
    category,
    priority
FROM base
