with transactions as (
    select * from {{ ref('stg_transactions') }}
),

currency_rates as (
    select * from {{ ref('stg_currency_rates') }}
),

transaction_resolutions as (
    select * from {{ ref('stg_transaction_resolutions') }}
),

date_mappings as (
    select * from {{ ref('date_mappings') }}
),

client_contracts as (
    select * from {{ ref('stg_client_contracts') }}
),

base_enriched as (
    select
        t.transaction_id,
        t.client_id,
        t.transaction_type,
        t.transaction_date,
        dmt.month_start_date as transaction_month,
        t.transaction_amount,
        t.platform_fee_margin,
        t.currency,
        t.linked_transaction_id,
        tr.resolution_status,
        tr.resolution_date,
        dmr.month_start_date as resolution_month,
        coalesce(cr.exchange_rate_to_gbp, 1.0) as exchange_rate_to_gbp, 
        t.transaction_amount * coalesce(cr.exchange_rate_to_gbp, 1.0) as transaction_amount_gbp,
        case when t.transaction_type = 'payment' then 1 else 0 end as is_payment,
        case when t.transaction_type = 'refund' then 1 else 0 end as is_refund,
        case when t.transaction_type = 'fraud' then 1 else 0 end as is_fraud,
        case when t.transaction_type = 'chargeback' then 1 else 0 end as is_chargeback,
        case
            when t.transaction_type = 'chargeback' and tr.resolution_status = 'resolved' then 1
            else 0
        end as is_chargeback_resolved,
        case
            when t.transaction_type = 'chargeback' and coalesce(tr.resolution_status, 'pending') != 'resolved' then 1
            else 0
        end as is_chargeback_pending,
        case
            when t.transaction_type = 'chargeback' and tr.resolution_status = 'resolved'
                then tr.resolution_date
            else t.transaction_date end as recognition_date, -- the date the transaction is settled chargebacks are settles using the resolution date 
        case
            when t.transaction_type = 'chargeback' and tr.resolution_status = 'resolved'
                then dmr.month_start_date
            else dmt.month_start_date end as recognition_month, -- the month the transaction is settled chargebacks are settles using the resolution date 
        case
            when t.transaction_type = 'payment' then t.transaction_amount * coalesce(cr.exchange_rate_to_gbp, 1.0)
            when t.transaction_type in ('refund', 'fraud') then -1 * t.transaction_amount * coalesce(cr.exchange_rate_to_gbp, 1.0)
            when t.transaction_type = 'chargeback' and tr.resolution_status = 'resolved' then -1 * t.transaction_amount * coalesce(cr.exchange_rate_to_gbp, 1.0)
            else 0 --chargebacks that are pending are treated as 0 
        end as net_transaction_amount_gbp

    from transactions t
    left join currency_rates cr
        on t.currency = cr.currency -- ensures currency conversion takes place only where and when needed
       and t.transaction_date = cr.rate_date
    left join transaction_resolutions tr
        on t.transaction_id = tr.transaction_id
    left join date_mappings dmt
        on t.transaction_date = dmt.calendar_date
    left join date_mappings dmr
        on tr.resolution_date = dmr.calendar_date
),

enriched_with_contracts as (
    select
        b.*,
        cc.contract_start_date,
        date(cc.contract_start_date, '+' || cc.contract_duration_months || ' months', '-1 day') as contract_end_date,
        cc.contract_duration_months,
        cc.spend_threshold,
        cc.discounted_fee_margin,
        case
            when cc.client_id is not null then 1
            else 0
        end as is_in_contract_period
    from base_enriched b
    left join client_contracts cc
        on b.client_id = cc.client_id
       and b.recognition_date >= cc.contract_start_date
       and b.recognition_date <= date(cc.contract_start_date, '+' || cc.contract_duration_months || ' months', '-1 day')
)

select *
from enriched_with_contracts


