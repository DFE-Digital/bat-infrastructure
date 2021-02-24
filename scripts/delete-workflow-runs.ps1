#!/usr/bin/env pwsh

$repo     = "DFE-Digital/<REPO-NAME>";
$apiToken = "<YOUR-API-TOKEN-HERE>";
$workflow = "<WORKFLOW-NAME>.yml";

$getWorkflowRuns = "https://api.github.com/repos/$repo/actions/workflows/$workflow/runs";

$deleteWorkflowRun = "https://api.github.com/repos/$repo/actions/runs";

$headers = @{
  Authorization = "Bearer $apiToken"
  Accept = "application/vnd.github.v3+json"
}

#Get all workflow runs
$getWorkflowRunsResponse = Invoke-RestMethod $getWorkflowRuns -Headers $headers;

# Delete all workflow runs, this will delete the workflow when all runs are deleted
$getWorkflowRunsResponse.workflow_runs.foreach{
  Invoke-RestMethod "$deleteWorkflowRun/$($_.id)" -Method Delete -Headers $headers;
}
