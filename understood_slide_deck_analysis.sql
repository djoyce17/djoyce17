-- --number of users
-- select count(distinct understood_id)
-- from pageview_data
-- --10000

-- --numbner of users by device
-- with r as(
-- select 
--     device_class
--     , count(distinct understood_id) as users_accessed
-- from pageview_data
-- group by 1)

-- --number of users who use more than 1 device to access the article
-- select understood_id, 
-- count(distinct device_class) as counted
-- from pageview_data 
-- group by 1 
-- having count(distinct device_class) > 1
-- order by 2 desc

-- -- what are the top 5 articles in the time period?
-- with s as (
--     select page_path_slug,
--     count(*) as num
--     from pageview_data p
--     where 1=1
--     and site_section = 'articles'
--     group by 1

-- )

-- select * 
-- from
--     (
--         select 
--             s.*
--             , row_number() OVER ( order by num desc) as rank 
--         from s 
--     ) r
-- where rank <=5

-- -- what about over time. may not use this
-- with s as (
--     select page_path_slug,
--     date_part('month',pageview_date_est) as tmonth,
--     count(*) as num
--     from pageview_data p
--     where 1=1
--     and site_section = 'articles'
--     group by 1,2

-- )

-- select * 
-- from
--     (
--         select 
--             s.*
--             , row_number() OVER (partition by tmonth order by num desc) as rank 
--         from s 
--     ) r
-- where rank <=5

