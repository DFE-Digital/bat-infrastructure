monitoring_space_name    = "bat-prod"
monitoring_instance_name = "bat"
influxdb_service_plan    = "medium-1_x"
alertmanager_app_names   = ["find-prod", "find-staging", "publish-teacher-training-prod", "publish-teacher-training-staging", "teacher-training-api-prod", "teacher-training-api-staging", "register-production", "register-staging", "apply-staging", "apply-prod"]
postgres_services = [
  "bat-staging/apply-postgres-staging",
  "bat-staging/register-postgres-staging",
  "bat-staging/teacher-training-api-postgres-staging",
  "bat-prod/apply-postgres-prod",
  "bat-prod/apply-postgres-sandbox",
  "bat-prod/apply-postgres-load-test",
  "bat-prod/register-postgres-production",
  "bat-prod/register-postgres-sandbox",
  "bat-prod/teacher-training-api-postgres-prod",
  "bat-prod/teacher-training-api-postgres-sandbox",
]
redis_services = [
  "bat-staging/register-redis-cache-staging",
  "bat-staging/teacher-training-api-cache-redis-staging",
  "bat-prod/apply-cache-redis-prod",
  "bat-prod/apply-cache-redis-sandbox",
  "bat-prod/apply-cache-redis-load-test",
  "bat-prod/register-redis-cache-production",
  "bat-prod/register-redis-cache-sandbox",
  "bat-prod/teacher-training-api-cache-redis-prod",
  "bat-prod/teacher-training-api-cache-redis-sandbox",
  "bat-prod/find-cache-redis-loadtest",
  "bat-prod/find-cache-redis-prod",
]
alertable_redis_services = [
  "bat-staging/apply-worker-redis-staging",
  "bat-staging/register-redis-worker-staging",
  "bat-staging/teacher-training-api-worker-redis-staging",
  "bat-prod/apply-worker-redis-prod",
  "bat-prod/apply-worker-redis-sandbox",
  "bat-prod/apply-worker-redis-load-test",
  "bat-prod/register-redis-worker-production",
  "bat-prod/register-redis-worker-sandbox",
  "bat-prod/teacher-training-api-worker-redis-prod",
  "bat-prod/teacher-training-api-worker-redis-sandbox",
  "bat-prod/find-worker-redis-loadtest",
  "bat-prod/find-worker-redis-prod",
]
internal_apps = ["apply-sandbox.apps.internal", "apply-prod.apps.internal", "apply-load-test.apps.internal", "apply-jmeter.apps.internal", "find-jmeter.apps.internal", "apply-vendor-jmeter.apps.internal", "apply-manage-jmeter.apps.internal"]
