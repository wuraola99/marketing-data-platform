with adgroups as (

    select *
    from {{ ref('stg_snapchat__adgroups') }}

),

ranked as (

    select
        ad_group_record_id,
        ad_group_id,
        campaign_id,
        ad_group_name,
        updated_at,

        row_number() over (
            partition by ad_group_id
            order by updated_at desc, ad_group_record_id desc
        ) as row_num

    from adgroups

),

latest as (

    select
        ad_group_id,
        campaign_id,
        ad_group_name,
        updated_at

    from ranked

    where row_num = 1

)

select *
from latest