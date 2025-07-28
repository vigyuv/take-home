with dates as (

	select
		distinct year_month as activity_month
		, month_start
		, month_end
	from {{ ref('core__calendar') }}
	where calendar_date <= current_date

)

, users AS (

	select
		*
		, to_varchar(activation_date, 'yyyy-MM') as activation_month
	from {{ ref('base_nucleus__users') }}
	where is_active = true
		and is_verified = true
		and is_admin = false

)

, events as (

	select
		* 
	from {{ ref ('base_nucleus__events') }}

)

, monthly_activity as (

	select
		to_varchar(activity_date, 'yyyy-MM') as activity_month
		, user_id
		, count(session_id) as total_queries
		, max(activity_date) as last_active_date
		, count(distinct event_type) AS unique_query_types
		, sum(number_of_documents) as total_documents_uploaded
		, avg(feedback_score) as average_feedback_score
	from events
	group by 
		to_varchar(activity_date, 'yyyy-MM')
		, user_id

)

, consolidated as (

	select
		dates.activity_month
		, users.user_id
		, users.firm_id
		, nvl(monthly_activity.total_queries, 0) as total_queries
		, nvl(monthly_activity.last_active_date, TO_DATE('9999-12-31')) as last_active_date
		, nvl(monthly_activity.unique_query_types, 0) as unique_query_types
		, nvl(monthly_activity.total_documents_uploaded, 0) as total_documents_uploaded
		, nvl(monthly_activity.average_feedback_score, 0.0) as average_feedback_score
		, case
			when nvl(monthly_activity.last_active_date, TO_DATE('9999-12-31')) = TO_DATE('9999-12-31')
				then 999
			when dates.activity_month = to_varchar(current_date, 'yyyy-MM')
				then datediff('day', monthly_activity.last_active_date, current_date)
			else
				datediff('day', monthly_activity.last_active_date, dates.month_end)
		  end as days_since_last_active
	from dates
	left join users
		on dates.activity_month >= users.activation_month
	left join monthly_activity
		on dates.activity_month = monthly_activity.activity_month
		and users.user_id = monthly_activity.user_id

)

, final as (

	select
		activity_month
		, user_id
		, firm_id
		, total_queries
		, last_active_date
		, unique_query_types
		, total_documents_uploaded
		, average_feedback_score
		, days_since_last_active
		, case
			when total_queries >= 100 
				and days_since_last_active <= 5
				and unique_query_types = 3 
			then 'High'
			when total_queries between 50 and 99
				and days_since_last_active between 6 and 15
				and unique_query_types >= 2 
			then 'Medium'
			when total_queries <= 49 
				and days_since_last_active > 15
				and unique_query_types >= 1
			then 'Low'
			when total_queries = 0 then 'Zero'
			else 'NA'
		end as engagement_level
		, {{ required_table_fields() }}
	from consolidated

)

select
	*
from final
