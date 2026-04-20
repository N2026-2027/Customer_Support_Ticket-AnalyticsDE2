

with base as (
    select * from "support_200k"."main"."stg_tickets"
),

channel_metrics as (
    select
        -- Cambiado de ticket_channel a channel
        channel,
        -- Cambiado de ticket_status a status
        status,
        count(ticket_id) as total_tickets,
        avg(customer_satisfaction_score) as avg_satisfaction
    from base
    group by 1, 2
)

select * from channel_metrics