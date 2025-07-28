with source AS (
	
	select
		*
	from {{ source('nucleus', 'events') }}

)

, staging AS (

	select
		--dates
        to_date(eventTs) as activity_date

        --ids
        , sessionId as session_id
		, userId as user_id
        , eventId as event_id
		
		--strings
		, eventName as event_name
        , eventType as event_type

		--numerics
		, numDocs::number(16,0) as number_of_documents
		, feedbackScore::number(16,0) as feedback_score

		--timestamps
		, eventTs as created_at
		, {{ required_table_fields() }}
    from source

)

select
	*
from staging