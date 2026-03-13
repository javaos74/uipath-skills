# Phase 0: Environment Readiness

**Goal:** Ensure Studio Desktop is running, connected, and targeting the correct project before any other operations.

## Step 0.1: Establish Project Root

The `uipcli rpa` commands use `--project-dir` to target a specific project (defaults to current working directory). **If the current working directory is NOT the UiPath project root, all commands will fail or target the wrong project.**

```bash
# Check if project.json exists in the CWD
ls {cwd}/project.json
```

If the CWD is not the project root:
- Locate the project root by finding `project.json`: `Glob: pattern="**/project.json"`
- **Pass `--project-dir` explicitly** to every `uipcli rpa` command, or
- Ask the user where their project is located

Store the project root path and use it consistently as `{projectRoot}` throughout all subsequent operations.

## Step 0.2: Verify Studio is Running

```bash
uipcli rpa list-instances --format json
```

**If no instances are found or Studio is not running:**
```bash
uipcli rpa start-studio
```

**If Studio is running but the project is not open:**
```bash
uipcli rpa open-project --project-dir "{projectRoot}"
```

**If Studio IPC connection fails** (error messages about connection refused, timeout, or pipe not found):
1. Check if Studio Desktop is actually installed on the machine
2. Try `uipcli rpa start-studio` to launch a fresh instance
3. If Studio is running but IPC fails, the user may need to restart Studio
4. Inform the user and ask them to ensure Studio Desktop is open and responsive

## Step 0.3: Authentication (If Needed)

Some commands (IS connections, workflow examples, cloud features) require authentication:

```bash
uipcli login
```

If you encounter auth errors (401, 403, "not authenticated") during any phase, prompt the user to run `uipcli login` to authenticate against their UiPath Cloud tenant.
