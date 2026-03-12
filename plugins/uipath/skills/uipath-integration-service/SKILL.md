---
name: uipath-integration-service
description: Interact with external services through UiPath Integration Service. Manages connectors, connections, activities, and resources via the CLI. Use when the user says "connect to Salesforce", "list Jira connections", "create a Slack message", "call an API", "use Integration Service", or wants to interact with any third-party service through UiPath.
metadata:
    allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
---

# Integration Service Assistant

Interact with external services through UiPath Integration Service — discover connectors, manage connections, explore activities, and execute operations via the `uipcli` CLI. Use `uipcli is <subcommand> --help` to discover available flags and options for any command.

## Core Principles

1. **Always follow the workflow** — Connector → Connection → Ping → Activities/Resources → Execute
2. **Do not make undocumented assumptions** — Always list real data (command output) before using IDs, keys, or names. Never fabricate values.
3. **Use `--refresh` once if results seem stale or empty** — The `list` subcommands under `is connectors`, `is connections`, `is activities`, and `is resources` cache locally. If results are missing or outdated, retry **once** with `--refresh`. If still empty after refresh, the data genuinely does not exist — do not loop.
4. **Always ping** — Verify every connection before use, even if it reports "Enabled"
5. **Prompt, don't assume** — When multiple choices exist, let the user decide

## CLI Output Format

All `uipcli` commands support `--format <format>` (table, json, yaml, plain).

**Always use `--format json`** for commands whose output you need to parse or act on. JSON output is structured and unambiguous.

---

## Task Navigation

| I need to... | Read these |
|---|---|
| **Understand the full agent workflow** | [references/agent-workflow.md](references/agent-workflow.md) |
| **Work with connectors** (find, list, fallback to HTTP) | [references/connectors.md](references/connectors.md) |
| **Work with connections** (list, create, ping, select) | [references/connections.md](references/connections.md) |
| **Work with activities** (discover actions) | [references/activities.md](references/activities.md) |
| **Work with resources** (CRUD on objects) | [references/resources.md](references/resources.md) |

## Quick Reference: Agent Workflow

```
Step 1: Find connector     → is connectors list --filter "<vendor>"
                             (if no native connector found, use the HTTP connector: uipath-uipath-http)
Step 2: Find connection    → is connections list "<connector-key>"
                             (prefer default enabled; match by name for HTTP)
Step 3: Ping connection    → is connections ping "<connection-id>"
                             (ALWAYS required before any operation)
Step 4: Discover actions   → is activities list "<connector-key>"
Step 5: List resources     → is resources list "<connector-key>" --connection-id <id> --operation <op>
                             (--connection-id for custom objects, --operation to filter by action)
Step 6: Describe resource  → is resources describe "<connector-key>" "<object>" --connection-id <id> --operation <op>
                             (--connection-id for custom fields, --operation for relevant field subset)
Step 7: Resolve references → Check describe output for referenceFields
                             For each: execute list on the referencedObject to get valid IDs
Step 8: Execute            → is resources execute <verb> "<connector-key>" "<object>" --connection-id <id>
```

For the full workflow with decision trees and examples, see [references/agent-workflow.md](references/agent-workflow.md).

## Critical Rules

1. **NEVER use a connection without pinging it first.** Even if State shows "Enabled", the token may be expired.
2. **NEVER fabricate connection IDs, connector keys, or reference field values.** Always list and select from command output.
3. **ALWAYS resolve reference fields before executing create/update.** Describe output includes `referenceFields` — list the referenced object to get valid IDs.
4. **If no native connector exists, fall back to the HTTP connector** (`uipath-uipath-http`) and match connection by vendor name.
5. **If results seem stale or empty, retry once with `--refresh`.** Do not retry more than once — if still empty, the data does not exist.
6. **If multiple connections exist, prompt the user.** Prefer `IsDefault: Yes`, then first enabled.
7. **Always use `--format json`** when parsing output programmatically.
