with source as (
    select * from {{ source('sqlite_raw', 'currency_rates') }}
),

src_currency_rates as (
    select
        currency,
        date(rate_date) as rate_date,
        exchange_rate_to_gbp
    from source
)

select * from src_currency_rates
