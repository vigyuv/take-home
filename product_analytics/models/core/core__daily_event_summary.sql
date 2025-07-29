with dates as (

	select
		*
	from {{ ref('core__calendar') }}
	where calendar_date <= current_date

)

, events as (

	select
		* 
	from {{ ref ('base_nucleus__events') }}

)

, distinct_events as (

	select
		event_id
		, event_type
		, event_name
		, min(activity_date) as first_occurrence
	from events
	group by event_id
		, event_type
		, event_name

)

, daily_activity as (

	select
		activity_date
		, event_type
		, event_id
		, event_name
		, count(distinct user_id) as unique_users
		, count(user_id) as total_users
		, count(session_id) as total_queries
		, sum(number_of_documents) as total_documents_uploaded
		, avg(feedback_score) as average_feedback_score
		, MD5(event_id || activity_date) AS _unique_key
	from events
	group by activity_date
		, event_type
		, event_id
		, event_name

)

, final as (

	select
		dates.calendar_date as activity_date
		, distinct_events.event_type
		, distinct_events.event_id
		, distinct_events.event_name
		, nvl(daily_activity.unique_users, 0) as unique_users
		, nvl(daily_activity.total_users, 0) as total_users
		, nvl(daily_activity.total_queries, 0) as total_queries
		, nvl(daily_activity.total_documents_uploaded, 0) as total_documents_uploaded
		, nvl(daily_activity.average_feedback_score, 0.0) as average_feedback_score
		, distinct_events.first_occurrence as event_launch_date
		, daily_activity._unique_key
		, {{ required_table_fields() }}
	from dates
		left join distinct_events 
			on dates.calendar_date >= distinct_events.first_occurrence
		left join daily_activity 
			on dates.calendar_date = daily_activity.activity_date

)

select
	*
from final
