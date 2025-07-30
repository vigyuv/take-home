# Harvey AI - Product Analytics

> **Executive Summary**
> - Built a layered analytics model (base → core → curated) to translate telemetry + CRM into trustworthy, decision-ready metrics.
> - Defined **power users** *based on* the `core__monthly_user_engagement` model using guardrails (recency, active days, feature breadth) plus **segment-based p90** query thresholds—implemented as an **analysis** (SQL/Markdown), not as a core column.
> - Surfaced key data-quality risks (FK gaps, SCD firm size, event hygiene, null feedback) and tied each to executable dbt tests.

## Tasks (per assignment)
### 1) Power user definition 
**Definition:** A user is a **power user** in a given month if they are recently active, consistently engaged, and in the **top decile of query volume for their segment**, with minimum activity safeguards.

**Rule (summary):**
- **Recency:** `last_active_at` within *N* days of month-end  
- **Consistency:** at least *X* **active days** in the month  
- **Breadth:** at least *Y* **distinct query types** used  
- **Depth (data-driven):** `total_queries` ≥ **p90** for their segment  
  *(segment = firm_size_category × practice_area × client_base × market_segment

**Where to look (analysis artifacts):**
- Definition & rationale: [`analyses/power_users.md`](analyses/power_users.md)  
- SQL Analysis: [`analyses/insights__power_users.sql`](analyses/insights__power_users.sql)

> **Note:** The assignment permits answering in Markdown/SQL; therefore, the power-user logic is presented as an **analysis** derived from the `core__monthly_user_engagement` model rather than embedded as a persistent column in the core/curated model.

**Why this works:** Combines **guardrails** (recency/consistency/breadth) with a **percentile threshold** that adapts by segment, preventing large-firm bias while preserving comparability.

---

### 2) Potential Data quality issues (and mitigation)
- **Missing foreign keys (users → firms):** Orphaned users break firm rollups.  
  *Mitigation:* `relationships` tests on `users.firm_id → firms.firm_id`; null-safe joins.
- **Slowly Changing Dimensions (firm size):** Using latest size can distort history.  
  *Mitigation:* Documented “as-of month” assumption; call out snapshot/SCD as next step.
- **Event hygiene (accepted values):** Inconsistent `event_type` skews engagement.  
  *Mitigation:* `accepted_values` tests; normalization CTE in base layer.
- **Duplicate/near-duplicate events:** Double counts inflate depth metrics.  
  *Mitigation:* Composite uniqueness and dedupe in base.
- **Null/biased feedback:** Sparse feedback skews satisfaction rates.  
  *Mitigation:* Null handling + rate metrics; volume thresholds for inclusion.
- **Freshness gaps:** Late-arriving telemetry undermines month-close metrics.  
  *Mitigation:* Source freshness checks; flag partial months.

> Each issue above maps to a dbt test or normalization step; see [Data Quality Framework](#data-quality-framework) for details.

---

## Key Model Map

| Layer | Model | Grain | Key Metrics |
|---|---|---|---|
| **Core** | `core__monthly_user_engagement` | user_id × activity_month | `total_queries`, `last_active_date`, `unique_query_types`, `total_documents_uploaded`, `average_feedback_score`, `feedbacks_submitted`, `days_since_last_active`, `engagement_level` |
| **Core** | `core__daily_event_summary` | event_id × activity_date | `unique_users`, `total_users`, `total_queries`, `total_documents_uploaded`, `average_feedback_score` |
| **Core** | `core__user_cohort_analysis` | cohort_month x firm_id | `cohort_month`, `reporting_month`, `firm_id`, `months_since_acquisition`, `retained_users`, `users_in_cohort`, `total_queries`, `retention_rate` |
| **Curated** | `curated__firm_usage_summary` | firm × reporting_month | engagement metrics, engagement trend, growth trend  |
| **Analyses** | `insights__power_users` | analysis result set | Segment p90s, user rankings, power users within a firm and across the customer base |

> See [Model Interpretation Guide](#model-interpretation-guide) for how to read each model.

---

## Assumptions
- **Time zone & month close:** Metrics computed on source TZ/UTC per calendar month.
- **Active day:** Any day with ≥1 qualifying event.
- **Recency window:** “Recent” if `last_active_at` ≤ *N* days from month-end.
- **Feature breadth:** Distinct query types approximate breadth of usage.
- **Percentiles:** p90 by `firm_size_category × practice_area × client_base × market_segment`.
- **Firm size SCD:** Treat `firm_size` as “latest known” unless SCD provided.
- **Null handling:** Exclude null/invalid fields from denominators; track via tests.

---

## Appendix

### Data Flow
```
Raw Data Sources → Base Models → Core Models → Curated Models → Business Insights
```

- **Base Models**: Cleans and standardizes raw data from Nucleus (made up telemetry system) and Salesforce (CRM)
- **Core Models**: Creates dimensional tables and fact tables for business analysis
- **Curated Models**: Aggregate and enrich data for specific business use cases and metrics
- **Analyses**: Identifies power users

## Design Principles

1. DRY & Modular: Each model is purpose-built and layered for reusability
2. Dimensional Modeling: Fact and dimension separation for analytical, BI flexibility
3. Contract-Driven Models: Enforced dbt contracts and tests validate schema and data integrity
4. Medallion Pattern: Follows Bronze (`source`) → Silver (`base`) → Gold (`core`, `curated`) structure

## Model Interpretation Guide

| Layer | Purpose | Models | Key Metrics |
|-------|---------|--------|-------------|
| **Base** (`product_analytics/models/base/`) | Data standardization and quality assurance | • `base_nucleus__events`: events table in sample data.<br>• `base_nucleus__users`: users table in sample data (includes foreign keys and other attributes) <br>• `base_salesforce__firms`: firms table in sample data (introduces firm attributes)| • NA |
| **Core** (`product_analytics/models/core/`) | Dimensional modeling and business logic implementation | • `core__calendar`: Time dimension for trend analysis<br>• `core__daily_event_summary`: Daily event aggregations by type<br>• `core__monthly_user_engagement`: Monthly user activity and engagement levels<br>• `core__user_cohort_analysis`: User retention and cohort performance | • Daily/Monthly Active Users (DAU/MAU)<br>• User engagement levels (high/medium/low/zero)<br>• Cohort retention rates and growth trends<br>• Query volume and document upload patterns |
| **Curated** (`product_analytics/models/curated/`) | Business-specific aggregations and insights | • `curated__firm_usage_summary`: Firm-level health and growth metrics | • Firm health scores (healthy/moderate/at_risk)<br>• Growth trends and usage patterns<br>• Power user ratios and engagement quality |
| **Analyses** (`product_analytics/analyses/`) | Strategic insights and power user identification | • `insights__power_users`: Power user classification and firm performance ranking | • Power user identification (segment-based p90 threshold with guardrails: recency, active days, feature breadth; see analysis)<br>• Firm performance rankings within segments<br>• Top 10% power user firms by segment |

## Data Quality Framework

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

### Data Quality Checks

**Data Tests**: Comprehensive validation including:
- `not_null` constraints on critical fields
- `unique` constraints on primary keys
- `accepted_values` for categorical fields
- `custom tests` Custom business logic validation

**Anomaly Detection**: `warn_freshness_anomalies_defaults` tests monitor:
- Data freshness and update frequency
- Unexpected gaps in data delivery
- Timestamp consistency across models

