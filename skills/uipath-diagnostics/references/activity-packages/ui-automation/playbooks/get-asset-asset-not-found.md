---
confidence: high
---

# Get Asset — Asset Not Found

## Context

A Get Asset or Get Robot Asset activity in a UI automation workflow failed because the asset does not exist in Orchestrator, or exists in a different folder than the job execution context. This is a configuration/deployment error, distinct from auth/permission issues.

See [Get Asset Failed](./get-asset-failed.md) for authentication, permission, and connectivity failures.

### Activity Distinction

- **Get Asset** — retrieves an asset value from Orchestrator. Requires the asset to exist in the current folder.
- **Get Robot Asset** — legacy activity with same failure pattern.

## What This Looks Like

- **DirectoryNotFoundException** — "Asset `<asset_name>` was not found in folder `<folder_name>`"
- **ArgumentNullException** — typically indicates asset reference is null (asset not found before retrieval)
- **KeyNotFoundException** — asset lookup failed, not in dictionary
- Process fails consistently on all runs and all machines with the same asset name
- Activity succeeds in debug execution but fails in unattended job (asset exists in debug folder, not in process deployment folder)
- Error message explicitly contains asset name and folder

## What Can Cause It

- Asset name in Get Asset activity is misspelled or wrong
- Asset exists but in a different folder than where the process is uploaded
- Asset was deleted from Orchestrator or moved to another folder after workflow was created
- Asset reference in workflow XAML is broken or not set (empty name)
- Process deployed to wrong folder that doesn't contain the required assets
- Folder context mismatch — process runs in "Production" folder but asset only exists in "Development" folder

## Investigation

1. **Extract asset details from error:** From job traces, locate the Get Asset exception and document:
   - Exact asset name (case-sensitive)
   - Folder name from error message if present
   - Full exception message and type
   - Robot account and deployment folder from job metadata

2. **Verify asset in Orchestrator:** Log into Orchestrator \u2192 Assets:
   - Search for the asset name. Document: Does it exist? If yes, in which folder?
   - **If asset exists:** Compare its folder location against the folder in which the job is running (from job metadata or XAML)
   - **If asset does not exist:** Confirm it was never created, or check if it was deleted recently in audit logs

3. **Cross-reference XAML:** Open the workflow XAML and find the Get Asset activity:
   - Extract the asset name from the activity configuration. Compare against Orchestrator step 2.
   - If names don't match exactly (including case, spaces, special characters), that's the root cause
   - Check if asset name is hardcoded or stored in a variable. If variable, trace where it's set

4. **Verify deployment context:** Check where the process is deployed:
   - **Orchestrator Process details:** Folder field shows the deployment folder
   - **Compare to asset location:** Asset must exist in the same folder or a parent/shared folder (if folder-scoped assets are available)
   - **If mismatch:** The asset and process are in different folder hierarchies

5. **Check asset history:** If asset was recently working, check if it was deleted or moved:
   - Orchestrator \u2192 Audit Logs (if available) — search for asset name and look for delete/move events
   - Ask team if asset was intentionally removed or migrated
   - Check if there's a newer asset with a different name that should be used instead

## Resolution

**If asset name is misspelled:** Correct the asset name in the Get Asset activity XAML. Match the name exactly as it appears in Orchestrator (case-sensitive). Publish and redeploy the process.

**If asset doesn't exist in Orchestrator:** Create the asset:
1. Orchestrator \u2192 Assets \u2192 Create New Asset
2. Enter the asset name exactly as referenced in the workflow
3. Select Type (Text, Credential, Integer, etc.) and set its Scope (Global, Per Robot, Per Robot Per Machine)
4. If Per Robot: assign a value for the robot account running the process
5. If Per Robot Per Machine: assign a value for the specific machine
6. Save and run the process again

**If asset exists but in wrong folder:** Move or copy the asset to the correct folder:
1. **Option A — Move asset:** Orchestrator \u2192 Assets \u2192 find asset \u2192 Edit \u2192 Change folder assignment and save
2. **Option B — Copy asset:** Create a new asset with the same name in the target folder and copy its values
3. Alternatively, move or redeploy the process to the folder where the asset exists

**If deployment folder is wrong:** Redeploy the process to the correct folder:
1. Update process folder assignment in Orchestrator or in your deployment pipeline
2. Ensure the target folder contains all required assets
3. Redeploy and run the process again

**If asset was deleted:** Restore or recreate it:
1. Check process version history — was the asset used in an earlier version that worked?
2. If asset should not have been deleted, restore from backup (if available)
3. Otherwise, recreate the asset following step 2 in this resolution section

**If using variables for asset name:** Verify dynamic asset naming is correct:
1. Add logging before the Get Asset activity to print the asset name variable
2. Compare logged asset name against actual asset name in Orchestrator
3. If different, fix the logic that sets the asset name variable
4. Redeploy and test

## Diagnostic Example

### Scenario: Process runs in "Production" folder, asset is in "Development"

**Observation:**
- Job fails with: `DirectoryNotFoundException: Asset "DBPassword" was not found in folder "Production"`
- Asset "DBPassword" exists in Orchestrator under folder "Development"

**Root cause:** Process deployment folder is "Production", but asset is only defined in "Development"

**Resolution options:**
1. Move "DBPassword" asset to "Production" folder, or
2. Redeploy process to "Development" folder, or
3. Create a separate "DBPassword" asset in "Production" folder with the same value

Choose based on your folder isolation strategy and multi-environment setup.

---

## Related Playbooks

- **[Get Asset Failed](./get-asset-failed.md)** — Asset exists but authentication, permission, or connectivity issues prevent retrieval
- **[Selector Failure](./selector-failure.md)** — UI automation activity couldn't find target element
- [UI Automation Overview](../overview.md) — General UI Automation context
