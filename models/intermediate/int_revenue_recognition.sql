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
        t.discounted_fee_margin,
        t.platform_fee_margin,
        cs.cumulative_payment_gbp,
        cs.spend_threshold,
        t.original_platform_fee_margin,
        t.original_discounted_fee_margin,
        coalesce(cs.spend_threshold_met, 0) as spend_threshold_met,
        --The following logic ensures that refunds are dealt with correctly when it comes to revenue of refunds they should have the same discount fee that was applied at purchase when being refunded
        --the below ensure that the refund is not dsicounted differently to original transaction
        case
            when t.is_refund = 1 and t.original_platform_fee_margin is not null then case 
                when coalesce(cs_original.spend_threshold_met, 0) = 1 then t.original_discounted_fee_margin else t.original_platform_fee_margin end 
            when coalesce(cs.spend_threshold_met, 0) = 1 then t.discounted_fee_margin else t.platform_fee_margin
        end as fee_margin,

        t.net_transaction_amount_gbp * (
            case
            when t.is_refund = 1 and t.original_platform_fee_margin is not null then case 
                when coalesce(cs_original.spend_threshold_met, 0) = 1 then t.original_discounted_fee_margin else t.original_platform_fee_margin end  
            when coalesce(cs.spend_threshold_met, 0) = 1 then t.discounted_fee_margin else t.platform_fee_margin
        end
        ) as revenue_gbp -- this is correct net of all negative transactions except pending chargebacks
    from transactions_enriched t
    left join contract_status cs
        on t.transaction_id = cs.transaction_id
    left join contract_status cs_original
        on t.linked_transaction_id = cs_original.transaction_id
)

select * from revenue_recognition
