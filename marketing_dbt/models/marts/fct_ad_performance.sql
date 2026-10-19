with facebook as (

    select
        platform,
        ad_id,
        account_id,
        campaign_id,
        ad_group_id,
        account_name,
        campaign_name,
        ad_group_name,
        ad_name,
        ad_date,
        currency_code,

        cast(null as string) as country_code,
        cast(null as string) as data_source,

        spend,
        impressions,
        clicks

    from {{ ref('int_facebook__ad_performance') }}

),

snapchat as (

    select
        platform,
        ad_id,
        cast(null as string) as account_id,
        campaign_id,
        ad_group_id,
        cast(null as string) as account_name,
        campaign_name,
        ad_group_name,
        ad_name,
        ad_date,
        currency_code,
        country_code,
        data_source,
        spend,
        impressions,
        clicks

    from {{ ref('int_snapchat__ad_performance') }}

),

combined as (

    select * from facebook

    union all

    select * from snapchat

)

select *
from combined