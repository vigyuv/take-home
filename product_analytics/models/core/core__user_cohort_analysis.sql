with users AS (

	select
		*
		, date_trunc('month', activation_date) as cohort_month
	from {{ ref('base_nucleus__users') }}
	where is_active = true
		and is_verified = true
		and is_admin = false
		and activation_date is not null

)

, events as (

	select
		* 
	from {{ ref ('base_nucleus__events') }}

)

, daily_activity as (

	select
		date_trunc('month', activity_date) as activity_month
		, user_id
		, count(session_id) as total_queries
	from events
	group by
		activity_month
		, user_id

)

, consolidated as (

	select
		users.cohort_month
		, daily_activity.activity_month
		, users.firm_id
		, datediff('month', users.cohort_month, daily_activity.activity_month) as months_since_acquisition
		, count(distinct 
			case
				when daily_activity.user_id is not null then users.user_id
			end
		) as retained_users
		, count(distinct
			case
				when date_trunc('month', users.activation_date) = users.cohort_month then users.user_id 
			end
		) as users_in_cohort
		, nvl(sum(daily_activity.total_queries), 0) as total_queries
	from users 
		left join daily_activity 
			on users.cohort_month <= daily_activity.activity_month
			and users.user_id = daily_activity.user_id
	group by
		users.cohort_month
		, daily_activity.activity_month
		, users.firm_id

)

, final AS (

	select
		*
		, retained_users / nullif(users_in_cohort, 0) as retention_rate
		, {{ required_table_fields() }}
	from consolidated


)

select
	*
from final
