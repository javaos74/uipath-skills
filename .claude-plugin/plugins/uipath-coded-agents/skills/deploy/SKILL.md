---
description: Deploy your UiPath agent to UiPath Cloud Platform
allowed-tools: Bash, Read, Glob, AskUserQuestion
---

# Deploy UiPath Agent

I'll help you deploy your UiPath agent to UiPath Cloud Platform with a complete, automated deployment workflow including pre-checks, packaging, publishing, and validation.

## What This Skill Does

- ✅ Pre-deployment checks (lint, format, type check, tests)
- 📦 Package agent (`uipath pack`)
- 🚀 Publish to UiPath Cloud (`uipath publish`)
- 🔍 Validate deployment
- 🧪 Run smoke test
- 📋 Provide invocation commands and URLs

## Prerequisites

- UiPath agent with `main.py` and `entry-points.json`
- Valid `uipath.json` project configuration
- UiPath authentication configured (use `/uipath-coded-agents:auth`)
- All dependencies in `pyproject.toml`

If not authenticated, I'll guide you through authentication first.

## Deployment Environments

UiPath supports multiple deployment targets:

- **🌍 Cloud (Production)** - `--cloud` - Production UiPath Automation Cloud
- **🧪 Staging** - `--staging` - Staging environment for testing
- **🔬 Alpha** - `--alpha` - Alpha environment for development

## Workflow

### Step 0: Authentication Check

I'll verify you're authenticated with UiPath:

```bash
uv run uipath auth --check
```

If not authenticated, I'll run:
```bash
uv run uipath auth --alpha  # or --staging, --cloud
```

### Step 1: Pre-Deployment Checks

Before deploying, I'll run quality checks:

#### Code Quality
```bash
# Format check
uv run ruff format --check .

# Lint check
uv run ruff check .

# Type check (if mypy configured)
uv run mypy src/ --ignore-missing-imports
```

#### Schema Validation
```bash
# Ensure schemas are up to date
uv run uipath init --no-agents-md-override

# Verify entry-points.json is valid
```

#### Tests (Optional but Recommended)
```bash
# Run unit tests if they exist
pytest tests/ --tb=short

# Run evaluations if they exist
uv run uipath eval
```

**If any check fails**, I'll:
- Show the error
- Suggest fixes
- Ask if you want to continue anyway

### Step 2: Version Check

I'll check your `uipath.json` for version information:

```json
{
  "name": "my-agent",
  "version": "1.0.0",
  "description": "My UiPath agent"
}
```

If version is missing, I'll suggest adding one.

### Step 3: Package Agent

I'll create a deployment package:

```bash
uv run uipath pack
```

This creates:
```
dist/
└── my-agent-1.0.0.uip
```

The `.uip` file contains:
- Agent code (`main.py`)
- Entry points (`entry-points.json`)
- Project metadata (`uipath.json`)
- Dependencies (`pyproject.toml`)

### Step 4: Publish to UiPath

I'll publish the agent to your UiPath workspace:

```bash
uv run uipath publish
```

**Publishing process:**
1. Uploads package to UiPath Cloud
2. Registers agent in your workspace
3. Makes agent available for invocation
4. Generates agent URL

**Output example:**
```
✅ Agent published successfully!

Agent Details:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name:         my-agent
Version:      1.0.0
Package:      my-agent-1.0.0.uip
Workspace:    my-workspace
Folder:       Shared
Status:       Published
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent URL:
https://cloud.uipath.com/my-org/my-workspace/agents/my-agent
```

### Step 5: Deployment Validation

I'll verify the deployment was successful:

```bash
# List published agents to confirm
uv run uipath list agents

# Check agent is accessible
uv run uipath invoke my-agent --dry-run
```

### Step 6: Smoke Test (Optional)

If you want, I'll run a smoke test with sample input:

```bash
# Invoke agent with test data
uv run uipath invoke my-agent '{
  "message": "deployment test",
  "timestamp": "2024-02-19T10:00:00Z"
}'
```

**Smoke test verifies:**
- Agent is invocable
- Input schema is correct
- Agent executes without errors
- Output schema is valid

### Step 7: Provide Next Steps

After deployment, I'll show you how to use your agent:

```
🎉 Deployment Complete!

Invoke your agent:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Via CLI:
uv run uipath invoke my-agent '{"message": "hello"}'

Via API:
POST https://cloud.uipath.com/my-org/my-workspace/agents/my-agent/invoke
Content-Type: application/json

{
  "input": {"message": "hello"}
}

Via Orchestrator:
1. Go to Automation Cloud → Agents
2. Find "my-agent"
3. Click "Invoke" button
4. Enter input JSON
5. View results

Monitor your agent:
- View executions: https://cloud.uipath.com/.../agents/my-agent/executions
- Check logs: https://cloud.uipath.com/.../agents/my-agent/logs
- View traces: Orchestrator → Jobs → Trace tab
```

## Deployment Options

### Quick Deploy (Skip Checks)

If you're confident everything is ready:

```
/uipath-coded-agents:deploy --skip-checks
```

Skips pre-deployment validation and goes straight to packaging.

### Deploy to Specific Environment

```
/uipath-coded-agents:deploy --environment staging
/uipath-coded-agents:deploy --environment alpha
/uipath-coded-agents:deploy --environment cloud
```

### Deploy with Smoke Test

```
/uipath-coded-agents:deploy --smoke-test
```

Runs a test invocation after deployment to verify it works.

### Verbose Mode

```
/uipath-coded-agents:deploy --verbose
```

Shows detailed output for each step.

## Common Deployment Scenarios

### First-Time Deployment

For your first deployment:
1. ✅ Ensure all tests pass
2. ✅ Run full pre-deployment checks
3. ✅ Deploy to alpha/staging first
4. ✅ Run smoke test
5. ✅ Verify in Orchestrator
6. ✅ Then deploy to production

### Update Existing Agent

To update an already-deployed agent:
1. ✅ Update version in `uipath.json`
2. ✅ Run evaluations to ensure no regressions
3. ✅ Deploy with `--skip-checks` if you're confident
4. ✅ Smoke test to verify update

### Rollback

If deployment fails or has issues:
```bash
# Republish previous version
uv run uipath publish --package dist/my-agent-0.9.0.uip
```

Keep previous `.uip` files in `dist/` for easy rollback.

## Pre-Deployment Checklist

Before deploying, ensure:

- [ ] All code changes committed to git
- [ ] Tests pass (`pytest tests/`)
- [ ] Evaluations pass (`uipath eval`)
- [ ] No linting errors (`ruff check .`)
- [ ] Schemas up to date (`uipath init`)
- [ ] Version bumped in `uipath.json`
- [ ] Bindings configured correctly
- [ ] Authentication is valid
- [ ] Deployment target is correct

## Deployment Files

These files are included in deployment:

```
my-agent-1.0.0.uip
├── main.py                 # Agent code
├── entry-points.json       # Entry point schemas
├── uipath.json            # Project metadata
├── pyproject.toml         # Dependencies
├── bindings.json          # Resource bindings
└── .agent/                # SDK and CLI reference (optional)
```

## Versioning Best Practices

Use semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** (1.0.0 → 2.0.0) - Breaking changes, incompatible API changes
- **MINOR** (1.0.0 → 1.1.0) - New features, backwards compatible
- **PATCH** (1.0.0 → 1.0.1) - Bug fixes, backwards compatible

Update version in `uipath.json`:
```json
{
  "name": "my-agent",
  "version": "1.1.0",
  "description": "Added queue processing capability"
}
```

## Monitoring Deployed Agents

After deployment, monitor your agent:

### View Executions
```bash
# List recent executions
uv run uipath list executions --agent my-agent --limit 10

# Get execution details
uv run uipath get execution <execution-id>
```

### Check Logs
```bash
# Get logs for failed executions
uv run uipath logs <execution-id>
```

### View Metrics
- Go to Orchestrator → Agents → [Your Agent]
- View execution count, success rate, average duration
- Monitor errors and failures

## Troubleshooting

### Authentication Errors

```
Error: Not authenticated with UiPath
```

**Fix:**
```bash
uv run uipath auth --alpha  # or --staging, --cloud
```

### Package Build Fails

```
Error: entry-points.json not found
```

**Fix:**
```bash
uv run uipath init --no-agents-md-override
```

### Publish Fails - Invalid Schema

```
Error: Input schema validation failed
```

**Fix:**
1. Check Input/Output models match entry-points.json
2. Run `uipath init` to regenerate schemas
3. Test locally with `uipath run main`

### Smoke Test Fails

```
Error: Agent invocation failed
```

**Fix:**
1. Check bindings are configured in Orchestrator
2. Verify input JSON matches schema
3. Check agent logs for errors
4. Test locally first with `uipath run main`

### Version Conflict

```
Error: Agent version 1.0.0 already exists
```

**Fix:**
1. Bump version in `uipath.json`
2. Rebuild package with `uipath pack`
3. Publish again

## Deployment to Different Environments

### Alpha Environment (Development)

```bash
# Authenticate to alpha
uv run uipath auth --alpha

# Deploy
uv run uipath publish
```

Use for:
- Development and testing
- Experimental features
- Breaking changes

### Staging Environment (Pre-Production)

```bash
# Authenticate to staging
uv run uipath auth --staging

# Deploy
uv run uipath publish
```

Use for:
- Final testing before production
- User acceptance testing
- Performance testing

### Cloud Environment (Production)

```bash
# Authenticate to cloud
uv run uipath auth --cloud

# Deploy
uv run uipath publish
```

Use for:
- Production workloads
- Stable, tested agents
- Customer-facing agents

## CI/CD Integration

This skill can be used in CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Deploy Agent

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.12'
      - name: Install uv
        run: curl -LsSf https://astral.sh/uv/install.sh | sh
      - name: Authenticate
        run: |
          uv run uipath auth \
            --client-id ${{ secrets.UIPATH_CLIENT_ID }} \
            --client-secret ${{ secrets.UIPATH_CLIENT_SECRET }} \
            --base-url ${{ secrets.UIPATH_BASE_URL }}
      - name: Deploy
        run: uv run uipath deploy
```

## Security Considerations

### Credentials

- ✅ Never commit credentials to git
- ✅ Use environment variables or secrets
- ✅ Rotate credentials regularly
- ✅ Use least-privilege access

### Bindings

- ✅ Configure bindings in Orchestrator, not in code
- ✅ Use folder-level permissions
- ✅ Validate resource access after deployment

### Dependencies

- ✅ Review dependencies before deploying
- ✅ Keep dependencies up to date
- ✅ Use dependency scanning tools

## Best Practices

✅ **Do:**
- Test thoroughly before deploying to production
- Use semantic versioning
- Deploy to alpha/staging first
- Keep deployment packages for rollback
- Monitor agent performance post-deployment
- Document deployment process

❌ **Don't:**
- Deploy directly to production without testing
- Skip pre-deployment checks
- Forget to update version numbers
- Ignore test failures
- Deploy with uncommitted changes

## Integration with Other Skills

This skill works well with:
- `/uipath-coded-agents:create-agent` - Create agent to deploy
- `/uipath-coded-agents:eval` - Run evaluations before deploying
- `/uipath-coded-agents:run` - Test locally before deploying
- `/uipath-coded-agents:auth` - Authenticate before deploying

## Let's Deploy Your Agent!

Ready to deploy? I'll guide you through the complete deployment process with:
1. Pre-deployment checks
2. Packaging
3. Publishing
4. Validation
5. Smoke testing (optional)

**Tell me:**
- Which environment? (alpha/staging/cloud)
- Skip pre-checks? (if you're confident)
- Run smoke test? (recommended for first deployment)

**Example prompts:**
- "Deploy my agent to alpha"
- "Deploy to staging with smoke test"
- "Deploy to production, skip checks"
