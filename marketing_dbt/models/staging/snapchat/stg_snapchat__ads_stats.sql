with source as (

    select *
    from {{ source('snapchat', 'snapchat_ads_stats') }}

),

renamed as (

    select
        cast(ad_detail_id as string) as ad_id,
        ad_currency_code as currency_code,
        ad_country as country_code,
        try_cast(ad_spend as decimal(18, 2)) as spend,
        try_cast(ad_impressions as bigint) as impressions,
        try_cast(ad_clicks as bigint) as clicks,
        cast(ad_date as date) as ad_date,
        data_src as data_source

    from source

)

select *
from renamed