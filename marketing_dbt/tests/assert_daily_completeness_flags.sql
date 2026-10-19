select
    platform,
    ad_date,
    currency_code,
    missing_click_records,
    missing_impression_records,
    clicks_complete,
    impressions_complete

from {{ ref('mart_daily_ad_performance') }}

where
    clicks_complete is distinct from (missing_click_records = 0)

    or impressions_complete is distinct from (missing_impression_records = 0)