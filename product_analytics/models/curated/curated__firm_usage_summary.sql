with dates as (

	select
		distinct year_month as activity_month
	from {{ ref('core__calendar') }}
	where calendar_date <= current_date

)

, firms AS (

	select
		*
		, to_varchar(sys_created_at, 'yyyy-MM') as registered_month
	from {{ ref('base_salesforce__firms') }}
	where is_active = true

)

, monthly_activity as (

	select
		*
	from {{ ref('core__monthly_user_engagement') }}

)

, consolidated as (

	select
		dates.activity_month as reporting_month
		, firms.firm_id
		, firms.firm_name
		, firms.practice_area
		, firms.client_base
		, firms.client_service_region
		, firms.client_service_sub_region
		, firms.market_segment
		, firms.country
		, firms.state
		, firms.city
		, firms.zip_code
		, firms.firm_size
		, firms.arr_in_thousands_usd
		, nvl(count(distinct monthly_activity.user_id), 0) as active_users
		, nvl(sum(monthly_activity.total_queries), 0) as total_queries
		, nvl(sum(monthly_activity.total_documents_uploaded), 0) as total_documents_uploaded
		, nvl(sum(monthly_activity.feedbacks_submitted), 0) as feedbacks_submitted
		, nvl(avg(monthly_activity.average_feedback_score), 0.0) as average_feedback_score
		, (nvl(sum(monthly_activity.total_queries), 0)
			/ nullif(count(distinct monthly_activity.user_id), 0.00))
		as average_queries_per_user
	from dates
		left join firms on dates.activity_month >= firms.registered_month
		left join monthly_activity on dates.activity_month = monthly_activity.activity_month
			and firms.firm_id = monthly_activity.firm_id
	group by
		dates.activity_month
		, firms.firm_id
		, firms.firm_name
		, firms.practice_area
		, firms.client_base
		, firms.client_service_region
		, firms.client_service_sub_region
		, firms.market_segment
		, firms.country
		, firms.state
		, firms.city
		, firms.zip_code
		, firms.firm_size
		, firms.arr_in_thousands_usd

)

, prior_month_usage AS (

	select
		*
		, nvl(lag(active_users) over (
			partition by firm_id
			order by reporting_month
		), 0) as prior_month_active_users
		, nvl(lag(total_queries) over (
			partition by firm_id
			order by reporting_month
		), 0) as prior_month_total_queries
		, nvl(lag(total_documents_uploaded) over (
			partition by firm_id
			order by reporting_month
		), 0) as prior_month_total_documents_uploaded
		, nvl(lag(average_queries_per_user) over (
			partition by firm_id
			order by reporting_month
		), 0.00) as prior_month_average_queries_per_user
		, nvl(lag(average_feedback_score) over (
			partition by firm_id
			order by reporting_month
		), 0.0) as prior_month_average_feedback_score
	from consolidated

)

, usage_trend AS (

	select
		*
		, case
			when active_users > prior_month_active_users then 'upward'
			when active_users < prior_month_active_users then 'downward'
			when active_users = prior_month_active_users then 'flat'
		  end as active_users_trend
		, case
			when total_queries > prior_month_total_queries then 'upward'
			when total_queries < prior_month_total_queries then 'downward'
			when total_queries = prior_month_total_queries then 'flat'
		  end as total_queries_trend
		, case
			when total_documents_uploaded > prior_month_total_documents_uploaded then 'upward'
			when total_documents_uploaded < prior_month_total_documents_uploaded then 'downward'
			when total_documents_uploaded = prior_month_total_documents_uploaded then 'flat'
		  end as total_documents_uploaded_trend
		, case
			when average_feedback_score > prior_month_average_feedback_score then 'upward'
			when average_feedback_score < prior_month_average_feedback_score then 'downward'
			when average_feedback_score = prior_month_average_feedback_score then 'flat'
		  end as average_feedback_score_trend
		, case
			when average_queries_per_user > prior_month_average_queries_per_user then 'upward'
			when average_queries_per_user < prior_month_average_queries_per_user then 'downward'
			when average_queries_per_user = prior_month_average_queries_per_user then 'flat'
		  end as average_queries_per_user_trend
	from prior_month_usage

)

, firm_health AS (

	select
		*
		, case
			when (active_users / nullif(firm_size, 0) >= 0.8)
				and average_queries_per_user_trend = 'upward' then 'healthy'
			when (active_users / nullif(firm_size, 0) between 0.5 and 0.79)
				and average_queries_per_user_trend in ('flat', 'upward') then 'moderate'
			when (active_users / nullif(firm_size, 0) < 0.5)
				and average_queries_per_user_trend in ('flat', 'upward') then 'at_risk'
			else 'na'
		end as firm_health
		, case
			when active_users_trend = 'upward' and total_queries_trend = 'upward' then 'growing'
			when active_users_trend = 'flat' and total_queries_trend = 'flat' then 'stable'
			else 'declining'
		  end as firm_growth_trend
		, MD5(firm_id || reporting_month) AS _unique_key
	from usage_trend

)

, final as (

	select
		reporting_month
		, firm_id
		, firm_name
		, practice_area
		, client_base
		, client_service_region
		, client_service_sub_region
		, market_segment
		, country
		, state
		, city
		, zip_code
		, firm_size
		, arr_in_thousands_usd
		, active_users
		, total_queries
		, total_documents_uploaded
		, average_feedback_score
		, feedbacks_submitted
		, average_queries_per_user
		, prior_month_active_users
		, prior_month_total_queries
		, prior_month_total_documents_uploaded
		, prior_month_average_feedback_score
		, prior_month_average_queries_per_user
		, active_users_trend
		, total_queries_trend
		, total_documents_uploaded_trend
		, average_feedback_score_trend
		, average_queries_per_user_trend
		, firm_health
		, firm_growth_trend
		, _unique_key
		, {{ required_table_fields() }}
	from firm_health

)

select
	*
from final
