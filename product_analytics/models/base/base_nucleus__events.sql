with source as (
	
	select
		*
	from {{ source('nucleus', 'events') }}

)

, staging as (

	select
		--dates
		to_date(eventts) as activity_date

		--ids
		, sessionid as session_id
		, userid as user_id
		, eventid as event_id
		
		--strings
		, eventname as event_name
		, eventtype as event_type

		--numerics
		, numdocs::number(16,0) as number_of_documents
		, feedbackscore::number(16,0) as feedback_score

		--timestamps
		, eventts as created_at
		, {{ required_table_fields() }}
	from source

)

select
	*
from staging
