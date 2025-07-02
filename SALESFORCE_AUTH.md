# Salesforce Authentication Setup

This document explains how to authenticate to your Salesforce orgs using the provided `setup_codex.sh` script. The script relies on SFDX (Salesforce CLI) and expects authentication URLs for both the sandbox and production environments.

## Auth URLs

The script uses pre-generated SFDX URLs. They can be supplied via environment variables or fall back to the values hardcoded below:

```bash
# --- SALESFORCE AUTH URLs (env-aware with hardcoded fallback) ---
SANDBOX_URL="force://PlatformCLI::5Aep861zRbUp4Wf7BvabiXhQlm_zj7s.I.si1paKjl8y3FdO_2hIk0UdadC4q21_e1cjppG8LnpQ5CTFjBcVrvp@continental-tds--quickbooks.sandbox.my.salesforce.com"
PROD_URL="force://PlatformCLI::5Aep861GVKZbP2w6VNEk7JfTpn8a.FUT0eGIr5lVdH_iY72liCdetimLZp65Rw2sbBUnRRCs_QfcTgPwSZzVfw7@continental-tds.my.salesforce.com"
```

If you have your own auth URLs, export them before running the script:

```bash
export SANDBOX_URL="force://...@my-sandbox.my.salesforce.com"
export PROD_URL="force://...@my-prod.my.salesforce.com"
```

## Configuration Flags

The script also exposes several configurable variables:

```bash
SANDBOX_ALIAS="QuickBooksSandbox"
PROD_ALIAS="ProductionOrg"
MODE="${1:-validate}"  # validate | deploy
ENV="${2:-sandbox}"    # sandbox | production
SOURCE_PATH="force-app/main/default"
MAX_RETRIES=3
```

- **SANDBOX_ALIAS** and **PROD_ALIAS** are the org aliases used by SFDX.
- **MODE** controls whether the script performs a validation-only deployment or a full deploy.
- **ENV** selects which org to target (sandbox or production).
- **SOURCE_PATH** is the root folder of the metadata to deploy.
- **MAX_RETRIES** is how many times the deployment will retry on failure.

## Running the Script

Ensure you have the Salesforce CLI installed and logged in. Then execute:

```bash
./setup_codex.sh [validate|deploy] [sandbox|production]
```

This will authenticate using the provided URLs, list the connected orgs, and either validate or deploy your metadata depending on the mode chosen.

