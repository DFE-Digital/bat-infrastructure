#!/bin/bash
set -eu

# Application (client) ID of the app registration that needs a new secret
CLIENT_ID=${1:-}
# Description or friendly name for the secret
DISPLAY_NAME=${2:-}

if [[ -z "${CLIENT_ID}" ]]; then
  echo "CLIENT_ID Application (client) ID variable is not set"
  exit 1
fi

if [[ -z "${DISPLAY_NAME}" ]]; then
  echo "DISPLAY_NAME variable is not set"
  exit 1
fi

AZ_ACCOUNT="$(az account show)"

if [[ -z "${AZ_ACCOUNT:-}" ]]; then
  echo "AZ_ACCOUNT variable not set from 'az account show'"
  exit 1
fi

SUBSCRIPTION_ID="$(echo $AZ_ACCOUNT | jq -r .id)"
TENANT_ID="$(echo $AZ_ACCOUNT | jq -r .tenantId)"
CLIENT_SECRET="$(az ad app credential reset --id ${CLIENT_ID} --append --display-name ${DISPLAY_NAME} --only-show-errors | jq -r .password)"

AZURE_CREDENTIALS='
{
  "clientId": "'$CLIENT_ID'",
  "clientSecret": "'$CLIENT_SECRET'",
  "subscriptionId": "'$SUBSCRIPTION_ID'",
  "tenantId": "'$TENANT_ID'"
}'

echo $AZURE_CREDENTIALS | jq .
