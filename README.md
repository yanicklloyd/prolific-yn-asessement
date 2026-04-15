# Global Transactions Assessment

## Overview

This dbt project is designed to process and analyze transaction data for a global marketplace platform. The project handles various transaction types, currency conversions, and revenue recognition rules.

## Project Structure

- `seeds/`: Contains raw CSV data files
  - `transactions.csv`: All platform transactions
  - `client_contracts.csv`: Client discount agreements
  - `currency_rates.csv`: Daily currency exchange rates
  - `transaction_resolutions.csv`: Chargeback resolution statuses
  - `date_mappings.csv`: A date mapping file

- `models/`: Contains all dbt models
  - `staging/`: Initial data cleaning and standardisation
  - `intermediate/`: Complex calculations and business logic
  - `marts/`: Final layer for reporting

## Target configuration

This project writes to a SQLite database in the target directory. You will need to install the dbt-sqlite adapter to run it.

## Profiles & Schemas

The `profiles.yml` file is set up to use the database file in the project root, as this contains the source data.
This has been moved from the `.db` file in the `target` folder, which is now included in `.gitignore`.
The `stg`, `int`, and `mart` folders use the same schema due to the way SQLite handles schemas. This keeps all models in the same database file and reduces the number of `.db` files that would otherwise be created for each schema and makes testing easier

```yaml
global_transactions:
  target: dev
  outputs:
    dev:
      type: sqlite
      threads: 1
      database: 'database'
      schema: 'main'
      schema_directory: '.'
      schemas_and_paths:
        main: 'global_transactions.db'
```

## Staging

Staging data is ingested from the database as a source rather than directly from the seed files, which was the initial project setup.

## Assumptions

- Contract thresholds are based on gross payment volume and do not subtract refunds or fraud. This avoids threshold status changing erratically over the course of a month and keeps the threshold logic easier to explain.
- Discount pricing applies from the date the payment transaction that breaches the threshold is recognised
- GMV is calculated using payment transactions only and does not subtract refunds, fraud, or chargebacks
- Pending chargebacks do not affect recognised revenue
- Resolved chargebacks affect recognised revenue in the resolution month rather than the original transaction month
- Refunds with a linked original transaction inherit the original transaction's fee treatment when calculating recognised revenue

## Revenue Definitions

- `GMV` (Gross Merchandise Value) is calculated using payment transactions only.
- `Revenue` is the amount collected by the platform. It starts from signed(+/-) transaction values in GBP and applies the relevant fee margin after contract and discount logic. Chargebacks are not recognised until they are resolved

## If I Had More Time / SQLite quirks
- lack of stable sqlfluff compatability
- make file for setup 
- even more testing




## Key Requirements

1. Handle multiple transaction types (payments, refunds, fraud, chargebacks)
2. Apply correct platform fee margins based on client contracts
3. Convert all amounts to GBP using daily exchange rates
4. Calculate monthly revenue recognising only resolved chargebacks

## Expected Output

The final mart model should provide monthly revenue recognition with:
- Revenue by client and month
- Total GMV in GBP
- Spend threshold tracking
- Discount application status
