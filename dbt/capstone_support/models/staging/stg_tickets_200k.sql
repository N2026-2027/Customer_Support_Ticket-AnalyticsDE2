SELECT 
    ticket_id,
    customer_name,
    category,
    priority,
    status,
    resolution_time_hours,
    '200k' as dataset_source
FROM {{ source('raw', 'tickets_200k_raw') }}
