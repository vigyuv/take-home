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
		, daily_activity.activity_month as reporting_month
		, users.firm_id
		, datediff('month', users.cohort_month, daily_activity.activity_month) as months_since_acquisition
		, count(distinct daily_activity.user_id) as retained_users
		, count(distinct users.user_id) as users_in_cohort
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
		cohort_month
		, reporting_month
		, firm_id
		, months_since_acquisition
		, retained_users
		, users_in_cohort
		, total_queries
		, case
			when users_in_cohort > 0 then retained_users / users_in_cohort
			else 0
		end as retention_rate
		, MD5(cohort_month || reporting_month || firm_id) AS _unique_key
		, {{ required_table_fields() }}
	from consolidated

)

select
	*
from final
