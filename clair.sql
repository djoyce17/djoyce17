
-- -- --started_onboarding
WITH so AS 
    (
        SELECT user_id
        ,'started_onboarding' AS event_name,
        MIN(event_timestamp) AS timestamp
        FROM events e
        WHERE 1=1
        AND event_name = 'started_onboarding'
        GROUP BY 1
    )
,
--accepted_tos
act AS 
    (
        SELECT user_id
        ,'accepted_tos' AS event_name,
        MIN(event_timestamp) AS timestamp
        FROM events e
        WHERE 1=1
        AND event_name = 'accepted_tos'
        GROUP BY 1
     )
,
--created_account
ca as 
    (
        SELECT user_id
        ,'created_account' AS event_name,
        MIN(event_timestamp) AS timestamp
        FROM events e
        WHERE 1=1
        AND event_name = 'created_account'
        GROUP BY 1
     )
,
--attempted_direct_deposit_update 
addu as 
    (
        SELECT user_id
        ,'attempted_direct_deposit_update' AS event_name,
        MIN(event_timestamp) AS timestamp
        FROM events e
        WHERE 1=1
        AND event_name = 'attempted_direct_deposit_update'
        GROUP BY 1
     )
,
--updated_direct_deposit  
udp as 
    (
        SELECT user_id
        ,'updated_direct_deposit ' AS event_name,
        MIN(event_timestamp) AS timestamp
        FROM events e
        WHERE 1=1
        AND event_name = 'updated_direct_deposit'
        GROUP BY 1
     )
,
--took_first_wage_advance  
tfwa as 
    (
        SELECT user_id
        ,'took_first_wage_advance ' AS event_name,
        MIN(event_timestamp) AS timestamp
        FROM events e
        WHERE 1=1
        AND event_name = 'took_first_wage_advance'
        GROUP BY 1
     )

select

        user_id
        , so.user_id as started_onboarding
        , act.user_id as accepted_tos
        , ca.user_id as created_account
        , addu.user_id as attempted_direct_deposit_update
        , udp.user_id as updated_direct_deposit
        , tfwa.user_id as took_first_wage_advance
from users u
left join so
on u.user_id = so.user_id
left join act
on u.user_id = act.user_id
left join ca
on u.user_id = ca.user_id 
left join addu
on u.user_id = addu.user_id
left join udp
on u.user_id = udp.user_id
left join tfwa
on u.user_id = tfwa.user_id

--time to complkete each step
with 
raw as 
(
    select e.user_id, partner_id, event_name, min(event_timestamp) as event_timestamp
from events e
join (select distinct user_id, partner_id from users) u
on e.user_id = u.user_id
-- where user_id = '123879'
group by 1,2,3
order by 3 asc
)
,
ends as ( 
            select 
                    user_id,
                    partner_id
                    , event_name, date(event_timestamp) as event_timestamp
                    , date(lag(event_timestamp) over (partition by user_id order by event_timestamp asc)) as prev_ts
                from raw
        )

select partner_id, event_name, avg(event_timestamp - prev_ts) as date_diff
from ends
where event_name = 'attempted_direct_deposit_update'
group by 1,2
