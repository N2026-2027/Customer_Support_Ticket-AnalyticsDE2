

WITH raw_200k AS (
    SELECT 
        "Ticket ID"::VARCHAR as id,  -- Added double colon and explicit 'as'
        customer_email::VARCHAR as email, 
        '200k' as src 
    FROM "support_200k"."main_main"."customer_support_tickets_200k"
),
raw_small AS (
    SELECT 
        "Ticket ID"::VARCHAR as id, 
        "Customer Email"::VARCHAR as email, 
        'small' as src 
    FROM "support_200k"."main_main"."customer_support_tickets"
)

SELECT * FROM raw_200k
UNION ALL
SELECT * FROM raw_small