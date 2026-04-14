with client_contracts as (
    select * from {{ ref('stg_client_contracts') }}
),

transactions_enriched as (
    select * from {{ ref('int_transactions_enriched') }}
),

contract_payments as (
    select
        c.client_id,
        c.contract_start_date,
        date(c.contract_start_date, '+' || c.contract_duration_months || ' months', '-1 day') as contract_end_date,  --subytacting 1 day to make the end date inclusive
        c.contract_duration_months,
        c.spend_threshold,
        c.discounted_fee_margin,
        t.transaction_id,
        t.transaction_date,
        t.transaction_month,
        t.transaction_amount_gbp
    from client_contracts c
    left join transactions_enriched t
        on c.client_id = t.client_id
       and t.is_payment = 1 --only including positive payments to avoid eligability bouncing around
       and t.transaction_date >= c.contract_start_date
       and t.transaction_date <= date(c.contract_start_date, '+' || c.contract_duration_months || ' months', '-1 day')
),

contract_status as (
    select
        client_id,
        contract_start_date,
        contract_end_date,
        contract_duration_months,
        spend_threshold,
        discounted_fee_margin,
        transaction_id,
        transaction_date,
        transaction_month,
        transaction_amount_gbp as payment_amount_gbp,
        sum(coalesce(transaction_amount_gbp, 0)) over (partition by client_id order by transaction_date, transaction_id) as cumulative_payment_gbp,
        case
            when sum(coalesce(transaction_amount_gbp, 0)) over (partition by client_id order by transaction_date, transaction_id) >= spend_threshold then 1
            else 0
        end as spend_threshold_met
    from contract_payments
)

select * from contract_status
