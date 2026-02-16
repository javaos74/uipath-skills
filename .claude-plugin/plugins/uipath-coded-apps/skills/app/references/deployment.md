# Deployment Reference

## CLI Installation

```bash
npm install -g @uipath/uipath-ts-cli
```
if the above cmd failed, make sure ~/.npmrc exists with valid gh token set

## Deployment Workflow

### Interactive (local development)

```bash
# 1. Authenticate via browser OAuth
uipath auth

# 2. Register your app (creates .uipath/app.config.json)
uipath register app

# 3. Build the app
npm run build

# 4. Package the dist folder into a .nupkg
uipath pack dist

# 5. Publish the .nupkg to Orchestrator
uipath publish <path-to-nupkg>

# 6. Deploy to UiPath Cloud (returns the app URL)
uipath deploy
```

## Required Deployment Config Files

These files must exist in the build output directory (e.g., `dist/`). Run the prepare-deploy script to generate them:

```bash
npm run build
bash scripts/prepare-deploy.sh <project-id>
```

This creates three files in `dist/`:

- **operate.json** — App manifest with `projectId`, `contentType: "webapp"`, `main: "index.html"`
- **entry-points.json** — API entry points with an auto-generated `uniqueId`
- **bindings.json** — Resource bindings (empty by default)

The `<project-id>` comes from `uipath register app`.

## CI Environment Variables

| Variable | Description |
|----------|-------------|
| `UIPATH_BASE_URL` | UiPath base URL (default: `https://cloud.uipath.com`) |
| `UIPATH_ORG_ID` | Organization ID |
| `UIPATH_TENANT_ID` | Tenant ID |
| `UIPATH_ACCESS_TOKEN` | Bearer token for authentication |
| `UIPATH_PROJECT_ID` | WebApp project ID (alternative to CLI arg) |

## CLI Commands Reference

| Command | Description |
|---------|-------------|
| `uipath auth` | OAuth browser flow or client-credentials auth |
| `uipath register app` | Register coded app, saves config to `.uipath/app.config.json` |
| `uipath pack <dist-path>` | Package built app as `.nupkg` (NuGet) |
| `uipath publish <nupkg-path>` | Upload `.nupkg` to Orchestrator |
| `uipath deploy` | Deploy/upgrade app, returns app URL |
| `uipath push [project-id]` | Sync local build to Studio Web project (atomic file sync) |
