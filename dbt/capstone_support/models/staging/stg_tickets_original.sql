SELECT 
    ticket_id,
    customer_name,
    category,
    priority,
    status,
    resolution_time_hours,
    'original' as dataset_source
FROM {{ source('raw', 'tickets_original_raw') }}
