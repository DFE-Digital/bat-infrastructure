monitoring_space_name    = "bat-qa"
monitoring_instance_name = "bat-qa"
influxdb_service_plan    = "tiny-1_x"
alertmanager_app_names   = ["find-qa", "publish-teacher-training-qa", "teacher-training-api-qa", "register-qa", "apply-qa"]
postgres_services = [
  "bat-qa/apply-postgres-qa",
  "bat-qa/register-postgres-qa",
  "bat-qa/teacher-training-api-postgres-qa",
]
redis_services = [
  "bat-qa/apply-redis-qa",
  "bat-qa/register-redis-cache-qa",
  "bat-qa/register-redis-worker-qa",
  "bat-qa/teacher-training-api-redis-qa",
]
internal_apps = ["apply-qa.apps.internal"]
