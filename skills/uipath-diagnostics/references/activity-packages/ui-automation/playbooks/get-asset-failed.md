---
confidence: medium
---

# Get Asset Failed (Activity)

## Context

A **Get Asset** or **Get Robot Asset** activity in a UI automation workflow failed during execution, but the error is not the exact "asset does not exist" pattern. See [Get Asset — Asset Not Found](./get-asset-asset-not-found.md) for failures where the asset literally doesn't exist in Orchestrator.

### Activity Distinction

- **Get Asset** — retrieves an asset value from Orchestrator for the current robot/machine. Requires asset to exist and execution context to have permission and a valid value.
- **Get Robot Asset** — legacy activity, similar behavior to Get Asset but older execution model. Both failure patterns are covered here.

What this looks like:
- **Authentication errors:** `HttpRequestException (401)`, `UnauthorizedAccessException`, "You are not authenticated", "invalid token", "session expired"
- **Permission/folder errors:** `InvalidOperationException`, "does not have access", "folder not found", "permission denied"
- **Connectivity errors:** `HttpRequestException (timeout)`, `OperationCanceledException`, "Orchestrator unreachable", connection refused
- **Runtime errors:** `NullReferenceException` if asset reference is broken, `InvalidCastException` if asset value type mismatch
- Intermittent failures for the same process and asset across different job runs (suggests transient connectivity or session issues)
- Activity succeeds in local debug execution but fails in unattended jobs (suggests execution identity or token context difference)

What can cause it:
- Authentication token expired or session lost between job start and Get Asset execution
- Folder context mismatch — asset defined in different folder than process execution context
- Asset value configuration mismatch (global vs per-account/per-account-machine) for the execution identity
- Network/platform instability or transient Orchestrator connectivity issues during asset retrieval
- Robot account lacks permissions to access the asset in the current folder context
- Platform or package version changes affecting folder binding or execution context

What to look for:
- Exact error message and exception type from job traces (authentication, access, timeout, HTTP status code)
- Execution identity (robot account) and folder context where the job is running
- Asset definition location (which folder the asset is stored in) vs execution folder
- Asset value mode (global, per-account, per-account-machine) and whether the running account has a value
- Time clustering and correlation with deployments, package updates, or infrastructure changes
- Whether failures occur consistently across all machines or specific runtime machines

## Investigation

1. **Collect baseline failures:** Gather at least 3 failed executions and 2 successful executions for the same process. Compare error signatures, folder, robot account, and timestamps.

2. **Extract error details:** Isolate the exact error from traces. Search for keywords: `AssetException`, `HttpRequestException`, `UnauthorizedAccessException`, `InvalidOperationException`, `OperationCanceledException`. Document:
   - Full exception message and stack trace
   - HTTP status code if present (401, 403, 408, 500, 502, 503)
   - Timestamp of failure
   - Robot account and machine name from job metadata
   - Folder context from job logs or XAML variable
   - If error is "does not exist" or "not found", use [Get Asset — Asset Not Found](./get-asset-asset-not-found.md) playbook instead

3. **Verify folder context:** Confirm the folder where the job is running and verify the asset exists in that folder.
   - **Diagnostic query:** Search job traces for "Folder:" or "EnvironmentContext" to find the execution folder
   - **Manual check:** Log into Orchestrator → Assets → confirm the asset name exists in the same folder
   - **Cross-check:** Compare XAML activity `folder` parameter (if set) against the folder in Orchestrator where the job is deployed
   - **Permission validation:** Verify the robot account has read permission on the asset in that folder (Orchestrator → Folder Settings → Robot role)

4. **Verify execution identity:** Check that the robot account executing the job matches expectations.
   - **Diagnostic query:** In Orchestrator job details, check the "Robot" and "UserName" fields. Confirm they match expectations.
   - **Compare contexts:** Failed runs should use unattended robot account, successful runs should use the same account. If different, that explains the failure.
   - **Check robot status:** Orchestrator → Robots → find the robot account and confirm:
     - Status is "Available" not "Disabled" or "Unavailable"
     - Last connection time is recent (not stale)
   - **Verify folder access:** Orchestrator → Folder Settings → Roles → confirm the robot's role has at least "Asset Consumer" permission

5. **Verify asset configuration:** Confirm the Get Asset activity is targeting the correct asset and the execution context has a valid value.
   - **From XAML:** Open the workflow XAML and find the Get Asset activity. Extract the asset name from the `Name` field.
   - **In Orchestrator:** Navigate to Folder → Assets and find the asset by name. Check the "Type" and "Scope" columns.
   - **Check asset values:**
     - If scope is "Global": a global value should exist (should work for any robot/machine)
     - If scope is "Per Robot (Account)": verify the executing robot account has a value configured. Look at the asset → edit → "Per Robot" tab and confirm an entry exists for the robot account.
     - If scope is "Per Robot Per Machine": verify the specific machine where the job ran has a value. Check asset → "Per Robot Per Machine" tab for the account-machine pair.
   - **Test assignment:** Create a test job running on the same robot/machine and try Get Asset. If it succeeds, the asset is configured correctly; if not, add the missing value.

6. **Correlate with environment changes:** If failures are intermittent or newly started, check timestamps against:
   - **Diagnostic query:** Orchestrator → System Settings → Deployment History; check if an upgrade occurred near the failure timestamp
   - **NuGet changes:** Check if `UiPath.System.Activities` or orchestrator integration packages were updated recently
   - **Robot version:** On the robot machine, check `UiPathRobot.exe` version; if recently updated, version mismatch with Orchestrator could cause auth issues
   - **Network incidents:** Check if there were firewall, proxy, or connectivity changes between robot and Orchestrator
   - **Orchestrator connectivity:** Try connecting from the robot machine to Orchestrator URL manually (`curl https://<orchestrator-url>/api/v1/Assets`) to rule out network blockage

A complete root cause must explain all failed executions in scope. If one hypothesis explains only part of the failures, continue investigating the remaining categories.

## Resolution

- **If authentication/token issue:** re-establish robot authentication in Orchestrator and validate the robot account is active. Restart the job to get a fresh session token.

- **If folder context mismatch:** verify the job runs in the correct folder where the asset is defined. Update process settings or deployment folder if needed.

- **If robot account lacks permissions:** grant the robot account appropriate asset-read permissions in the target folder through Orchestrator role/folder settings.

- **If asset value missing for execution context:** add or update asset value configuration so the executing robot account (or account-machine pair) has a valid value. Test the assignment works for the specific robot and machine.

- **If intermittent connectivity/timeouts:** implement retry logic around the Get Asset activity with exponential backoff (retry 3 times with 2, 4, 8-second delays). Test network connectivity from the robot machine to Orchestrator (`ping`, `telnet`, DNS resolution) and increase Orchestrator availability before rerun.

- **If deployment or runtime regression:** align the package versions, NuGet bindings, and robot runtime versions with the last known good configuration.

### How to Add Retry Logic

Wrap the Get Asset activity in a Try-Catch with retry:

1. Create a sequence called "GetAssetWithRetry"
2. Set Int32 variable `retryCount = 0`
3. Add While loop: `retryCount < 3`
4. Inside While, add Try block containing:
   - Get Asset activity (your asset call)
   - Set `retryCount = 99` (to exit after success)
5. In Catch block:
   - Log error message
   - Delay(2000) — wait 2 seconds
   - Increment `retryCount`
5. If all retries fail, throw exception or handle gracefully

This ensures transient failures don't immediately fail the entire job.

---

## Related Playbooks

- **[Get Asset — Asset Not Found](./get-asset-asset-not-found.md)** — The asset does not exist in Orchestrator
- **[Selector Failure](./selector-failure.md)** — UI automation activity couldn't find target element
- **[Timeout Issue](./timeout-issue.md)** — Activity exceeded wait time (may include Get Asset timeouts)
- [UI Automation Overview](../overview.md) — General UI Automation context
