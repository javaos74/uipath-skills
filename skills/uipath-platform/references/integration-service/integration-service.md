# Integration Service

Interact with external services through UiPath Integration Service — discover connectors, manage connections, and execute operations via the `uip` CLI.

> Full command syntax and options: [uip-commands.md — Integration Service](../uip-commands.md#integration-service-is). Domain-specific usage patterns are shown inline in each reference file.

## Prerequisites

- `uip` must be authenticated (`uip login`)
- Correct folder context must be set if using folder-scoped connections (`--folder`)

## Core Principles

1. **Always follow the workflow** — Connector → Connection → Ping → Discover → Resolve References → Execute
2. **Never fabricate IDs or values** — Always list real data (command output) before using IDs, keys, or names. Select from command output only.
3. **Resolve reference fields before create/update** — Describe output includes `referenceFields` — list the referenced object to get valid IDs before executing.
4. **Use `--refresh` once if results are unexpected** — The `list` subcommands cache locally. Retry **once** with `--refresh` when: results are empty, a recently created item is missing, or the user says data should exist. If still empty after refresh, inform the user the data does not exist — do not loop.
5. **Always ping** — Verify every connection before use, even if it reports "Enabled"
6. **Prompt, don't assume** — When multiple choices exist (connections, reference values), present options and let the user decide. Only auto-select when there is exactly one valid option.
7. **Always use `--output json`** for commands whose output you need to parse or act on.
8. **Delegate steps to agents** — Each workflow step has a focused agent with only the context it needs. This prevents context overload and hallucination. See [agent-workflow.md](agent-workflow.md) for the orchestration pattern.

---

## Navigation

### Workflow Orchestration (start here for any IS task)

| When to load | File | For |
|---|---|---|
| Any IS task | [agent-workflow.md](agent-workflow.md) | Step-by-step orchestrator — delegates to agents |

### Sub-Agents (loaded by orchestrator per step — do NOT load all at once)

| Sub-Agent | File | Context |
|---|---|---|
| Find Connector | [agents/connectors.md](agents/connectors.md) | Connector discovery, HTTP fallback |
| Find Connection | [agents/connections.md](agents/connections.md) | Connection selection (native + HTTP), ping |
| Discover Capabilities | [agents/activities.md](agents/activities.md) | Activities check, resource listing, describe |
| Discover Triggers | [agents/triggers.md](agents/triggers.md) | Trigger activities, objects, field metadata |
| Resources | [agents/resources.md](agents/resources.md) | Reference fields, execute, error recovery, pagination |

---

## How to Present Choices

When multiple options exist, present them clearly:
- **Connections**: "Which connection? 1) Salesforce Prod (default, enabled) 2) Salesforce Dev (enabled)"
- **Reference fields**: "Which department? 1) Engineering (id: 123) 2) Sales (id: 456)"

## Error Recovery

| Problem | Recovery |
|---|---|
| Ping returns non-enabled | Run `is connections edit <id>` to re-authenticate, then ping again. If still fails, ask user to choose another connection or create new. |
| List returns empty after `--refresh` | Inform user the data does not exist. Do not retry. Suggest checking permissions or folder context. |
| Reference field lookup returns empty | Inform user — the referenced object has no records. Ask if they want to create one or use a different value. |
| Execute fails with validation error | Re-check describe output for required fields. Verify field types and reference IDs are correct. |
| Describe returns empty `availableOperations` | Metadata gap — do **not** retry with `--refresh`. Skip describe, attempt execute directly. See [agents/activities.md](agents/activities.md). |
| Create fails with `INVALID_FIELD_FOR_INSERT_UPDATE` | Field is read-only/auto-generated. Remove it from `--body`, use alternative writable field, and retry. See [agents/resources.md](agents/resources.md). |
| Connector not found | Fall back to HTTP connector (`uipath-uipath-http`). See [agents/connectors.md](agents/connectors.md). |
| No trigger objects for operation | Check operation name (CREATED/UPDATED/DELETED, uppercase). Verify connector supports events (`hasEvents` in connector list). See [agents/triggers.md](agents/triggers.md). |
| Trigger metadata empty | Check object name matches exactly from `triggers objects` output. Try with `--connection-id` for custom fields. See [agents/triggers.md](agents/triggers.md). |
