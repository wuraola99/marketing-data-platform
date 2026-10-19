with fact_totals as (

    select
        platform,
        currency_code,
        count(*) as record_count,
        sum(spend) as total_spend,
        sum(impressions) as total_impressions,
        sum(clicks) as total_clicks
    from {{ ref('fct_ad_performance') }}
    group by platform, currency_code

),

daily_totals as (

    select
        platform,
        currency_code,
        sum(performance_records) as record_count,
        sum(total_spend) as total_spend,
        sum(total_impressions) as total_impressions,
        sum(total_clicks) as total_clicks
    from {{ ref('mart_daily_ad_performance') }}
    group by platform, currency_code

),

reconciliation as (

    select
        coalesce(f.platform, d.platform) as platform,
        coalesce(f.currency_code, d.currency_code) as currency_code,

        f.record_count as fact_records,
        d.record_count as daily_records,

        f.total_spend as fact_spend,
        d.total_spend as daily_spend,

        f.total_impressions as fact_impressions,
        d.total_impressions as daily_impressions,

        f.total_clicks as fact_clicks,
        d.total_clicks as daily_clicks

    from fact_totals f

    full outer join daily_totals d
        on f.platform <=> d.platform
        and f.currency_code <=> d.currency_code

)

select *
from reconciliation

where
    fact_records is distinct from daily_records
    or abs(coalesce(fact_spend, 0) - coalesce(daily_spend, 0)) > 0.01
    or fact_impressions is distinct from daily_impressions
    or fact_clicks is distinct from daily_clicks