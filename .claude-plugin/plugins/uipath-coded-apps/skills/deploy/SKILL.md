---
description: Use when the user asks to deploy uipath coded app. this will deploy the app to uipath platform
---

# Deployment Reference

## CLI Installation

```bash
npm install -g @uipath/uipath-ts-cli
```

If the above command fails, make sure `~/.npmrc` exists with a valid GitHub token set.

## Deploying to UiPath Cloud

**IMPORTANT: The UiPath CLI commands (`uipath auth`, `uipath register app`, `uipath deploy`) are interactive — they open a browser or prompt for input. The agent CANNOT run these commands. Instead, instruct the user to run the deployment script.**

### What to do when the user asks to deploy

1. **Ensure the app builds cleanly:**

```bash
cd <app-directory> && npm run build
```

If the build fails, fix the errors first.

2. **Copy the deploy script into the project** (so the user can run it from the project root):

```bash
cp <skill-base-dir>/scripts/deploy.sh <app-directory>/deploy.sh
```

3. **Tell the user to run the script themselves** in their terminal:

```
To deploy your app to UiPath Cloud, run this in your terminal:

  cd <app-directory>
  bash deploy.sh [environment]

Where [environment] is one of: cloud (default), alpha, staging.

The script will:
  1. Authenticate via browser OAuth
  2. Register your app interactively
  3. Build the app
  4. Create deployment config files
  5. Package and publish to Orchestrator
  6. Deploy and print the app URL
```

**Do NOT attempt to run `deploy.sh`, `uipath auth`, `uipath register app`, `uipath pack`, `uipath publish`, or `uipath deploy` yourself.** These commands require browser interaction or terminal prompts that the agent cannot handle.


## CI Environment Variables

| Variable | Description |
|----------|-------------|
| `UIPATH_BASE_URL` | UiPath base URL (default: `https://cloud.uipath.com`) |
| `UIPATH_ORG_ID` | Organization ID |
| `UIPATH_TENANT_ID` | Tenant ID |
| `UIPATH_ACCESS_TOKEN` | Bearer token for authentication |
| `UIPATH_PROJECT_ID` | WebApp project ID (alternative to CLI arg) |

## CLI Commands Reference

| Command | Description | Interactive? |
|---------|-------------|--------------|
| `uipath auth` | OAuth browser flow or client-credentials auth | Yes — opens browser |
| `uipath register app` | Register coded app, saves config to `.uipath/app.config.json` | Yes — prompts for input |
| `uipath pack <dist-path>` | Package built app as `.nupkg` (NuGet) | No |
| `uipath publish <nupkg-path>` | Upload `.nupkg` to Orchestrator | No |
| `uipath deploy` | Deploy/upgrade app, returns app URL | Yes — may prompt |
| `uipath push [project-id]` | Sync local build to Studio Web project (atomic file sync) | No |
