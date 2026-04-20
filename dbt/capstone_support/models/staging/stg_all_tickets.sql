{{ config(materialized='view') }}

WITH raw_200k AS (
    SELECT 
        ticket_id::VARCHAR as id, 
        customer_email::VARCHAR as email, 
        '200k' as src 
    -- CAMBIO: Usar ref() al modelo de staging que YA arreglamos, no a la tabla cruda
    FROM {{ ref('stg_tickets_200k') }} 
),
raw_small AS (
    SELECT 
        ticket_id::VARCHAR as id, 
        customer_email::VARCHAR as email, 
        'small' as src 
    -- CAMBIO: Usar ref() al modelo de staging original
    FROM {{ ref('stg_tickets_original') }}
)

SELECT * FROM raw_200k
UNION ALL
SELECT * FROM raw_small
