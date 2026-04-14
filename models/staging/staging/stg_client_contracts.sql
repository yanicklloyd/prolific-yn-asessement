with source as (
    select * from {{ source('sqlite_raw', 'client_contracts') }}
),

src_client_contracts as (
    select
        client_id,
        date(contract_start_date) as contract_start_date,
        cast(contract_duration_months as integer) as contract_duration_months,
        cast(spend_threshold as integer) as spend_threshold,
        discounted_fee_margin
    from source
)

select * from src_client_contracts
