{% test fx_rate_exists(model, currency_column, date_column) %}

with transactions as (
    select *
    from {{ model }}
),

currency_rates as (
    select *
    from {{ ref('stg_currency_rates') }}
),

missing_rates as (
    select
        t.{{ currency_column }} as currency,
        t.{{ date_column }} as transaction_date
    from transactions t
    left join currency_rates cr
        on t.{{ currency_column }} = cr.currency
       and t.{{ date_column }} = cr.rate_date
    where cr.currency is null
    and t.{{ currency_column }} != 'GBP' -- Excluding GBP it made the test too stingent and we only really care about non GBP transactions
)

select *
from missing_rates

{% endtest %}