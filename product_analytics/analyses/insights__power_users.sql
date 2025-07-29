with dates as (

	select
		distinct year_month as activity_month
		, month_start
		, month_end
	from {{ ref('core__calendar') }}
	where calendar_date <= current_date

)

engagement as (

	select
		*
	from {{ ref('core__monthly_user_engagement') }}

)

, firms as (

	select
		*
	from {{ ref('base_salesforce__firms') }}
	where is_active = true

)

, user_classification as (

	select
		*
		, case
			when
				total_queries >= 100 and unique_query_types = 3
				and feedbacks_submitted > 20 and days_since_last_active <= 5
				then user_id
			else null
			end as verified_power_user
	from engagement

)

, aggregated_usage as (

	select
		activity_month
		, firm_id
		, count(distinct user_id) as unique_users
		, count(distinct verified_power_user) as power_users
	from user_classification
	group by firm_id

)

, consolidated as (

	select
		dates.activity_month
		, firms.firm_id
		, firms.firm_name
		, firms.practice_area
		, firms.client_base
		, firms.client_service_region
		, firms.client_service_sub_region
		, firms.market_segment
		, firms.country
		, firms.firm_size
		, case
			when firms.firm_size < 100 then '0-99'
			when firms.firm_size between 100 and 499 then '100-499'
			when firms.firm_size between 500 and 999 then '500-999'
			else '1000+'
		end as firm_size_category
		, nvl(aggregated_usage.unique_users, 0) as unique_users
		, nvl(aggregated_usage.power_users, 0) as power_users
		, nvl((nvl(aggregated_usage.power_users, 0) / nullif(firms.firm_size, 0)), 0.0) as power_users_ratio
	from dates
		left join firms on dates.activity_month >= firms.registered_month
		left join aggregated_usage on dates.activity_month = aggregated_usage.activity_month
			and firms.firm_id = aggregated_usage.firm_id

)

, percentile_thresholds AS (

	select
		activity_month
		, firm_size_category
		, practice_area
		, client_base
		, market_segment
		, APPROX_PERCENTILE(power_users_ratio, 0.90) AS p90_threshold
	from consolidated
	group by activity_month
		, firm_size_category
		, practice_area
		, client_base
		, market_segment
)


, final as (

	select
		consolidated.activity_month
		, consolidated.firm_id
		, consolidated.firm_name
		, consolidated.practice_area
		, consolidated.client_base
		, consolidated.client_service_region
		, consolidated.client_service_sub_region
		, consolidated.market_segment
		, consolidated.country
		, consolidated.firm_size
		, consolidated.firm_size_category
		, consolidated.unique_users
		, consolidated.power_users
		, consolidated.power_users_ratio
		, rank() over (
			partition by consolidated.activity_month
				, consolidated.firm_size_category
				, consolidated.practice_area
				, consolidated.client_base
				, consolidated.market_segment
			order by consolidated.power_users_ratio desc
		) as power_user_rank
		, case
			when (consolidated.power_users_ratio >= percentile_thresholds.p90_threshold) then 'Top 10% Power Users'
			else 'Not a Power User'
		end as power_user_category
		, case 
			when (consolidated.power_users_ratio >= 0.8) /  then '80% Power Users'
			when (consolidated.power_users_ratio between 0.5 and 0.79) then '50% - 79% Power Users'
			when (consolidated.power_users_ratio < 0.5) then '0% - 49% Power Users'
		  end as Power_User_Ratio_Category
		, percentile_thresholds.p90_threshold as p90_threshold
		, {{ required_table_fields() }}
	from consolidated
		left join percentile_thresholds
			on consolidated.activity_month = percentile_thresholds.activity_month
			and consolidated.firm_size_category = percentile_thresholds.firm_size_category
			and consolidated.practice_area = percentile_thresholds.practice_area
			and consolidated.client_base = percentile_thresholds.client_base
			and consolidated.market_segment = percentile_thresholds.market_segment

)

select
	*
from final
