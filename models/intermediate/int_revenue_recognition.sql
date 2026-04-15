with transactions_enriched as (
    select * from {{ ref('int_transactions_enriched') }}
),

contract_status as (
    select * from {{ ref('int_client_contract_status') }}
),

revenue_recognition as (
    select
        t.transaction_id,
        t.client_id,
        t.transaction_type,
        t.transaction_date,
        t.transaction_month,
        t.recognition_date,
        t.recognition_month,
        t.transaction_amount,
        t.transaction_amount_gbp,
        t.net_transaction_amount_gbp,
        t.currency,
        t.linked_transaction_id,
        t.resolution_status,
        t.resolution_date,
        t.is_payment,
        t.is_refund,
        t.is_fraud,
        t.is_chargeback,
        t.is_chargeback_resolved,
        t.is_chargeback_pending,
        t.contract_start_date,
        t.contract_end_date,
        t.spend_threshold,
        cs.discounted_fee_margin,
        cs.cumulative_payment_gbp,
        coalesce(cs.spend_threshold_met, 0) as spend_threshold_met,
        case
            when coalesce(cs.spend_threshold_met, 0) = 1 then cs.discounted_fee_margin
            else t.platform_fee_margin
        end as fee_margin,
        t.net_transaction_amount_gbp * (
            case
                when coalesce(cs.spend_threshold_met, 0) = 1 then cs.discounted_fee_margin
                else t.platform_fee_margin
            end
        ) as revenue_gbp -- this is correct net of all negative transactions except pending chargebacks
    from transactions_enriched t
    left join contract_status cs
        on t.transaction_id = cs.transaction_id
)

select * from revenue_recognition
