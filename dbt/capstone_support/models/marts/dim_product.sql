{{ config(materialized='table') }}

WITH base AS (
    SELECT DISTINCT
        product,
        -- Usamos el nombre real que viene del staging: ticket_channel
        COALESCE(ticket_channel, 'unknown') as channel_name
    FROM {{ ref('stg_tickets_200k') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['product', 'channel_name']) }} AS product_sk,
    product,
    channel_name as channel
FROM base
