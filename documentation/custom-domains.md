# BAT cdn-route

## QA
```=
qa.find-postgraduate-teacher-training.service.gov.uk,
qa.register-trainee-teachers.education.gov.uk,
qa.api.publish-teacher-training-courses.service.gov.uk,
qa.publish-teacher-training-courses.service.gov.uk
```

`CNAME => d1g6p51l52so6s.cloudfront.net`

Update command:
```shell
cf update-service bat-cdn-qa -c '{"domain": "qa.find-postgraduate-teacher-training.service.gov.uk,qa.register-trainee-teachers.education.gov.uk,qa.api.publish-teacher-training-courses.service.gov.uk,qa.publish-teacher-training-courses.service.gov.uk", "headers": ["Accept", "Authorization"]}'
```

## Staging
```=
staging.find-postgraduate-teacher-training.service.gov.uk,
staging.register-trainee-teachers.education.gov.uk,
staging.api.publish-teacher-training-courses.service.gov.uk,
staging.publish-teacher-training-courses.service.gov.uk
```

`CNAME => d2jkti130squc1.cloudfront.net`

Update command:
```shell
cf update-service bat-cdn-staging -c '{"domain": "staging.find-postgraduate-teacher-training.service.gov.uk,staging.register-trainee-teachers.education.gov.uk,staging.api.publish-teacher-training-courses.service.gov.uk,staging.publish-teacher-training-courses.service.gov.uk", "headers": ["Accept", "Authorization"]}'
```

## Prod
```=
www2.find-postgraduate-teacher-training.service.gov.uk,
www.find-postgraduate-teacher-training.service.gov.uk,
www.register-trainee-teachers.education.gov.uk
```

`CNAME => d3kffbwt0ldx12.cloudfront.net`

Update command:
```shell
cf update-service bat-cdn-prod -c '{"domain": "www2.find-postgraduate-teacher-training.service.gov.uk,www.find-postgraduate-teacher-training.service.gov.uk,www.register-trainee-teachers.education.gov.uk", "headers": ["Accept", "Authorization"]}'
```
