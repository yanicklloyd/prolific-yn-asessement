# Global Transactions Assessment

## Overview

This dbt project is designed to process and analyze transaction data for a global marketplace platform. The project handles various transaction types, currency conversions, and revenue recognition rules.

## Project Structure

- `seeds/`: Contains raw CSV data files
  - `transactions.csv`: All platform transactions
  - `client_contracts.csv`: Client discount agreements
  - `currency_rates.csv`: Daily currency exchange rates
  - `transaction_resolutions.csv`: Chargeback resolution statuses
  - `date_mappings.csv` : A date mapping file 

- `models/`: Contains all dbt models
  - `staging/`: Initial data cleaning and standardisation
  - `intermediate/`: Complex calculations and business logic
  - `marts/`: Final layer for reporting

## Target configuration

This project writes to a SQLite database in the target directory. You will need to install the dbt-sqlite adapter to run it.

# Profiles & Schemas
The profiles yaml is set up to use the database file in the root as this contained the source data
this has been moved from the .db file in the target folder which is now included in the .gitignore
The various folders stg/int/mart use the same schema due to quirky way SQlite works with schemas so all models like in the same database and schema to reduce the number of .db files created as they would have been create for each schema

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

# staging
staging data is being ingested from the database as a source not the seed files as initially set up

# Contract thresholds:
 use gross payments and ignore refunds and fraud this is avoid erratic movement in thresholds being met over the course of a month and make communication clearer and transparent

# Discount 
pricing effective from: discount pricing applies from the date payment of transaction that breaches the threshold has been recognised

# GMV Gross Merchandise Value
Is calculated using only payment transactions and ignoring refunds fraud and chargebacks

# Revenue
Revenue is the amount collected by the platform it takes payment values and subtracts fraud, refunds and chargbacks that have been resolved this figure if then multiplies by the relevant plaform fee for the specific client 

### to do 
Things that I would do had I had more time
- The final mart has null contract columns because the int_contract model only includes payment transactions I would split this out into two models one for contract info and one for threshold calcs
- more extensive descriptions and yml for dbt docs and discoverabiliuty 



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
