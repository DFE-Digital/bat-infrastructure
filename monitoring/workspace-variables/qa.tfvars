monitoring_space_name    = "bat-qa"
monitoring_instance_name = "bat-qa"
influxdb_service_plan    = "tiny-1_x"
alertmanager_app_names   = ["find-qa", "publish-teacher-training-qa", "teacher-training-api-qa", "register-qa", "apply-qa", "teacher-training-api-loadtest"]
postgres_services = [
  "bat-qa/apply-postgres-qa",
  "bat-qa/register-postgres-qa",
  "bat-qa/teacher-training-api-postgres-qa",
  "bat-qa/teacher-training-api-postgres-loadtest",
]
redis_services = [
  "bat-qa/apply-cache-redis-qa",
  "bat-qa/register-redis-cache-qa",
  "bat-qa/teacher-training-api-cache-redis-qa",
]
alertable_redis_services = [
  "bat-qa/apply-worker-redis-qa",
  "bat-qa/register-redis-worker-qa",
  "bat-qa/teacher-training-api-worker-redis-qa",
]
internal_apps = ["apply-qa.apps.internal"]
