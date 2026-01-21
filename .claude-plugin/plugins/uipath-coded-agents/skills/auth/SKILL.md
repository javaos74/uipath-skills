---
description: Authenticate with UiPath using uipath auth --alpha
allowed-tools: Bash, AskUserQuestion
---

# UiPath Authentication

I'll help you authenticate with UiPath using the UiPath Python CLI. Authentication is required to run agents and access UiPath Cloud Platform.

## Authentication Modes

The UiPath CLI supports two authentication modes:

### 🔓 Interactive Mode (Default - Recommended)
Opens a browser for OAuth authentication where you can select your tenant interactively.

```bash
uv run uipath auth --cloud         # Production environment
uv run uipath auth --staging       # Staging environment
uv run uipath auth --alpha         # Alpha environment
```

### 🔐 Unattended Mode (For Automation)
Uses client credentials flow for automated authentication without user interaction.

```bash
uv run uipath auth --client-id YOUR_CLIENT_ID \
                   --client-secret YOUR_CLIENT_SECRET \
                   --base-url YOUR_BASE_URL
```

## Prerequisites Check

First, verify the UiPath SDK is available:

```bash
uv run uipath --version
```

If this command fails, you need to set up your project first with `/uipath-coded-agents:create-agent`.

## Environment Setup

For **Automation Suite** (on-premise) deployments, set your instance URL:

```bash
export UIPATH_URL=https://your-instance-url
```

Or add to a `.env` file in your project directory.

## Additional Options

- **Force Re-authentication:** Use `-f` or `--force` to get a new token
- **Specify Tenant:** Use `--tenant TENANT_NAME` for a specific tenant
- **Custom Scopes:** Use `--scope "SCOPE1 SCOPE2"` (defaults to 'OR.Execution')

## Network Configuration

The CLI respects proxy settings via:
- `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` environment variables
- `REQUESTS_CA_BUNDLE` for custom CA certificates

## Running Authentication

I'll guide you through the authentication process. Choose your preferred authentication mode, and I'll handle the setup.

Please wait for the command to complete and respond to any prompts that appear.