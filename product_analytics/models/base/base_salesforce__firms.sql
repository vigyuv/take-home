with source AS (
	
	select
		*
	from {{ source('salesforce', 'firms__c') }}

)

, staging AS (

	select
		--ids
		id__c as firm_id
		
		--strings
		, account_name__c as firm_name
		, practice_area__c as practice_area
		, client_base__c as client_base
		, client_service_region__c as client_service_region
		, client_service_sub_region__c as client_service_sub_region
		, market_segment__c as market_segment
		, country__c as country
		, state__c as state
		, city__c as city
		, zip__c as zip_code
		
		--numerics
		, firm_size__c::number(16, 0) as firm_size
		, arr_in_usd__c::number(16, 2) as arr_in_thousands_usd

		--booleans
		, is_active__c as is_active
		
		--timestamps
		, created_at__c as sys_created_at
		, last_modified_date__c as sys_modified_at
		, {{ required_table_fields() }}
	from source

)

select
	*
from staging
