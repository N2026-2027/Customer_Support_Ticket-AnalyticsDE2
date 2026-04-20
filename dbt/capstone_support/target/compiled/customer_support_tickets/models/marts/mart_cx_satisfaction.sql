

with base as (
    select
        product,
        customer_gender,
        ticket_channel,
        -- Forzamos a double para que el promedio no falle por tipos mezclados
        cast(satisfaction_rating as double) as satisfaction_rating
    from "support_200k"."main_staging"."stg_tickets_200k"
    where satisfaction_rating is not null
)

select
    product,
    customer_gender,
    ticket_channel,
    round(avg(satisfaction_rating), 2) as avg_rating,
    count(*) as total_tickets
from base
group by 1, 2, 3