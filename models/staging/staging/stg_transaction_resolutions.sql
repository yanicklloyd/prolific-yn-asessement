with source as (
    select * from {{ source('sqlite_raw', 'transaction_resolutions') }}
),

src_transaction_resolutions as (
    select
        transaction_id,
        lower(trim(resolution_status)) as resolution_status,
        case
            when nullif(trim(resolution_date), '') is null then null
            else date(
                substr(trim(resolution_date), 7, 4) || '-' ||
                substr(trim(resolution_date), 4, 2) || '-' ||
                substr(trim(resolution_date), 1, 2)
            )
        end as resolution_date
    from source
)

select * from src_transaction_resolutions
