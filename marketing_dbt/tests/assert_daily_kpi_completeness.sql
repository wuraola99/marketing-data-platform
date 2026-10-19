select
    platform,
    ad_date,
    currency_code,
    clicks_complete,
    impressions_complete,
    ctr_pct,
    cpc,
    cpm

from {{ ref('mart_daily_ad_performance') }}

where
    (
        not clicks_complete
        and (
            ctr_pct is not null
            or cpc is not null
        )
    )

    or

    (
        not impressions_complete
        and (
            ctr_pct is not null
            or cpm is not null
        )
    )