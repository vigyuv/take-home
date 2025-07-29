with source as (
	
	select
		*
	from {{ source('nucleus', 'users') }}

)

, staging as (

	select
		--dates
		to_date(activatedat) as activation_date

		--ids
		, id as user_id
		, firmid as firm_id
		
		--strings
		, firstname as first_name
		, lastname as last_name
		, email as email_address
		, roletitle as title
		
		--booleans
		, isactive as is_active
		, isverified as is_verified
		, isadmin as is_admin

		--timestamps
		, activatedat as user_activated_at
		, lastloginat as last_login_at
		, createdat as sys_created_at
		, modifiedat as sys_modified_at
		, {{ required_table_fields() }}
	from source

)

select
	*
from staging
