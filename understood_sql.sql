--1 accessed users by device
select 
    device_class
    , count(distinct understood_id) as users_accessed
from pageview_data
group by 1

--2 What is the average session duration by traffic source (channel_category field)
--for users in the United States (location_country field = US)?
with c as 
(
    select 
        distinct understood_id
        , location_country
    from pageview_data
    where 1=1
    and location_country = 'US'
)
select 
    channel_category
    ,avg(engagement_second) as avg_sess_duration
from session_data s
join c
on c.understood_id = s.understood_id
where 1=1
group by 1

--3 What are the top 5 most visited articles (page_path_slug field and
-- site_section fields) on the site based on total pageviews for users who
-- did not bounce in their session (engagement_is_bounce_session field)?

with s as (
    select page_path_slug,
    count(*) as num
    from pageview_data p
    join session_data s
    on p.session_id = s.session_id
    where 1=1
    and site_section = 'articles'
    and not engagement_is_bounce_session
    group by 1

)

select * 
from
    (
        select 
            s.*
            , row_number() OVER ( order by num desc) as rank 
        from s 
    ) r
where rank <=5

--4 What is the number of return sessions (is_user_initial_session field) and the
-- average scroll depth (engagement_y_percentage _scrolled field) for sessions
-- which had a pageview on the top 5 most popular articles (page_path_slug and
-- site_section fields)?

with 
    s as 
        (
            select 
                page_path_slug
                , count(*) as num
            from pageview_data p
            join session_data s
            on p.session_id = s.session_id
            where 1=1
            and site_section = 'articles'
            and not engagement_is_bounce_session
            group by 1
        ) 
,
    r as 
        (
            select * 
            from
                (
                    select 
                        s.*
                        , row_number() OVER (order by num desc) as rank 
                    from s 
                ) r
            where rank <=5
        )

select 

     sum(case when not is_user_initial_session then 1 else 0 end) as num_return_sessions
    , avg(engagement_y_percentage_scrolled) as avg_scroll_depth
from pageview_data p
join session_data s
on p.session_id = s.session_id
join r
on p.page_path_slug = r.page_path_slug
