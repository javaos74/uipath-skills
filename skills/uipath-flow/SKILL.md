---
name: uipath-flow
description: "This skill should be used when the user wants to 'create a new Flow project', 'scaffold a flow with uip flow init', 'add a node to my flow', 'connect nodes in my flow', 'validate a .flow file', 'debug a flow', 'run a flow', 'discover flow node types', or when the user is editing a .flow file, wiring nodes and edges, working with definitions or ports, or asks about the .flow JSON format or uip flow CLI commands."
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
- User wants to **debug** a Flow (cloud)
- User asks about the **`.flow` JSON format**, nodes, edges, definitions, or ports
- User asks **how to implement logic** in a Flow (scripts, HTTP calls, branching, etc.)

## Common Edits (existing flows)

For targeted changes to an existing flow, use the recipes below instead of the full Quick Start pipeline. Always run `uip flow validate` after editing.

### Change a script body

Edit the `inputs.script` string on the target node in `flow_files/<ProjectName>.flow`. Script nodes must return an object (`return { key: value }`), not a scalar.

### Add a node between two existing nodes

1. Get the new node's schema: `uip flow registry get <nodeType> --format json`
2. Add its `Data.Node` to the `definitions` array (skip if that type already has a definition)
3. Add the node instance to `nodes` with a unique `id` and correct `ui.position`
4. Find the edge connecting the two existing nodes — update it to point to the new node instead:
   - Change `targetNodeId` to the new node's `id` and `targetPort` to the new node's incoming port (usually `input`)
5. Add a new edge (with a unique `id`) from the new node to the original target:
   - `sourceNodeId`: new node's `id`, `sourcePort`: `success` (or the appropriate port)
   - `targetNodeId`: original target's `id`, `targetPort`: `input`
6. Check ports: see [references/flow-file-format.md — Standard ports](references/flow-file-format.md) for source/target ports by node type

### Add a branch (condition node)

1. Get the definition: `uip flow registry get core.logic.condition --format json` and add `Data.Node` to `definitions`
2. Add a `core.logic.condition` node with an `expression` input
3. Redirect the incoming edge to the condition node — update `targetNodeId` and set `targetPort: "input"`
4. Add two outgoing edges from the condition — one from `sourcePort: "true"`, one from `sourcePort: "false"` — each wiring to the appropriate downstream node with `targetPort: "input"`

### Remove a node

1. Delete the node from the `nodes` array
2. Delete all edges where `sourceNodeId` or `targetNodeId` matches the removed node's `id`
3. Reconnect: add a new edge from the upstream node to the downstream node
4. Remove its definition from `definitions` only if no other node uses the same type

## Quick Start

These steps are for **creating a new flow from scratch**. For existing projects, use the Common Edits section above or skip to the relevant step.

### Step 0 — Resolve the `uip` binary

The `uip` CLI is installed via npm. If `uip` is not on PATH (common in nvm environments), resolve it first:

```bash
UIP=$(command -v uip 2>/dev/null || npm root -g 2>/dev/null | sed 's|/node_modules$||')/bin/uip
$UIP --version
```

Use `$UIP` in place of `uip` for all subsequent commands if the plain `uip` command isn't found.

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

### Step 4 — Discover connector capabilities (when using connectors)

**Skip this step if the flow only uses OOTB nodes (scripts, HTTP, branching).** When the flow uses Integration Service connectors (e.g., Slack, Salesforce, Outlook), you **must** discover what the connector can do before planning. The flow registry tells you *which* connector nodes exist, but not what operations they support or what fields are required. Without IS discovery, generated flows will have missing or incorrect `inputs.detail`, empty `outputs` blocks, and unresolvable `$vars` references — issues that `flow validate` does not catch.

**Use the [/uipath:uipath-platform](/uipath:uipath-platform) skill for all IS operations.** It has the complete Integration Service reference including the agent workflow (connector → connection → ping → discover → resolve references → execute), field metadata, error recovery, and connection management. The key commands you'll need:

- `uip is activities list <connector-key>` — what operations the connector supports
- `uip is resources list/describe <connector-key>` — what data objects and fields are available
- `uip is connections list/ping/create <connector-key>` — check or create authenticated connections

Gather this information **before** moving to the planning step. For each connector node in the flow, you should know: which operation to use, what fields are required, and whether a connection exists.

### Step 5 — Plan the flow (interactive)

**Required when creating a new flow or adding multiple nodes.** Only skip this step for small targeted edits to an *existing* flow (e.g., changing a script body, renaming a node, tweaking one connection). When in doubt, plan.

Generate a plan as a **markdown file** with a mermaid diagram and structured details. This lets the user (and PMs) review the flow topology before any code is written.

#### 5a. Write the plan file

Write `flow-plan.md` in the project directory with the following sections. For subsequent updates (Step 5c), edit `flow-plan.md` directly.

**Required sections:**

1. **Summary** — 2-3 sentences describing what the flow does end-to-end
2. **Flow Diagram** — a mermaid diagram showing all nodes, edges, and branching logic. Use `subgraph` blocks to group related sections (e.g., "Data Ingestion", "Processing", "Notification"). For flows with 20+ nodes, subgraphs are essential for readability. Use direction TB (top-bottom) for most flows; LR (left-right) only for very linear flows with few branches.
3. **Node table** — markdown table with columns: `#`, `Name`, `Category`, `Node Type`, `Description`. Category is one of: connector, script, control, trigger, agent.
4. **Connector details** (omit if no connectors) — markdown table with columns: `Node`, `Connector Key`, `Operation`, `Required Inputs`, `Connection`. Mark connection status as found or not found.
5. **Inputs & Outputs** — markdown table with columns: `Direction`, `Name`, `Type`, `Description`
6. **Open questions** (omit if none) — bulleted list, each prefixed with `**[REQUIRED]**`

#### 5b. Present the plan for review

In chat, output a **short summary only** (goal + key nodes + any open questions). Tell the user to review the full plan in `flow-plan.md`.

#### 5c. Iterate until approved

**Do NOT proceed to Step 6 until the user explicitly approves the plan.** The iteration loop:

1. User reviews the plan and gives feedback in chat (e.g., "move the Slack notification before the filter", "add an error handler after the API call", "use Salesforce instead of HubSpot")
2. Update `flow-plan.md` with the changes
3. Summarize what changed in chat
4. Repeat until the user says the plan is approved

### Step 6 — Build the flow

Edit `flow_files/<ProjectName>.flow` only. Never edit `content/<ProjectName>.bpmn` — it is auto-generated.

Build the flow by editing the `.flow` JSON directly. For each node:
1. Get the full node schema: `uip flow registry get <nodeType> --format json`
2. Copy the `Data.Node` object into the `definitions` array
3. Add the node instance to the `nodes` array with correct inputs (use field info from Step 4 IS discovery)
4. Add edges to the `edges` array with correct `sourcePort` and `targetPort`

See [references/flow-file-format.md](references/flow-file-format.md) for the full JSON schema, node/edge structure, and definition requirements.

### Step 7 — Validate loop

Run validation and fix errors iteratively until the flow is clean.

```bash
uip flow validate flow_files/<ProjectName>.flow --format json
```

**Validation loop:**
1. Run `uip flow validate`
2. If valid → done, move to Step 8
3. If errors → read the error messages, fix the `.flow` file
4. Go to 1

Common error categories:
- **Missing targetPort** — every edge needs a `targetPort` string
- **Missing definition** — every `type:typeVersion` in nodes needs a matching `definitions` entry
- **Invalid node/edge references** — `sourceNodeId`/`targetNodeId` must reference existing node `id`s
- **Duplicate IDs** — node and edge `id`s must be unique

### Step 8 — Debug (cloud) — only when explicitly requested

```bash
uip flow debug flow_files/<ProjectName>.flow
```

Requires `uip login`. Uploads to Studio Web, triggers a debug session in Orchestrator, and streams results. Use `flow validate` first — cloud debug is slower and requires connectivity.

**Do NOT run `flow debug` automatically.** Debug executes the flow for real — it will send emails, post Slack messages, call APIs, write to databases, etc. Only run debug when the user explicitly asks to debug or test the flow. After validation succeeds, tell the user the flow is ready and ask if they want to debug it.

## Task Navigation

| I need to... | Read these |
|---|---|
| **Edit an existing flow** | Common Edits section |
| **Generate a flow plan** | Step 5 |
| **Understand the .flow JSON format** | [references/flow-file-format.md](references/flow-file-format.md) |
| **Know all CLI commands** | [references/flow-commands.md](references/flow-commands.md) |
| **Add a Script node** | [references/flow-file-format.md - Script node](references/flow-file-format.md) |
| **Wire nodes with edges** | [references/flow-file-format.md - Edges](references/flow-file-format.md) |
| **Find the right node type** | Run `uip flow registry search <keyword>` |
| **Discover connector capabilities** | Step 4 + [/uipath:uipath-platform — Integration Service](/uipath:uipath-platform) |
| **Check/create connections** | [/uipath:uipath-platform — Integration Service](/uipath:uipath-platform) |
| **Pack / publish / deploy** | [/uipath:uipath-platform](/uipath:uipath-platform) |

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
- **[Pack / Publish / Deploy](/uipath:uipath-platform)** — Packaging and Orchestrator deployment (uipath-platform skill)
