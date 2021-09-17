# BAT Infrastructure

Shared code and documentation for Becoming a teacher infrastructure.

* [Monitoring](monitoring/readme.md)
* [CI/CD strategy](documentation/ci-cd-strategy.md)
* [GitHub Actions](actions/README.md)

## Check paas users
Only authorised users may have access to production spaces. The powershell script `check-users-in-space-developer-role.ps1` lists the users and
either report to Slack or automatically unsets their SpaceDeveloper role. A whitelist can be provided so required users like service accounts are not deleted.

List extra users:
```
% ./scripts/check-users-in-space-developer-role.ps1 -space <space_name> -slack_webhook <slack_webhook_url>
```

Delete extra users:
```
% ./scripts/check-users-in-space-developer-role.ps1 -space <space_name> -slack_webhook <slack_webhook_url> -unset true -whitelist <user_names_comma_separated_list>
```

## Fix Logit data
[Example script](scripts/fix-logit.py) to iterate across all indices and fix the data. Can be reused and adapted for other cases.
