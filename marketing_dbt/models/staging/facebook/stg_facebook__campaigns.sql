with source as (

    select *
    from {{ source('facebook', 'fb_campaigns') }}

),

renamed as (

    select
        cast(campaign_id as string) as campaign_id,
        campaign_name,
        cast(campaign_updated_at as timestamp) as updated_at

    from source

)

select *
from renamed