with source as (

    select *
    from {{ source('snapchat', 'snapchat_campaigns') }}

),

renamed as (

    select
        cast(campaign_id as string) as campaign_id,
        cast(account_id as string) as account_id,
        campaign_name

    from source

)

select *
from renamed