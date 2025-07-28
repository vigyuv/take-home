with source AS (
	
	select
		*
	from {{ source('nucleus', 'users') }}

)

, staging AS (

	select
		--dates
		to_date(activatedAt) as activation_date

		--ids
		, id as user_id
		, firmID as firm_id
		
		--strings
		, firstName as first_name
		, lastName as last_name
		, email as email_address
		, roleTitle as title
		
		--booleans
		, isActive as is_active
		, isVerified as is_verified
		, isAdmin as is_admin

		--timestamps
		, activatedAt as user_activated_at
		, lastLoginAt as last_login_at
		, createdAt as sys_created_at
		, modifiedAt as sys_modified_at
		, {{ required_table_fields() }}
    from source

)

select
	*
from staging
