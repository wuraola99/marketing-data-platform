with ad_stats as (

    select *
    from {{ ref('stg_snapchat__ads_stats') }}

),

ads as (

    select *
    from {{ ref('stg_snapchat__ads') }}

),

adgroups as (

    select *
    from {{ ref('int_snapchat__latest_adgroups') }}

),

campaigns as (

    select *
    from {{ ref('stg_snapchat__campaigns') }}

),

joined as (

    select
        'snapchat' as platform,

        s.ad_id,
        a.ad_group_id,
        g.campaign_id,

        c.campaign_name,
        g.ad_group_name,
        a.ad_name,

        s.ad_date,
        s.country_code,
        s.currency_code,
        s.data_source,

        s.spend,
        s.impressions,
        s.clicks

    from ad_stats as s

    left join ads as a
        on s.ad_id = a.ad_id

    left join adgroups as g
        on a.ad_group_id = g.ad_group_id

    left join campaigns as c
        on g.campaign_id = c.campaign_id

)

select *
from joined