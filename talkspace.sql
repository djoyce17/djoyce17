-- number 1
		SELECT
		provider_id,
		unnest(string_to_array(state_of_licenses, ', ' )) AS state_of_license
	FROM talkspace.providers

-- number 2

select *
from crosstab(
			'with w as
(
	SELECT
		provider_id,
		unnest(string_to_array(state_of_licenses, '', '' )) AS state_of_license
	FROM talkspace.providers 
	order by 1
)
			SELECT  
			w.state_of_license,
			  w1.state_of_license,
			  count(w.provider_id)
				FROM w
				  left join w as w1
				  on w.provider_id = w1.provider_id
				  group by 1,2
			 order by 1'
			, 'values(''CA''), (''DL''), (''FL''), (''NY''), (''TX'')'
			)

	as(state_of_license text, "CA" bigint, "DL" bigint, "FL" bigint, "NY" bigint, "TX" bigint)

-- number 3 - python

-- number 4 
	-- assume that they have equal number of clients per state
with 
	p as 
		(
			SELECT
				provider_id,
				unnest(string_to_array(state_of_licenses, '/ ' )) AS state_of_license
			FROM talkspace.providers 
			order by 1
		)
	,
	m as 
		(
			select 
				id
				, max_client_capacity provider_capcity
				, count(distinct state_of_license) num_states
				, max_client_capacity/count(distinct state_of_license) num_clients_per_state
			from talkspace.max_client m
			left join p
			on m.id = p.provider_id
			group by 1,2
		)
		
select 
	state_of_license
	, sum(num_clients_per_state)
from p
left join m
on m.id = p.provider_id
group by 1

-- number 5

select 
	*
	, current_number_of_clients/current_avg_max_provider_capacity as num_providers
	, projected_number_of_clients/current_avg_max_provider_capacity as num_providers_needed
	, (projected_number_of_clients/current_avg_max_provider_capacity) - current_number_of_clients/current_avg_max_provider_capacity as additional_providers
from talkspace.state_fact sf 

-- number 6. at the end of a year we will have to add about 1 provider in each state
with g as
(
	select 
		* 
		, case
			when state = 'NY' then .01
			when state = 'CA' then .02
			when state = 'FL' then .02
			when state = 'DL' then .03
			when state = 'TX' then .01
				end as growth_rate
	from talkspace.state_fact
)
select 
	state
	, current_number_of_clients
	, current_avg_max_provider_capacity
	, growth_rate
	, ceiling(current_number_of_clients*((1 + growth_rate/12))^12) as projected_number_of_clients
	, ceiling(current_number_of_clients*((1 + growth_rate/12))^12/current_avg_max_provider_capacity - (current_number_of_clients/current_avg_max_provider_capacity)) as additional_providers
from g
