with ad_performance as (

    select *
    from {{ ref('fct_ad_performance') }}

),

daily_totals as (

    select
        platform,
        ad_date,
        currency_code,

        sum(spend) as total_spend,
        sum(impressions) as total_impressions,
        sum(clicks) as total_clicks,

        count(*) as performance_records,

        sum(
            case when clicks is null then 1 else 0 end
            ) as missing_click_records,

        sum(
            case when impressions is null then 1 else 0 end
            ) as missing_impression_records

    from ad_performance

    group by
        platform,
        ad_date,
        currency_code

),

final as (

    select
        platform,
        ad_date,
        currency_code,

        total_spend,
        total_impressions,
        total_clicks,
        performance_records,
        missing_click_records,
        missing_impression_records,

        (missing_click_records = 0) as clicks_complete,
        (missing_impression_records = 0) as impressions_complete,

        case
            when missing_click_records = 0
            and missing_impression_records = 0
            then round(
        total_clicks * 100.0 / nullif(total_impressions, 0),
        2
        )
        end as ctr_pct,

        case
            when missing_click_records = 0
            then round(
        total_spend / nullif(total_clicks, 0),
        2
        )
        end as cpc,

        case
            when missing_impression_records = 0
            then round(
            total_spend * 1000.0 / nullif(total_impressions, 0),
            2
            )
        end as cpm

    from daily_totals

)

select *
from final