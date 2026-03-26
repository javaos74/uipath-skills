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

## Quick Start

These steps are for **creating a new flow from scratch**. For existing projects, skip to the relevant step. For small targeted edits (changing a script body, renaming a node, tweaking a port), skip straight to Step 6.

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
```

> **Auth note**: Without `uip login`, registry shows OOTB nodes only. After login, tenant-specific connector nodes are also available.

At this point you know **which connector node types** to use (e.g., `uipath.connector.uipath-atlassian-jira.create-issue`). Do **not** run `registry get` yet — you need a connection ID first to get enriched metadata. For OOTB nodes (scripts, HTTP, branching), you can call `registry get` immediately since they don't need a connection.

### Step 4 — Bind connections, fetch metadata, and resolve references (when using connectors)

**Skip this step if the flow only uses OOTB nodes.** When the flow uses Integration Service connectors (e.g., Jira, Slack, Salesforce), follow these sub-steps in order:

#### 4a. Fetch and bind connections

For each connector used in the flow, extract the connector key from the node type (`uipath.connector.<connector-key>.<activity-name>`) and fetch a connection.

**Read [/uipath:uipath-platform — Integration Service — connections.md](/uipath:uipath-platform) for the full connection selection workflow**, including:
- Native connector selection (default + enabled preference)
- HTTP fallback connector matching (name-based substring match for `uipath-uipath-http`)
- Multi-connection disambiguation (present options to user)
- No-connection recovery (prompt user to create)
- Ping verification (always ping before using — a connection can be `Enabled` but expired)
- Re-authentication via `uip is connections edit`

Quick reference:
```bash
# 1. List available connections
uip is connections list "<connector-key>" --format json

# 2. Pick the default enabled connection (IsDefault: Yes, State: Enabled)
#    Follow connections.md for selection rules and fallback

# 3. Verify the connection is healthy
uip is connections ping "<connection-id>" --format json
```

Once you have the connection ID, bind it using the CLI. Run once per unique connector:

```bash
uip flow bindings upsert <flowFile> \
  --connector <connector-key> \
  --connection-id <connection-id>
```

This atomically updates `bindings_v2.json`, `*.bindings.flow`, and `*.connectors.flow`. Safe to re-run — it upserts in place. Use `--display-name <label>` to set a human-readable label (defaults to `"<connector-key> connection"`).

If a flow uses multiple connectors (e.g., Jira + Slack), run once per connector. See [references/flow-file-format.md — Bindings](references/flow-file-format.md) for the full schema and multi-connector examples.

#### 4b. Get enriched node definitions with connection

Now that you have a connection ID, call `registry get` with `--connection-id` to fetch connection-aware metadata. This returns the full field schema including custom fields specific to that connection/account:

```bash
uip flow registry get <nodeType> --connection-id <connection-id> --format json
```

The flow tool internally calls the Integration Service SDK's `getInstanceObjectMetadata` (instead of `getObjectMetadata`) when a connection ID is provided, returning enriched `inputDefinition.fields` and `outputDefinition.fields` with accurate type, required, description, enum, and `reference` info.

> **Without `--connection-id`**, `registry get` still returns metadata but only standard/base fields — custom fields and connection-specific reference data may be missing.

#### 4c. Resolve reference fields

Check the `inputDefinition.fields` from the `registry get` response for any field that has a `reference` object. These fields require their values to be looked up from the connector's live data.

**Read [/uipath:uipath-platform — Integration Service — resources.md](/uipath:uipath-platform) for the full reference resolution workflow**, including:
- How to identify reference fields (`reference.objectName`, `reference.lookupValue`)
- Resolving references via `uip is resources execute list`
- Inferring references without describe (fields ending in `Id` → base name convention)
- Describe failures and metadata gap recovery
- Read-only field recovery on create
- Pagination for large result sets

**How to identify reference fields** — look for the `reference` property in the `registry get` response:

```json
{
  "name": "fields.project.key",
  "displayName": "Project",
  "type": "string",
  "required": true,
  "reference": {
    "objectName": "project",
    "lookupValue": "key"
  }
}
```

This means the value for `fields.project.key` must be resolved by listing the `project` resource and using the `key` field from the results.

#### Field dependency chains

Some reference fields **depend on other fields** — e.g., Jira's `fields.issuetype.id` depends on `fields.project.key` (issue types are project-scoped). Resolving them in the wrong order returns duplicates across all projects.

**CRITICAL: If a parent field value is NOT in the user's prompt, you MUST ask the user for it BEFORE attempting to resolve any child fields.** Do not resolve child fields without a scoped parent — the results will be wrong or ambiguous.

**Resolution order:**
1. Identify which reference fields have parent dependencies (e.g., issue type depends on project)
2. Check if the user provided the parent field value in their prompt
3. **If the parent value is missing → ASK the user.** Do not skip, guess, or resolve the child unscoped.
4. Once you have the parent value, resolve the child field scoped to that parent

**Read [/uipath:uipath-platform — Integration Service — resources.md § Field Dependency Chains](/uipath:uipath-platform) for the full pattern**, including how to detect dependencies, the correct resolution order, and scoped path substitution.

**Example — user says "Create a Jira ticket with issue type Bug" (no project specified):**
1. Metadata shows `fields.issuetype.id` depends on `fields.project.key`
2. User did NOT provide a project → **ASK:** "Which Jira project should this be created in?"
3. User responds "ENGCE"
4. NOW resolve issue types scoped to ENGCE: `project/ENGCE/issuetypes`
5. Match "Bug" → ID `1`

**Do NOT resolve issue types globally without a project scope** — this returns issue types from ALL projects, leading to ambiguous or incorrect IDs.

Quick example — Jira project → issue type (when parent IS provided):
```bash
# Step 1: Resolve project (no dependency)
uip is resources execute list "uipath-atlassian-jira" "project" \
  --connection-id "<id>" --format json
# → { "key": "ENGCE", "id": "10845" }

# Step 2: Resolve issue types scoped to that project
uip is resources execute list "uipath-atlassian-jira" "project/ENGCE/issuetypes" \
  --connection-id "<id>" --format json
# → { "id": "10004", "name": "Bug" }  ← only issue types for ENGCE
```

#### Simple reference fields (no dependencies)

For fields with no parent dependency, resolve directly:

```bash
# Resolve Slack channel "#test-slack" to its channel ID
uip is resources execute list "uipath-salesforce-slack" "curated_channels?types=public_channel,private_channel" \
  --connection-id "<id>" --format json
# → { "id": "C1234567890", "name": "test-slack" }
```

**Present options to the user** when multiple matches exist. Use the resolved IDs (not display names) in the flow's node `inputs`.

#### Pagination for resource resolution

`uip is resources execute list` may not return all results in a single call (e.g., Slack channels, Jira users). **Always check for pagination** and fetch all pages when searching for a specific item.

**Pagination parameters:**
```bash
uip is resources execute list "<connector-key>" "<resource>" \
  --connection-id "<id>" \
  --page 1 --page-size 100 \
  --format json
```

**Pagination response headers** (available in the response):
- `elements-has-more`: `true` or `false` — indicates if more pages exist
- `elements-next-page-token`: opaque token to pass as `--next-page` for the next request

**Pagination loop:**
```bash
# First page
uip is resources execute list "<connector-key>" "<resource>" \
  --connection-id "<id>" --page-size 100 --format json
# → Check response: elements-has-more=true, elements-next-page-token="abc123"

# Next page (pass the token)
uip is resources execute list "<connector-key>" "<resource>" \
  --connection-id "<id>" --page-size 100 --next-page "abc123" --format json
# → Continue until elements-has-more=false or target item is found
```

**When to paginate:**
- When searching for a specific item by name (e.g., Slack channel "test-slack") and it's not in the first page
- When listing all items for user selection and the first page is incomplete

**Stop early:** If you find the target item in the current page, no need to fetch remaining pages.

> **Exception — HTTP connectors and http-request activities:** Connectors with key `uipath-uipath-http` and any connector's `*-http-request` activity do NOT use the `elements-*` pagination headers. These depend directly on vendor-specific pagination (e.g., `offset`/`limit` query params, `cursor` fields in the response body). Handle these on a case-by-case basis based on the vendor API docs.

> **Fallback when resolution fails:** If `execute list` returns empty or errors, fall back to using the user-provided display name as-is. The connector runtime may still resolve it. Note this as a risk in the plan. See the **Inferring References Without Describe** section in [resources.md](/uipath:uipath-platform) for naming-convention-based inference as a secondary fallback.

#### 4d. Validate required fields against user prompt

After fetching node metadata (Steps 4b/4c), **check every required field** in `inputDefinition.fields` against what the user provided in their prompt. This is a hard gate — do NOT proceed to planning or building until all required fields have values.

**Process:**
1. Collect all fields where `required: true` from each connector node's `inputDefinition.fields`
2. For each required field, check if the user's prompt contains a value for it
3. If any required field is missing, **ask the user** before proceeding:
   - List the missing fields with their `displayName` and `description`
   - For reference fields, explain what kind of value is expected (e.g., "Which Jira project should this issue be created in?")
   - Wait for the user's response before continuing
4. Only after all required fields are accounted for, proceed to reference resolution and planning

**Example — user says "Create a Jira ticket with issue type Bug":**
- Required fields from metadata: `fields.project.key` (Project), `fields.issuetype.id` (Issue type)
- User provided: issue type = Bug
- User did NOT provide: project
- **Ask:** "Which Jira project should this Bug be created in? (e.g., ENGCE, PROJ, etc.)"
- Wait for response, then continue

> **Do NOT guess or skip missing required fields.** A missing required field will cause a runtime error. It is always better to ask than to assume.

After completing Steps 4a–4d, you should have for each connector node: a bound connection ID, enriched field metadata, and resolved values for all reference fields. Carry this information into the planning step.

### Step 5 — Plan the flow (interactive)

**Required when creating a new flow or adding multiple nodes.** Only skip this step for small targeted edits to an *existing* flow (e.g., changing a script body, renaming a node, tweaking one connection). When in doubt, plan.

Generate a plan as a **self-contained HTML file** with a mermaid diagram and structured details. This lets the user (and PMs) visually review the flow topology before any code is written.

#### 5a. Write the plan file

Read [references/plan-template.html](references/plan-template.html) **once** and write `flow-plan.html` in the project directory by **copying the template and replacing the `{{PLACEHOLDER}}` markers** with actual content. Do not rewrite the HTML from scratch — preserve the Tailwind config, styles, and structure exactly. The HTML comment examples in the template show the expected format for each section.

> **Token efficiency:** Only read the template when generating a new plan. For subsequent updates (Step 5c), edit `flow-plan.html` directly — do not re-read the template.

The plan must include:

1. **Summary** — 2-3 sentences describing what the flow does end-to-end
2. **Mermaid diagram** — visual flowchart showing all nodes, edges, and branching logic. Use `subgraph` blocks to group related sections (e.g., "Data Ingestion", "Processing", "Notification"). For flows with 20+ nodes, subgraphs are essential for readability.
3. **Node table** — every node with: ID, display name, node type, and what it does
4. **Connector details** — for each connector node: connector key, operation, required input fields (from Step 4 IS discovery), and connection status (found/missing)
5. **Inputs & Outputs** — what the flow needs to start and what it produces
6. **Open questions** — anything the user hasn't specified, marked as `[REQUIRED: ...]`

#### 5b. Open the plan for review

```bash
open flow-plan.html    # macOS — opens in default browser
```

In chat, output a **short summary only** (goal + key nodes + any open questions). Tell the user to review the full plan and diagram in the browser.

#### 5c. Iterate until approved

**Do NOT proceed to Step 6 until the user explicitly approves the plan.** The iteration loop:

1. User reviews the plan in browser and gives feedback in chat (e.g., "move the Slack notification before the filter", "add an error handler after the API call", "use Salesforce instead of HubSpot")
2. Update `flow-plan.html` with the changes
3. Tell the user to refresh the browser page
4. Summarize what changed in chat
5. Repeat until the user says the plan is approved

### Step 6 — Build the flow

Never edit the `<ProjectName>.flow`, `content/<ProjectName>.bpmn`, or `bindings_v2.json` directly. These files are manipulated through flow CLI commands. Always use `uip flow` commands to make changes, and let the CLI handle file updates. Direct edits will be overwritten or cause validation errors.

#### 6a. Split the .flow file

Use the `uip flow split` command to split the monolithic `.flow` file into separate files for nodes, edges, and definitions. This makes it easier to manage and edit. The flow CLI commands expect this split structure for incremental updates.

```bash
uip flow split <ProjectName>.flow
```

#### 6b. Build the .flow file

For each node:

**1. Fetch the node definition** into the `.definitions.flow` split file:
```bash
uip flow definitions upsert <flowFile> <nodeType>
```
Safe to re-run — inserts or updates in place.

**2. Add the node instance** with its inputs (use resolved field values from Step 4c):
```bash
uip flow nodes add <flowFile> --type <nodeType> --id <nodeId> --inputs '<json>'
```

For connector nodes, `<json>` uses **resolved IDs** from Step 4c, not display names:
```bash
uip flow nodes add MyFlow.flow \
  --type uipath.connector.uipath-atlassian-jira.create-issue \
  --id create-issue \
  --inputs '{"fields.project.key":"ENGCE","fields.issuetype.id":"10004","fields.assignee.id":"5f4abc..."}'
```

Pass `--inputs -` to pipe JSON from a previous command:
```bash
echo '{"script":"return {}"}' | uip flow nodes add MyFlow.flow \
  --type uipath.script --id my-script --inputs -
```

To inspect a node's current inputs after adding:
```bash
uip flow nodes get <flowFile> <nodeId> --format json
```

To update inputs on an existing node:
```bash
uip flow nodes edit <flowFile> <nodeId> --inputs '<updated-json>'
```

**3. Wire edges** between nodes (every edge requires a `targetPort`):
```bash
uip flow edges add <flowFile> "<edgeId>: <sourceNodeId>:<sourcePort> -> <targetNodeId>:<targetPort>"
```

After all nodes are added, remove any stale definitions:
```bash
uip flow definitions trimunused <flowFile>
```

#### 6c. Bind connector connections

If the flow uses connector nodes, bind each connection using the CLI (same command as Step 4a):

```bash
uip flow bindings upsert <flowFile> \
  --connector <connector-key> \
  --connection-id <connection-id>
```

To remove a binding (e.g., when swapping connectors):
```bash
uip flow bindings remove <flowFile> --connector <connector-key>
```

This file is what the runtime uses to resolve `<bindings.{connector-key} connection>` placeholders in node model context. See [references/flow-file-format.md — Bindings](references/flow-file-format.md) for the full schema and multi-connector examples.

#### 6d. Recombine the .flow file

After all nodes, edges, definitions, and bindings are updated, use `uip flow combine` to merge them back into a single `.flow` file.

```bash
uip flow combine <ProjectName>.flow
```

### Step 7 — Validate loop

Run validation and fix errors iteratively until the flow is clean.

```bash
uip flow validate <ProjectName>.flow --format json
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
uip flow debug <ProjectName>.flow
```

Requires `uip login`. Uploads to Studio Web, triggers a debug session in Orchestrator, and streams results. Use `flow validate` first — cloud debug is slower and requires connectivity.

**Do NOT run `flow debug` automatically.** Debug executes the flow for real — it will send emails, post Slack messages, call APIs, write to databases, etc. Only run debug when the user explicitly asks to debug or test the flow. After validation succeeds, tell the user the flow is ready and ask if they want to debug it.

## Task Navigation

| I need to... | Read these |
|---|---|
| **Generate a flow plan** | Step 5 + [references/plan-template.html](references/plan-template.html) |
| **Understand the .flow JSON format** | [references/flow-file-format.md](references/flow-file-format.md) |
| **Know all CLI commands** | [references/flow-commands.md](references/flow-commands.md) |
| **Add a node definition to .definitions.flow** | Run `uip flow definitions upsert <flowFile> <nodeType>` |
| **Remove unused definitions from .definitions.flow** | Run `uip flow definitions trimunused <flowFile>` |
| **Add a Script node** | [references/flow-file-format.md - Script node](references/flow-file-format.md) |
| **Wire nodes with edges** | [references/flow-file-format.md - Edges](references/flow-file-format.md) |
| **Find the right node type** | Run `uip flow registry search <keyword>` |
| **Bind connector connections** | Run `uip flow bindings upsert <flowFile> --connector <key> --connection-id <id>` |
| **Remove a connector binding** | Run `uip flow bindings remove <flowFile> --connector <key>` |
| **Get enriched connector metadata** | Step 4b — `registry get --connection-id` |
| **Resolve reference fields** | Step 4c + [/uipath:uipath-platform — Integration Service — Resources](/uipath:uipath-platform) |
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
2. **Every node type needs a `definitions` entry** — run `uip flow definitions upsert <flowFile> <nodeType>` to populate it automatically
3. **Edit `<ProjectName>.flow` only** — `content/*.bpmn` is auto-generated and will be overwritten
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
- **[Plan Template](references/plan-template.html)** — HTML template for flow plan visualization (mermaid diagram + node details)
- **[Pack / Publish / Deploy](/uipath:uipath-platform)** — Packaging and Orchestrator deployment (uipath-platform skill)
