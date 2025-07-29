with recursive date_series as (

	select 
		to_date('2021-01-01') as calendar_date

	union all

	select
		dateadd(day, 1, calendar_date) as calendar_date
	from date_series
	where
		calendar_date < current_date + interval '50 years'
)

, final as (

	select
	hash(calendar_date)as core_calendar_id
	, calendar_date
	, concat(
		year(calendar_date), '-', lpad(month(calendar_date), 2, '0')
	) as year_month
	, date_trunc('month', calendar_date) as month_start
	, last_day(calendar_date) as month_end
	, concat(year(calendar_date), '-q', quarter(calendar_date)) as year_quarter
	, weekofyear(calendar_date) as week_number
	, year(calendar_date) as calendar_year
	, {{ required_table_fields() }}
	from date_series

)

select
	*
from final
