with ad_stats as (

    select *
    from {{ ref('stg_facebook__ads_stats') }}

),

ads as (

    select *
    from {{ ref('stg_facebook__ads') }}

),

campaigns as (

    select *
    from {{ ref('stg_facebook__campaigns') }}

),

adgroups as (

    select *
    from {{ ref('stg_facebook__adgroups') }}

),

accounts as (

    select *
    from {{ ref('stg_facebook__accounts') }}

),

joined as (

    select
        'facebook' as platform,

        s.ad_id,
        s.account_id,
        a.campaign_id,
        a.ad_group_id,

        acc.account_name,
        c.campaign_name,
        g.ad_group_name,
        a.ad_name,
        a.ad_status,

        s.ad_date,
        acc.currency_code,

        s.spend,
        s.impressions,
        s.clicks

    from ad_stats as s

    left join ads as a
        on s.ad_id = a.ad_id
        and s.account_id = a.account_id

    left join campaigns as c
        on a.campaign_id = c.campaign_id

    left join adgroups as g
        on a.ad_group_id = g.ad_group_id

    left join accounts as acc
        on s.account_id = acc.account_id

)

select *
from joined