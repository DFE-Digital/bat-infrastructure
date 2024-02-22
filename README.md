# BAT Infrastructure

Shared code and documentation for Becoming a teacher infrastructure.

* [CI/CD strategy](documentation/ci-cd-strategy.md)

## Fix Logit data
[Example script](scripts/fix-logit.py) to iterate across all indices and fix the data. Can be reused and adapted for other cases.

## Generate service principal secret
Use [the new_aad_app_secret script](scripts/new_aad_app_secret.sh) to generate Azure credentials on a service principal agains the current subscription.

## SQLPad
Contains terraform code to deploy [sqlpad](https://getsqlpad.com/).
