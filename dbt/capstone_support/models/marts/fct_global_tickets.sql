{{ config(materialized='table') }}

SELECT * FROM {{ ref('stg_tickets_200k') }}
UNION ALL
SELECT * FROM {{ ref('stg_tickets_original') }}
