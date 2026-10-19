with source as (

    select *
    from {{ source('snapchat', 'snapchat_adgroups') }}

),

renamed as (

    select
        cast(_surrogate_key as string) as ad_group_record_id,
        cast(ad_group_id as string) as ad_group_id,
        cast(campaign_id as string) as campaign_id,
        ad_group_name,
        cast(ad_group_updated_at as timestamp) as updated_at

    from source

)

select *
from renamed