with source as (

    select *
    from {{ source('facebook', 'fb_ads_stats') }}

),

renamed as (

    select
        cast(ad_id as string) as ad_id,
        cast(account_id as string) as account_id,
        cast(ad_date as date) as ad_date,

        try_cast(ad_spend as decimal(18, 2)) as spend,
        try_cast(ad_impressions as bigint) as impressions,
        try_cast(ad_clicks as bigint) as clicks

    from source

)

select *
from renamed