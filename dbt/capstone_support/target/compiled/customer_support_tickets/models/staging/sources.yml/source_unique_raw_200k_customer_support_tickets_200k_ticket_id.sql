
    
    

select
    ticket_id as unique_field,
    count(*) as n_records

from "support_200k"."main"."customer_support_tickets_200k"
where ticket_id is not null
group by ticket_id
having count(*) > 1


