---
name: uipath-flow
description: "UiPath Flow authoring assistant — create, edit, validate, and debug Flow projects using the uip CLI and .flow file format. TRIGGER when: User wants to create a new Flow project or scaffold one with uip flow init; User is editing a .flow file (JSON workflow definition); User asks about Flow node types, the node registry, or how to wire nodes together; User wants to validate a .flow file; User wants to debug or run a Flow locally or in the cloud; User asks about .flow file format, edges, definitions, or ports; User references 'uip flow', 'flow init', 'flow validate', 'flow debug', 'flow registry'; User asks how to add logic to a Flow (Script nodes, HTTP nodes, conditions, etc.). DO NOT TRIGGER when: User wants to pack, publish, or deploy a Flow to Orchestrator (use uipath-development instead); User is building a coded automation in C# (use uipath-coded-workflows instead); User is building an RPA XAML workflow (use uipath-rpa-workflows instead); User asks about Orchestrator management (folders, assets, processes) — that is uipath-development."
metadata:
   allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# UiPath Flow Authoring Assistant

Comprehensive guide for creating, editing, validating, and debugging UiPath Flow projects using the `uip` CLI and `.flow` file format.

## When to Use This Skill

- User wants to **create a new Flow project** with `uip flow init`
- User is **editing a `.flow` file** — adding nodes, edges, or logic
- User wants to **explore available node types** via the registry
- User wants to **validate** a Flow file locally
- User wants to **debug or run** a Flow (cloud or local)
- User asks about the **`.flow` JSON format**, nodes, edges, definitions, or ports
- User asks **how to implement logic** in a Flow (scripts, HTTP calls, branching, etc.)

## Quick Start

### Step 1 — Check login status

`uip flow debug` and process operations require authentication. `uip flow init`, `validate`, and `registry` commands work without login.

```bash
uip login status --format json
```

If not logged in and you need cloud features:
```bash
uip login                                          # interactive OAuth (opens browser)
uip login --authority https://alpha.uipath.com     # non-production environments
```

### Step 2 — Create a new Flow project

```bash
uip flow init <ProjectName>
```

This scaffolds a complete project. See [references/flow-file-format.md](references/flow-file-format.md) for the full project structure.

### Step 3 — Discover available node types

Before editing the `.flow` file, check what nodes are available:

```bash
uip flow registry pull                          # refresh local cache (expires after 30 min)
uip flow registry list --format json            # list all cached node types
uip flow registry search <keyword>              # search by name, tag, or category
uip flow registry search --filter "category=agent"
uip flow registry get <nodeType> --format json  # full schema for one node type
```

> **Auth note**: Without `uip login`, registry shows OOTB nodes only. After login, tenant-specific connector nodes are also available.

### Step 4 — Edit the `.flow` file

Edit `flow_files/<ProjectName>.flow` only. Never edit `content/<ProjectName>.bpmn` — it is auto-generated.

See [references/flow-file-format.md](references/flow-file-format.md) for the full JSON schema, node/edge structure, and definition requirements.

### Step 5 — Validate locally

```bash
uip flow validate flow_files/<ProjectName>.flow --format json
```

Validates JSON structure and cross-references (edges point to existing nodes, every node type has a `definitions` entry). No auth required, runs instantly.

### Step 6 — Debug (cloud)

```bash
uip flow debug flow_files/<ProjectName>.flow
```

Requires `uip login`. Uploads to Studio Web, triggers a debug session in Orchestrator, and streams results. Use `flow validate` first — cloud debug is slower and requires connectivity.

## Task Navigation

| I need to... | Read these |
|---|---|
| **Understand the .flow JSON format** | [references/flow-file-format.md](references/flow-file-format.md) |
| **Know all CLI commands** | [references/flow-commands.md](references/flow-commands.md) |
| **Add a Script node** | [references/flow-file-format.md - Script node](references/flow-file-format.md) |
| **Wire nodes with edges** | [references/flow-file-format.md - Edges](references/flow-file-format.md) |
| **Find the right node type** | Run `uip flow registry search <keyword>` |
| **Pack / publish / deploy** | [/uipath:uipath-development](/uipath:uipath-development) |

## Key Concepts

### validate vs debug

| Command | What it does | Auth needed |
|---------|-------------|-------------|
| `uip flow validate` | Local JSON schema + cross-reference check | No |
| `uip flow debug` | Converts to BPMN, uploads to Studio Web, runs in Orchestrator, streams results | Yes |

Always `validate` locally before `debug`. Validation is instant; debug is a cloud round-trip.

### .flow file — critical rules

1. **`targetPort` is required on every edge** — `validate` rejects edges without it with `[error] [edges.N.targetPort] expected string, received undefined`
2. **Every node type needs a `definitions` entry** — copy from `uip flow registry get <nodeType>` output
3. **Edit `flow_files/*.flow` only** — `content/*.bpmn` is auto-generated and will be overwritten
4. **Script node returns an object** — `return { key: value }` not a scalar

### CLI output format

All `uip` commands return structured JSON:
```json
{ "Result": "Success", "Code": "FlowValidate", "Data": { ... } }
{ "Result": "Failure", "Message": "...", "Instructions": "Found N error(s): ..." }
```

Always use `--format json` for programmatic use. The `--localstorage-file` warning in some environments is benign.

## References

- **[.flow File Format](references/flow-file-format.md)** — Full JSON schema, node/edge structure, common node types, ports, and examples
- **[CLI Command Reference](references/flow-commands.md)** — All `uip flow` subcommands with parameters
- **[Pack / Publish / Deploy](/uipath:uipath-development)** — Packaging and Orchestrator deployment (uipath-development skill)
