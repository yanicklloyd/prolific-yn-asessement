with revenue_recognition as (
    select * from {{ ref('int_revenue_recognition') }}
),

monthly_revenue as (
    select
        client_id,
        recognition_month as revenue_month,
        round(sum(case when is_payment = 1 then transaction_amount_gbp else 0 end ), 2) as gmv_gbp,
        round(sum(revenue_gbp), 2) as recognised_revenue_gbp,
        round(sum(case when is_payment = 1 then transaction_amount_gbp else 0 end), 2) as gross_payment_gbp,
        round(sum(case when is_refund = 1 then transaction_amount_gbp else 0 end), 2) as gross_refund_gbp,
        round(sum(case when is_fraud = 1 then transaction_amount_gbp else 0 end), 2) as gross_fraud_gbp,
        round(sum(case when is_chargeback_resolved = 1 then transaction_amount_gbp else 0 end), 2) as gross_resolved_chargeback_gbp,
        max(coalesce(contract_start_date, null)) as contract_start_date,
        max(coalesce(contract_end_date, null)) as contract_end_date,
        max(spend_threshold_met) as spend_threshold_met,
        max(case when contract_start_date is not null then 1 else 0 end) as has_contract
    from revenue_recognition
    group by 1, 2
)

select
    client_id,
    revenue_month,
    gmv_gbp,
    recognised_revenue_gbp,
    gross_payment_gbp,
    gross_refund_gbp,
    gross_fraud_gbp,
    gross_resolved_chargeback_gbp,
    contract_start_date,
    contract_end_date,
    spend_threshold_met,
    case
        when spend_threshold_met = 1 then 'discount_applied'
        when has_contract = 1 then 'contract_active_no_discount'
        else 'no_contract'
    end as discount_application_status
from monthly_revenue
