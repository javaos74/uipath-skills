# CLI Commands Reference

All `uip` commands that apply to low-code agent development. Use `--output json` on all native `uip` commands when parsing output programmatically.

## Agent Commands

### `uip lowcodeagents init`

Scaffold a new low-code agent project inside an existing solution directory.

```bash
uip lowcodeagents init "<AGENT_NAME>" --output json
```

Creates the full project structure: `agent.json`, `entry-points.json`, `project.uiproj`, `flow-layout.json`, `evals/` with default evaluators, empty `features/` and `resources/` directories.

Run this from inside the solution directory (the directory containing `solution.uiproj`).

### `uip lowcodeagents validate`

Validate agent project structure and schemas.

```bash
uip lowcodeagents validate --output json
```

Run from the agent project directory (the directory containing `agent.json`). Checks:
- agent.json schema validity
- entry-points.json schema validity
- Input/output schema consistency between agent.json and entry-points.json
- Feature and resource file structure
- Evaluation set validity

Run this after every change to catch errors early.

### `uip lowcodeagents models` (Planned)

List available model identifiers for the `settings.model` field. This command is not yet available. Common model identifiers from existing agents:

| Model | Identifier |
|-------|-----------|
| Claude Sonnet 4.6 | `anthropic.claude-sonnet-4-6` |
| GPT-5.2 | `gpt-5.2-2025-12-11` |
| GPT-4.1 | `gpt-4.1-2025-04-14` |
| GPT-4.1 Mini | `gpt-4.1-mini-2025-04-14` |

Check Studio Web for the current list of available models.

## Solution Commands

Low-code agent projects live inside solutions. Use solution commands for project lifecycle management.

### Create a Solution

```bash
uip solution new "<SOLUTION_NAME>" --output json
```

Creates a solution directory with `solution.uiproj`. Run this before `uip lowcodeagents init`.

### Register Agent Project with Solution

```bash
uip solution project add --project-path "<AGENT_PROJECT_DIR>" --output json
```

Run from the solution directory. Links the agent project to the solution so it can be bundled and published.

### Bundle for Studio Web

```bash
uip solution bundle --output json
```

Run from the solution directory. Creates a `.nupkg` package in the solution directory. This is the default publish path — bundle first, then upload.

### Upload to Studio Web

```bash
uip solution upload --output json
```

Run from the solution directory after bundling. Uploads the bundled solution to Studio Web. Requires login (`uip login`).

### Alternative: Pack for Orchestrator

Only use this path if the user explicitly asks to deploy to Orchestrator (not Studio Web):

```bash
uip solution pack --output json
uip solution publish --output json
```

## Authentication Commands

### Login

```bash
uip login --output json
```

Opens browser for interactive OAuth login. Required before `uip solution upload`.

### Check Login Status

```bash
uip login status --output json
```

Returns current authentication state. Check this before attempting cloud operations. If not logged in, prompt the user to run `uip login`.

## Global Options

| Option | Description |
|--------|-------------|
| `--output json` | Machine-readable JSON output. Use on all commands when parsing output. |
| `--help` | Show command help and available options. |

## Command Quick Reference

| Task | Command | Run From |
|------|---------|----------|
| Create solution | `uip solution new "<NAME>" --output json` | Any directory |
| Scaffold agent | `uip lowcodeagents init "<NAME>" --output json` | Solution directory |
| Register project | `uip solution project add --project-path "<PATH>" --output json` | Solution directory |
| Validate agent | `uip lowcodeagents validate --output json` | Agent project directory |
| Login | `uip login --output json` | Any directory |
| Check login | `uip login status --output json` | Any directory |
| Bundle solution | `uip solution bundle --output json` | Solution directory |
| Upload to Studio Web | `uip solution upload --output json` | Solution directory |
