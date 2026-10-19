with source as (

    select *
    from {{ source('facebook', 'fb_accounts') }}

),

renamed as (

    select
        cast(account_id as string) as account_id,
        account_name,
        ad_currency_code as currency_code,
        cast(account_created_at as timestamp) as created_at,
        cast(account_updated_at as timestamp) as updated_at

    from source

)

select *
from renamed