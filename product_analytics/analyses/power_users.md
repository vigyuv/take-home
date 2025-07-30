## Overview
This analysis identifies **user-level power users** using absolute engagement thresholds, then summarizes **firm-level power-user ratios** and highlights firms whose ratios are in the **top decile (p90)** within their segment. 


## Definition

A power user is defined as a user who meets **ALL** of the following criteria demonstrating self-sustained platform usage and advocates within a given organization:

1) `total_queries >= 100`
2) `unique_query_types = 3` (assistant, vault, workflow)  
3) `feedbacks_submitted > 20`  
4) `days_since_last_active <= 5`

**Business rationale:**
- High query volume (100+): Indicates heavy platform usage and reliance on the product. Sets high bar for usage.
- Full feature breadth (3 query types): Shows comprehensive feature adoption across all major product areas
- Frequent feedback (>20): Demonstrates investment in product improvement and engagement
- Recent activity (≤5 days): Ensures users are current and not historical power users

## Firm-level metrics

From user flags, we compute firm-month metrics (CTE **`aggregated_usage`** and **`consolidated`**):
- `unique_users` = distinct active users in firm × month  
- `power_users` = distinct power users in firm × month  
- `power_users_ratio` = `power_users / firm_size`

> **Note:** Using `firm_size` (headcount) as the denominator emphasizes penetration vs. realized activity. For realized engagement, use `power_users / unique_users`. 

We then compute **p90** of `power_users_ratio` per **segment** and **month** (CTE **`percentile_thresholds`**):
- Segment dimensions: `firm_size_category`, `practice_area`, `client_base`, `market_segment`.

Final classification (CTE **`final`**):
- `power_user_rank` = within-segment rank by `power_users_ratio`  
- `power_user_category` = `'Top 10% Power Users'` if `power_users_ratio >= p90_threshold`, else `'Not a Power User'`  
- `power_user_ratio_category` = bucketed as 80%+, 50–79%, 0–49%. Indicating power user penetration at a firm. 

## Assumptions (specific to this analysis)
- **Feature diversity:** 3 query types (workflow, vault, assistant) indicates overall platform adoption
- **Recent activity:** ≤5 days ensures current engagement
- Firm size categories provide meaningful segmentation for analysis
- **Firm-Size as Denominator:** firm_size (headcount) is used to determine platform adoption.  
- **Registration gating:** Firms only appear after they are created in CRM system (`registered_month` derived from `base_salesforce__firms`).  
- **Segments:** All firm related attributes (practice area, client base, market segment) are simulated and can vary. 

## Limitations
- **Strict user criteria:** Absolute thresholds are opinionated; a lenient view (e.g., X+ query types, lower feedback bar) or a hybrid where user power requires meeting guardrails and being above the user-level p90 for their segment.
- **SCD for firm_size:** Current logic assumes latest headcount; historical changes may distort ratios. Consider snapshots or “as-of month” attributes.

## Analysis Structure

#### 1. User Classification (`user_classification` CTE)
- Applies power user criteria to individual users
- Creates `verified_power_user` field that contains user_id for power users, null otherwise

#### 2. Firm Aggregation (`aggregated_usage` CTE)
- Aggregates user-level data to firm-month level
- Calculates:
  - `unique_users`: Total distinct users per firm per month
  - `power_users`: Total distinct power users per firm per month

#### 3. Firm Size Segmentation (`consolidated` CTE)
- Joins firm metadata with usage data
- Creates firm size categories:
  - **0-99**: Small firms
  - **100-499**: Medium firms
  - **500-999**: Large firms
  - **1000+**: Enterprise firms
- Calculates `power_users_ratio`: Power users / Total firm size

#### 4. Percentile Analysis (`percentile_thresholds` CTE)
- Calculates 90th percentile thresholds (using Snowflake's `APPROX_PERCENTILE`) for power user ratios
- Segmented by the following dimensions for accuracy and leveled comparison:
  - Activity month
  - Firm size category
  - Practice area
  - Client base
  - Market segment

#### 5. Final Classification (`final` CTE)
- Applies percentile-based and ratio-based categorizations
- Creates ranking within segments

---

## Appendix

### Usage Recommendations

#### For Product Teams
- Focus retention efforts on firms with high power user ratios
- Identify features that drive power user behavior
- Target product improvements based on power user feedback patterns

#### For Sales Teams
- Prioritize accounts with growing power user ratios
- Use power user metrics in customer success conversations
- Identify expansion opportunities in high-performing firms

#### For Customer Success Teams
- Focus on firms just below the p90 threshold (most convertible).

#### For Executive Teams
- Monitor power user trends as a key health metric
- Use power user ratios for customer segmentation
- Track power user growth as a leading indicator of product-market fit

---

### Final Output
- `activity_month`
- `firm_id`
- `firm_name`
- `practice_area`
- `client_base`
- `client_service_region`
- `client_service_sub_region`
- `market_segment`
- `country`
- `firm_size`
- `firm_size_category`
- `unique_users`
- `power_users`
- `power_users_ratio`
- `power_user_rank`
- `power_user_category`
- `power_user_ratio_category`
- `p90_threshold`