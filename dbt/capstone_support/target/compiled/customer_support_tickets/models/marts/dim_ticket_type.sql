

WITH base AS (
    SELECT DISTINCT
        -- Usamos los nombres reales que vienen de stg_tickets_200k
        ticket_type as category,
        ticket_priority as priority
    FROM "support_200k"."main"."stg_tickets_200k"
)

SELECT
    md5(cast(coalesce(cast(category as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(priority as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS ticket_type_sk,
    category,
    priority
FROM base