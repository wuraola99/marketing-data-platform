with source as (

    select *
    from {{ source('snapchat', 'snapchat_ads') }}

),

renamed as (

    select
        cast(ad_id as string) as ad_id,
        cast(ad_group_id as string) as ad_group_id,
        ad_name,
        cast(ad_detail_updated_at as timestamp) as updated_at

    from source

)

select *
from renamed