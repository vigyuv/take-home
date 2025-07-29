# Power User Analysis

## Overview

This analysis identifies and categorizes power users within Harvey's Platform based on engagement metrics. The analysis provides insights into user behavior patterns, firm-level power user distribution, and comparative performance across different market segments.

## Power User Definition

A **power user** is defined as a user who meets **ALL** of the following criteria for self-sustained platform usage at a given organization:

1. **High Activity Volume**: ≥100 total queries in the month
2. **Feature Diversity**: Uses all 3 unique query types (assistant, vault, workflow)
3. **Product Investment**: Submits >20 feedback responses
4. **Current Engagement**: Active within the last 5 days

### Business Rationale

- **100+ queries**: Indicates heavy platform usage and reliance on the product. Sets high bar for usage.
- **3 unique query types**: Shows comprehensive feature adoption across all major product areas
- **20+ feedback submissions**: Demonstrates investment in product improvement and engagement
- **≤5 days since last active**: Ensures users are current and not historical power users

## Outputs

### Power User Categories
1. **Top 10% Power Users**: Firms with power user ratio ≥ 90th percentile in their segment
2. **Not a Power User**: All other firms

### Power User Ratio Categories
1. **80%+ Power Users**: ≥80% of firm size are power users
2. **50% - 79% Power Users**: 50-79% of firm size are power users  
3. **0% - 49% Power Users**: <50% of firm size are power users

## Key Assumptions

### Data Quality Assumptions
- All users in `core__monthly_user_engagement` are active users
- Firm size data is accurate and up-to-date
- Feedback submission data is complete and reliable

### Business Assumptions
- Power users represent the most valuable customer segment
- Feature diversity (3 query types) indicates overall platform adoption
- Recent activity (≤5 days) ensures current engagement
- Firm size categories provide meaningful segmentation for analysis

### Analytical Assumptions
- Percentile thresholds are calculated within meaningful segments
- Power user ratio is a valid measure of firm engagement quality
- Monthly aggregation provides sufficient granularity for trend analysis

## Analysis Structure

### 1. User Classification (`user_classification` CTE)
- Applies power user criteria to individual users
- Creates `verified_power_user` field that contains user_id for power users, null otherwise

### 2. Firm Aggregation (`aggregated_usage` CTE)
- Aggregates user-level data to firm-month level
- Calculates:
  - `unique_users`: Total distinct users per firm per month
  - `power_users`: Total distinct power users per firm per month

### 3. Firm Size Segmentation (`consolidated` CTE)
- Joins firm metadata with usage data
- Creates firm size categories:
  - **0-99**: Small firms
  - **100-499**: Medium firms
  - **500-999**: Large firms
  - **1000+**: Enterprise firms
- Calculates `power_users_ratio`: Power users / Total firm size

### 4. Percentile Analysis (`percentile_thresholds` CTE)
- Calculates 90th percentile thresholds (using Snowflake's `APPROX_PERCENTILE`) for power user ratios
- Segmented by the following dimensions for accuracy and leveled comparison:
  - Activity month
  - Firm size category
  - Practice area
  - Client base
  - Market segment

### 5. Final Classification (`final` CTE)
- Applies percentile-based and ratio-based categorizations
- Creates ranking within segments

## Usage Recommendations

### For Product Teams
- Focus retention efforts on firms with high power user ratios
- Identify features that drive power user behavior
- Target product improvements based on power user feedback patterns

### For Sales Teams
- Prioritize accounts with growing power user ratios
- Use power user metrics in customer success conversations
- Identify expansion opportunities in high-performing firms

### For Executive Teams
- Monitor power user trends as a key health metric
- Use power user ratios for customer segmentation
- Track power user growth as a leading indicator of product-market fit

## Limitations

- Power user criteria may need adjustment based on business evolution
- Firm size categories are static and may not reflect current business reality
- Analysis assumes equal weighting of all power user criteria
- Percentile thresholds may be sensitive to small sample sizes in some segments
