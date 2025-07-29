Analytics Engineer Take home

Repository structure

product_analytics/				                    -- product analytics dbt project
├── analyses/
│   ├── insights__power_users.sql/				    -- power user analysis
│   ├── power_users_analysis.md/				      -- documentation of the analysis
│
└── models/
   ├── base/
   │   ├── base_nucleus__events.sql				    -- standardized events table
   │   ├── base_nucleus__events.yml				    -- events table documentation
   │   ├── base_nucleus__users.sql				    -- standardized users table
   │   ├── base_nucleus__users.yml				    -- users table documentation
   │   ├── base_salesforce__firms.sql			    -- standardized firms table	
   │   └── base_salesforce__firms.yml			    -- firms table documentation
   │
   ├── core/
   │   ├── core__calendar.sql					        -- dim calendar table
   │   ├── core__calendar.yml					        -- dim calendar documentation
   │   ├── core__daily_event_summary.sql		  -- fact daily event summary table
   │   ├── core__daily_event_summary.yml		  -- fact daily event summary documentation
   │   ├── core__monthly_user_engagement.sql  -- fact monthly user engagement table
   │   ├── core__monthly_user_engagement.yml  -- fact monthly user engagement documentation
   │   ├── core__user_cohort_analysis.sql		  -- fact user cohort analysis
   │   └── core__user_cohort_analysis.yml		  -- fact user cohort analysis documentation
   │
   └── curated/
       ├── curated__firm_usage_summary.sql		-- firm usage summary table
       └── curated__firm_usage_summary.yml		-- firm usage summary documentation
