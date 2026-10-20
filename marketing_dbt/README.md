# Marketing dbt project

This is the dbt transformation subproject for the [Marketing Data Platform](../README.md). It reads Facebook and Snapchat raw tables from `marketing_dev.bronze` and builds nine staging views, three intermediate views, and two Gold tables.

## Local development

From the repository root, run `uv sync --frozen`. From this `marketing_dbt` directory:

```powershell
uv run dbt deps
uv run dbt debug
uv run dbt build --select package:marketing_dbt
uv run dbt docs generate
uv run dbt docs serve
```

These commands use your locally configured `~/.dbt/profiles.yml`; check your target and credentials before building. For the full setup, schema naming, and security details, see the [root README](../README.md) and [architecture guide](../docs/ARCHITECTURE.md).

## Models

- `models/staging/facebook/`: five Facebook staging views.
- `models/staging/snapchat/`: four Snapchat staging views.
- `models/intermediate/`: Facebook enrichment, Snapchat latest ad-group lookup, and Snapchat enrichment.
- `models/marts/fct_ad_performance.sql`: unified detail-level marketing fact.
- `models/marts/mart_daily_ad_performance.sql`: platform/date/currency aggregate with completeness-aware CTR, CPC, and CPM.
- `tests/`: three singular reconciliation and completeness tests.

## Deployment

Production-like deployment is triggered manually through `.github/workflows/dbt-deploy.yml`. It uses an OAuth service principal and writes to `marketing_dev.silver` and `marketing_dev.gold`. Local development writes to `marketing_dev.default_silver` and `marketing_dev.default_gold` using the custom `generate_schema_name` macro. Elementary is enabled for development and disabled for the deploy target.

For query examples and the case-study checklist, see [Validation](../docs/VALIDATION.md).
