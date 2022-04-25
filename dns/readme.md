# DNS

Terraform code for managing Azure DNS Zones and records.

This is separated into two components

- zones
- records

This is becuase a zone will be created initially and then is unlikely to have changes made to it,
while records will be added or changed more frequently.

# Zones

There is one zone per service e.g. register, etc

To create a new zone;

- Add json files

    - dns/zones/workspace_variables/${zone}-zone.tfvars.json
    - dns/zones/workspace_variables/backend_${zone}.tfvars

- Add the zone to the Makefile

- Create the containers in the storage account

    - ${zone}-dns-zone-tfstate

- Run the make command (there is no workflow job for zone creation or update)

    - make ${zone} dnszone-plan
    - make ${zone} dnszone-apply

- Provide the NS records for delegation from service.gov.uk

    - see https://www.gov.uk/service-manual/technology/get-a-domain-name#choose-where-youll-host-your-dns

Notes;

- Any zone updates would be made by making changes to the tfvars json file and running a "make ${zone} plan/apply"

Taking care that if this causes a zone creation the NS records may change and/or existing records may be deleted

- Our DNS zones have extra txt and caa records to protect against spoofing and invalid certificates, as per

    - see https://www.gov.uk/guidance/protect-domains-that-dont-send-email
    - see https://www.gov.uk/service-manual/technology/get-a-domain-name#set-up-security-certificates

So we add the following 3 records to indicate we don't send mail from these domains, and use Amazon for certificates.

- TXT record (for SPF)
```
“v=spf1 -all”
```

- TXT record (for DMARC)
```
"v=DMARC1; p=reject; sp=reject; rua=mailto:dmarc-rua@dmarc.service.gov.uk; ruf=mailto:dmarc-ruf@dmarc.service.gov.uk"
```

- CAA record
```
0 issue "amazon.com"
```

# Records

There is a json configuration file per env per service e.g. register-qa, register-staging, etc

To create (or update) records to an existing zone

- Add (or update) a json file to

    - dns/records/workspace_variables/${zone}-${env}.tfvars.json
    - dns/records/workspace_variables/backend_${zone}-${env}.tfvars (only on initial creation)

- Create the containers in the storage account (only on initial creation)

    - ${zone}-${env}-dns-tfstate

- Run the make command with DNS_ENV set to the environment you are adding records too

    - make ${zone} dnsrecord-plan DNS_ENV=${env}
    - make ${zone} dnsrecord-apply DNS_ENV=$env}
        - e.g. make register dnsrecord-plan DNS_ENV=qa

Note;
- You should always check any changes via terraform plan before applying to make sure you are not making unintended changes.
