# CLI Commands Reference

Use `--output json` on all `uip` commands when parsing output.

## Agent Commands

### `uip lowcodeagents init`

Scaffold a new agent project inside a solution directory.

```bash
uip lowcodeagents init "<AGENT_NAME>" --output json
```

Run from the solution directory. Creates agent.json, entry-points.json, project.uiproj, and default eval/feature/resource directories.

### `uip lowcodeagents validate`

Validate agent project structure and schemas.

```bash
uip lowcodeagents validate --output json
```

Run from the agent project directory. Checks schema validity and consistency between agent.json and entry-points.json. Run after every change.

## Solution Commands

### Create Solution

```bash
uip solution new "<SOLUTION_NAME>" --output json
```

### Register Agent with Solution

```bash
uip solution project add --project-path "<AGENT_PROJECT_DIR>" --output json
```

Run from the solution directory.

### Bundle and Upload to Studio Web

```bash
uip solution bundle --output json
uip solution upload --output json
```

Run from the solution directory. Bundle first, then upload. Requires login.

## Authentication

```bash
uip login --output json          # Interactive OAuth login
uip login status --output json   # Check current auth state
```

## Quick Reference

| Task | Command | Run From |
|------|---------|----------|
| Create solution | `uip solution new "<NAME>" --output json` | Any directory |
| Scaffold agent | `uip lowcodeagents init "<NAME>" --output json` | Solution directory |
| Register project | `uip solution project add --project-path "<PATH>" --output json` | Solution directory |
| Validate | `uip lowcodeagents validate --output json` | Agent project directory |
| Bundle | `uip solution bundle --output json` | Solution directory |
| Upload | `uip solution upload --output json` | Solution directory |
