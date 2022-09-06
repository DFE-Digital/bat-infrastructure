# SQLPad

We need a mechanism for business analysts and other non-technical users to be able to access the data and generate reports.
Previously this was done by running pgAdmin on their local machines and connecting to the Azure database.

PaaS doesn't allow connection to its database services from outside its network by default and requiring these users to use `cf conduit` is not a viable solution.

--------------

[SQLPad](https://sqlpad.github.io/sqlpad/#/) provides a web interface for connecting and querying Postgres and other popular databases.

### Installation
The terraform config deploys [sqlpad's docker image](https://hub.docker.com/r/sqlpad/sqlpad/) into a PaaS space along side other bat applications.

Deploy using the Makefile

make $env sqlpad-plan/sqlpad-apply

Currently the only valid env is prod. The old sqlpad app in bat-qa can't be updated using make at the moment. This is because;
- the qa statefile is currently missing so it will need to be imported.
- the connections file doesn't exist so this would need to be created or details kept before make.

### User configuration
Google sign-on has been configured for the application and only users invited by the admin (`SQLPAD_ADMIN`) will be able to login.


### Required terraform variables

#### SQLPAD_ADMIN

`var.sqlpad_admin` - Email address for the initial admin user, once logged in additional users can be configured.

`sqlpad_admin_password` - in az keyvault

#### Google SSO (az keyvault)
`sqlpad_google_client_id` - Google Client Id for SSO

`sqlpad_google_client_secret` - Google Client Secret for SSO

These are generated in the Google Cloud 'Becoming a Teacher' project

#### Postgres connection details

For prod, connections are only created by the admin after the initial app build.
For qa, see below

`var.connections` -
A json array of the postgres connection details in this [specification](https://sqlpad.github.io/sqlpad/#/connections?id=postgresql-postgres)
It is recommended to use the credentials from a read-only service-key for the required database services.
```json
[{
  "id": "connectionid",
  "name": "Connection Name",
  "driver": "postgres",
  "multiStatementTransactionEnabled": true,
  "host": "<hostname>.eu-west-2.rds.amazonaws.com",
  "port": 5432,
  "database": "<database>",
  "username": "<username>",
  "password": "<password>",
  "postgresSsl": true,
  "postgresSslSelfSigned": true
}]
```
The above json array will be transformed into environment variables in the below format ([see](https://sqlpad.github.io/sqlpad/#/connections?id=defining-connections-via-configuration)).
```
SQLPAD_CONNECTIONS__{connectionid}__{key} = {value}
```
