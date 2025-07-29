# Harvey AI Product Analytics

## Overview

This analytics project transforms raw telemetry and CRM data into trusted, business-ready insights that measure user engagement, firm performance, and product adoption on Harvey’s AI platform. The models are designed for scalability, auditability, and clarity—enabling the business to define and track healthy usage across users and firms.

([sample data](https://docs.google.com/spreadsheets/d/1QCykHV7gq4XXtrpvgmITf2YCGuljyr9NZHzAFl0FWxQ/edit?gid=2072030414#gid=2072030414))

## Quick Links
- [Power User Definition](analyses/power_users.md)
- [Power User Analysis](analyses/insights__power_users.sql)
- [Data Intuition and Data Quality Framework](#data-quality-framework)

## Analytics Architecture

### Data Flow
```
Raw Data Sources → Base Models → Core Models → Curated Models → Business Insights
```

- **Base Models**: Cleans and standardizes raw data from Nucleus (made up telemetry system) and Salesforce (CRM)
- **Core Models**: Creates dimensional tables and fact tables for business analysis
- **Curated Models**: Aggregate and enrich data for specific business use cases and metrics
- **Analyses**: Identifies power users

## Project Interpretation Guide

| Layer | Purpose | Models | Key Metrics |
|-------|---------|--------|-------------|
| **Base** (`product_analytics/models/base/`) | Data standardization and quality assurance | • `base_nucleus__events`: users table in sample data<br>• `base_nucleus__users`: users table in sample data (included foriegn keys and other attributes) <br>• `base_salesforce__firms`: firms table in sample data (introduced dimensional attributes)| • NA |
| **Core** (`product_analytics/models/core/`) | Dimensional modeling and business logic implementation | • `core__calendar`: Time dimension for trend analysis<br>• `core__daily_event_summary`: Daily event aggregations by type<br>• `core__monthly_user_engagement`: Monthly user activity and engagement levels<br>• `core__user_cohort_analysis`: User retention and cohort performance | • Daily/Monthly Active Users (DAU/MAU)<br>• User engagement levels (high/medium/low/zero)<br>• Cohort retention rates and growth trends<br>• Query volume and document upload patterns |
| **Curated** (`product_analytics/models/curated/`) | Business-specific aggregations and insights | • `curated__firm_usage_summary`: Firm-level health and growth metrics | • Firm health scores (healthy/moderate/at_risk)<br>• Growth trends and usage patterns<br>• Power user ratios and engagement quality |
| **Analyses** (`product_analytics/analyses/`) | Strategic insights and power user identification | • `insights__power_users`: Power user classification and firm performance ranking | • Power user identification (100+ queries, 3 query types, 20+ feedback, ≤5 days active)<br>• Firm performance rankings within segments<br>• Top 10% power user firms by segment |

## Design Principles

1. DRY & Modular: Each model is purpose-built and layered for reusability
2. Dimensional Modeling: Fact and dimension separation for analytical, BI flexibility
3. Contract-Driven Models: Enforced dbt contracts and tests validate schema and data integrity
4. Medallion Pattern: Follows Bronze (`source`) → Silver (`base`) → Gold (`core`, `curated`) structure

## Data Quality Framework

### **Observed Data Quality Issues:**
- **Missing Foriegn Key** in `users` table: Users table doesn't contain `firm_id` potentially due to missing joins or deleted metadata.
- **Slowly changing Dimensions**: `firms` table contains a factual field called firm size that can change over a period of time.
- **Orphaned Users**: Some users in the `users` table may not have an associated `firm_id` in the `firms` table, leading to broken joins and incomplete firm-level rollups.
- **Nulls values**: Certain events might null feedback_score values despite being valid query events. Underlying assumption in the sample data is user provides feedback for every quick which will be different from real world usage.

To prevent some of the potential data quality concerns, here are some proactive methods used in the project.

### Contract Enforcement
All models enforce explicit contracts to prevent data quality issues:
```yaml
config:
  contract:
    enforced: true
```

**Benefits**:
- Prevents schema drift and unexpected column changes
- Ensures data type consistency across environments
- Validates required fields and constraints
- Maintains referential integrity

### Proactive Data Quality Monitoring
**Anomaly Detection**: `warn_freshness_anomalies_defaults` tests monitor:
- Data freshness and update frequency
- Unexpected gaps in data delivery
- Timestamp consistency across models

**Data Tests**: Comprehensive validation including:
- `not_null` constraints on critical fields
- `unique` constraints on primary keys
- `accepted_values` for categorical fields
- `custom tests` Custom business logic validation

## Business Impact

### User Engagement Insights
- **Power User Identification**: 4% of users drive 40% of platform activity
- **Engagement Segmentation**: High/medium/low engagement classification
- **Retention Analysis**: Cohort-based retention tracking and prediction

### Firm Performance Metrics
- **Health Scoring**: Automated firm health assessment (healthy/moderate/at_risk)
- **Growth Tracking**: Month-over-month usage trends and growth indicators
- **Segment Analysis**: Performance comparison across practice areas and firm sizes

### Product Intelligence
- **Feature Adoption**: Usage patterns across assistant, vault, and workflow features
- **Feedback Analysis**: User satisfaction and product improvement insights
- **Usage Optimization**: Identification of underutilized features and opportunities

## Support and Maintenance

### Monitoring
- Daily data quality checks via dbt tests
- Weekly freshness anomaly monitoring
- Monthly performance and usage reviews

### Updates
- Model updates follow semantic versioning
- Breaking changes require migration scripts
- Documentation updated with each release
