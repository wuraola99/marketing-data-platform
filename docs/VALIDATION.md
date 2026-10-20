# Validation, Business Questions, and Case-Study Acceptance

This document maps the take-home case study to the actual repository and provides SQL to validate the **deployed** Gold data. 

## 1. Deployment evidence and baseline

| Check | Observed result | Evidence type |
| --- | --- | --- |
| GitHub Actions `Deploy dbt to Databricks` | Success, approximately 1m 12s | 
| `marketing_dev.gold.fct_ad_performance` | **95,109 rows** | User-executed Databricks SQL |
| `marketing_dev.gold.mart_daily_ad_performance` | **758 rows** | User-executed Databricks SQL |
| Development dbt/Elementary | Previously successful; report showed 46 passed tests and 14 healthy tables | User-observed local Elementary report |
| Every business KPI result | **Queries supplied; outputs not yet captured** | Pending execution |

Baseline query:

```sql
SELECT 'fact' AS model, COUNT(*) AS row_count
FROM marketing_dev.gold.fct_ad_performance
UNION ALL
SELECT 'daily' AS model, COUNT(*) AS row_count
FROM marketing_dev.gold.mart_daily_ad_performance;
```

**Expected from the observed snapshot:** fact 95,109, daily 758. Counts may change if Bronze data is updated.

## 2. Query conventions

- Use `marketing_dev.gold.fct_ad_performance` for campaign/ad-level questions and `marketing_dev.gold.mart_daily_ad_performance` for platform/day/currency summaries.
- **`currency_code` is preserved in spend comparisons.** A single spend total combining EUR and USD is not valid without conversion.
- `SUM(clicks)` and `SUM(impressions)` can represent **partial observed counts** where source records contain `NULL`. Include completeness indicators when interpreting results.
- CTR/CPC/CPM are ratios of sums, **not averages of row-level rates**. For the daily mart, respect its completeness flags and `NULL` KPIs.
- The fact does not include a guaranteed complete historical campaign dimension. Snapchat joins to the latest ad-group metadata.

## 3. Required business questions — executable SQL

### Q1. What is total advertising spend, by currency?

```sql
SELECT currency_code, ROUND(SUM(spend), 2) AS total_spend
FROM marketing_dev.gold.fct_ad_performance
GROUP BY currency_code
ORDER BY currency_code;
```

This is the only defensible version of *overall spend* without an FX conversion layer.

### Q2. How much did we spend on Facebook vs Snapchat?

```sql
SELECT platform, currency_code, ROUND(SUM(spend), 2) AS total_spend
FROM marketing_dev.gold.fct_ad_performance
GROUP BY platform, currency_code
ORDER BY currency_code, platform;
```

**Previously observed fact-level reference totals:** Facebook EUR **2,562,561.24**; Facebook USD **6,869,536.99**; Snapchat EUR **30,529.76**. Re-run to confirm current state. Only compare Facebook vs Snapchat directly within the same currency.

### Q3. How much did we spend by campaign?

```sql
SELECT platform, currency_code, campaign_id, campaign_name,
       ROUND(SUM(spend), 2) AS total_spend
FROM marketing_dev.gold.fct_ad_performance
GROUP BY platform, currency_code, campaign_id, campaign_name
ORDER BY currency_code, total_spend DESC;
```

Grouping by `platform` and `campaign_id` avoids merging unrelated campaigns with the same name. Null campaign IDs/names may indicate missing metadata from a left join.

### Q4. How many impressions did each platform generate?

```sql
SELECT platform,
       SUM(impressions) AS observed_impressions,
       SUM(CASE WHEN impressions IS NULL THEN 1 ELSE 0 END) AS missing_impression_records
FROM marketing_dev.gold.fct_ad_performance
GROUP BY platform
ORDER BY platform;
```

The observed impressions are **not guaranteed complete** if missing record counts are positive.

### Q5. Which campaigns generated the most impressions?

```sql
SELECT platform, campaign_id, campaign_name,
       SUM(impressions) AS observed_impressions,
       SUM(CASE WHEN impressions IS NULL THEN 1 ELSE 0 END) AS missing_impression_records
FROM marketing_dev.gold.fct_ad_performance
GROUP BY platform, campaign_id, campaign_name
ORDER BY observed_impressions DESC
LIMIT 20;
```

### Q6. How many clicks did each campaign generate?

```sql
SELECT platform, campaign_id, campaign_name,
       SUM(clicks) AS observed_clicks,
       SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS missing_click_records
FROM marketing_dev.gold.fct_ad_performance
GROUP BY platform, campaign_id, campaign_name
ORDER BY observed_clicks DESC;
```

### Q7. Which platform generated more clicks?

```sql
SELECT platform,
       SUM(clicks) AS observed_clicks,
       SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS missing_click_records
FROM marketing_dev.gold.fct_ad_performance
GROUP BY platform
ORDER BY observed_clicks DESC;
```

Because missing clicks differ by platform, **ranking observed clicks is not necessarily a ranking of true total clicks**.

### Q8. What are CTR, CPC and CPM by day, platform and currency?

```sql
SELECT platform, ad_date, currency_code,
       total_spend, total_impressions, total_clicks,
       missing_click_records, missing_impression_records,
       clicks_complete, impressions_complete,
       ctr_pct, cpc, cpm
FROM marketing_dev.gold.mart_daily_ad_performance
ORDER BY ad_date DESC, platform, currency_code;
```

Definitions: `CTR (%) = clicks / impressions * 100`; `CPC = spend / clicks`; `CPM = spend / impressions * 1000`. When denominators are zero or necessary metrics are incomplete, the corresponding KPI is `NULL`.

### Q9. How does performance change over time?

```sql
SELECT ad_date, platform, currency_code,
       total_spend, total_impressions, total_clicks,
       ctr_pct, cpc, cpm,
       clicks_complete, impressions_complete
FROM marketing_dev.gold.mart_daily_ad_performance
ORDER BY ad_date, platform, currency_code;
```

For monthly spend, aggregate by `date_trunc('month', ad_date)` **and currency**. Avoid averaging daily CTR/CPC/CPM; recalculate ratios from appropriately complete numerator/denominator totals instead.

### Q10. Compare Facebook and Snapchat spend in the same currency

```sql
SELECT currency_code, platform,
       ROUND(SUM(total_spend), 2) AS total_spend
FROM marketing_dev.gold.mart_daily_ad_performance
WHERE currency_code = 'EUR'
GROUP BY currency_code, platform
ORDER BY total_spend DESC;
```

The currency filter is deliberate. A cross-platform comparison in EUR does not include Facebook's USD spend.

### Q11. Which campaign had the most clicks last month?

```sql
SELECT platform, campaign_id, campaign_name,
       SUM(clicks) AS observed_clicks,
       SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS missing_click_records
FROM marketing_dev.gold.fct_ad_performance
WHERE ad_date >= add_months(date_trunc('month', current_date()), -1)
  AND ad_date < date_trunc('month', current_date())
GROUP BY platform, campaign_id, campaign_name
ORDER BY observed_clicks DESC
LIMIT 10;
```

If there are no rows for the preceding calendar month, the query correctly returns no results. Campaign rankings based on incomplete click records should be described as observed rankings.

## 4. Technical validation SQL

### A. Confirm fact platform distribution

```sql
SELECT platform, COUNT(*) AS records
FROM marketing_dev.gold.fct_ad_performance
GROUP BY platform;
```

Previously observed: Facebook **92,300**, Snapchat **2,809**; total **95,109**.

### B. Confirm Gold daily grain

```sql
SELECT platform, ad_date, currency_code, COUNT(*) AS duplicates
FROM marketing_dev.gold.mart_daily_ad_performance
GROUP BY platform, ad_date, currency_code
HAVING COUNT(*) > 1;
```

Expected: **zero rows**.

### C. Check platform validity and negative metrics

```sql
SELECT
  SUM(CASE WHEN platform NOT IN ('facebook', 'snapchat') OR platform IS NULL THEN 1 ELSE 0 END) AS invalid_platform_rows,
  SUM(CASE WHEN spend < 0 THEN 1 ELSE 0 END) AS negative_spend_rows,
  SUM(CASE WHEN impressions < 0 THEN 1 ELSE 0 END) AS negative_impression_rows,
  SUM(CASE WHEN clicks < 0 THEN 1 ELSE 0 END) AS negative_click_rows
FROM marketing_dev.gold.fct_ad_performance;
```

Expected ideally zero for each; investigate any nonzero result. **This query supplements existing dbt tests; do not claim all four are already enforced by dbt unless corresponding tests exist.**

### D. Audit missing values

```sql
SELECT platform, currency_code, COUNT(*) AS records,
       SUM(CASE WHEN spend IS NULL THEN 1 ELSE 0 END) AS missing_spend,
       SUM(CASE WHEN impressions IS NULL THEN 1 ELSE 0 END) AS missing_impressions,
       SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS missing_clicks
FROM marketing_dev.gold.fct_ad_performance
GROUP BY platform, currency_code
ORDER BY platform, currency_code;
```

Earlier observations included missing clicks on Facebook and Snapchat and missing impressions on Facebook. 

### E. Reconcile daily and fact row counts

```sql
SELECT
  (SELECT COUNT(*) FROM marketing_dev.gold.fct_ad_performance) AS fact_rows,
  (SELECT SUM(performance_records) FROM marketing_dev.gold.mart_daily_ad_performance) AS daily_source_rows;
```

Expected equal. The project also has `assert_daily_performance_reconciliation.sql`, which checks platform/currency spend, clicks, impressions, and record counts.

### F. Verify KPI suppression

```sql
SELECT *
FROM marketing_dev.gold.mart_daily_ad_performance
WHERE (NOT clicks_complete AND (ctr_pct IS NOT NULL OR cpc IS NOT NULL))
   OR (NOT impressions_complete AND (ctr_pct IS NOT NULL OR cpm IS NOT NULL));
```

Expected: **zero rows**. Mirrors the project singular test.

### G. Confirm dbt build and lineage

From `marketing_dbt`, with a valid development profile:

```powershell
uv run dbt deps
uv run dbt build --select package:marketing_dbt
uv run dbt docs generate
uv run dbt docs serve
```

For the deployed target, use the GitHub Actions workflow rather than local dummy OAuth variables. Save the successful workflow URL or screenshot as evidence. `dbt docs generate` creates a static HTML docs artifact locally; `dbt docs serve` lets reviewers inspect the lineage graph.

## 5. Requirement-by-requirement audit

The case study's **Definition of Done has 22 bullet requirements**. Status labels below distinguish code/evidence from incomplete verification.

| # | Case-study requirement | Status | Evidence / caveat |
| --- | --- | --- | --- |
| 1 | Facebook data loaded to Databricks | Verified | Five registered Bronze source tables; downstream Facebook rows present |
| 2 | Snapchat data loaded to Databricks | Verified | Four registered Bronze source tables; downstream Snapchat rows present |
| 3 | Raw data accessible through Unity Catalog | Verified | `marketing_dev.bronze` sources read successfully by dbt |
| 4 | dbt connects to environment | Verified | Local development and service-principal deployment connection |
| 5 | Staging models | Verified | Nine staging models |
| 6 | Intermediate models where appropriate | Verified | Three intermediate models |
| 7 | Unified marketing model | Verified | `fct_ad_performance`, 95,109 rows |
| 8 | Model grain defined | Documented | Grain specified in architecture and model descriptions |
| 9 | Data quality tests | Verified | YAML tests plus three singular tests; successful deployment build |
| 10 | Important columns and models documented | Implemented; improve as needed | YAML descriptions exist; some columns and sources have limited descriptions |
| 11 | Static HTML dbt docs can be generated | Previously demonstrated | `dbt docs generate` used; generated HTML is not in repository |
| 12 | Lineage visible | Previously demonstrated | dbt docs graph from `ref()` and `source()` dependencies |
| 13 | Elementary configured | Verified in development | Package, models and CLI report; **not enabled in deploy** |
| 14 | CI environment | Partially demonstrated | GitHub Actions `dbt parse` only; no live CI data tests |
| 15 | Staging/development environment | Verified | Local OAuth, `default_silver` and `default_gold` |
| 16 | Production environment | Demonstrated with qualification | `deploy` target and `silver`/`gold`; shares `marketing_dev` catalog |
| 17 | Service principal for production | Verified | OAuth M2M `marketing-dbt-ci`; no personal PAT in deploy |
| 18 | Unity Catalog permissions | Verified operationally | Deployment succeeded; analyst SELECT separately granted |
| 19 | Appropriate materializations | Verified | Views in staging/intermediate; tables in Gold; incremental not used |
| 20 | CI/CD workflow | Verified with limitation | PR/push parse CI + successful manual deploy |
| 21 | README setup and architecture | Addressed by accompanying docs | Add the generated files to repository |
| 22 | Final model answers business questions | Query capability demonstrated; outputs pending | Run and record SQL in section 3; interpret missing values/currencies |



> I gingested supplied Facebook and Snapchat datasets into Unity Catalog Bronze tables, standardized their fields with nine staging views, and used three intermediate views to enrich the advertising facts and deduplicate Snapchat ad-group versions. A unified Gold fact preserves source reporting grain and currency, while a daily mart calculates spend, impressions, clicks and safe KPIs. I used views for reusable transformations and tables for downstream marts. Automated dbt tests and Elementary in development provide data-quality visibility. GitHub Actions performs parse validation on changes and a separately triggered, service-principal-authenticated deployment into Silver and Gold schemas. I intentionally distinguish missing metrics from zero and avoid combining different currencies without conversion. Current limitations include parse-only CI, development-only Elementary, and schema-level rather than catalog-level production isolation.

