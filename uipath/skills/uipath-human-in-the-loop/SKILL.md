---
name: uipath-human-in-the-loop
description: "TRIGGER when: User describes a business process involving human approval, review, escalation, compliance sign-off, exception handling, or write-back validation — even if they do not explicitly say 'HITL'; User is building a Flow, Maestro process, or Coded Agent and a human decision point exists in the business logic; User asks to add a human review step, approval gate, or pause-for-human. DO NOT TRIGGER when: The process is fully automated with no human decision point; User is asking about Action Center task administration or runtime task management (not automation authoring); User is deploying or publishing — use uipath-development instead."
metadata:
  allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# UiPath Human-in-the-Loop Assistant

Recognizes when a business process needs a human decision point, designs the task schema, and wires the HITL node into the automation — Flow, Maestro, or Coded Agent.

## When to Use This Skill

- User describes **approval gates** — invoice approval, offer letter review, compliance sign-off
- User describes **exception escalation** — "if confidence is low, escalate to a human"
- User describes **write-back validation** — "human approves before agent writes to ServiceNow"
- User describes **data enrichment** — human fills in missing fields the automation cannot resolve
- User explicitly asks to **add a HITL node**, human review step, or Action Center task
- User is building any automation where **a human must act before the process can continue**

See [references/hitl-patterns.md](references/hitl-patterns.md) for the full business pattern recognition guide.

---

## Step 1 — Detect the Surface

Before designing anything, identify what type of automation is being built. Run these checks in order:

```bash
# Check for a .flow file (Flow project)
find . -name "*.flow" -maxdepth 4 | head -5

# Check for agent.json (Coded Agent project)
find . -name "agent.json" -maxdepth 4 | head -3

# Check for Maestro .bpmn (Maestro process)
find . -name "*.bpmn" -maxdepth 4 | head -3
```

| Found | Surface | CLI available |
|---|---|---|
| `.flow` file | **Flow** | Yes — `uip flow hitl add` |
| `agent.json` | **Coded Agent** | Partial — escalation CLI in-flight |
| `.bpmn` (Maestro) | **Maestro** | Not yet — guide user manually |

If the user mentioned a specific file path, use that directly.

---

## Step 2 — Read Business Context and Identify the HITL Point

Read the relevant automation file to understand what the process does:

- **Flow**: read the `.flow` file — identify nodes, edges, variable context
- **Coded Agent**: read `agent.json` and the agent source files
- **Maestro**: read the `.bpmn` file and declared process variables

Then identify:
1. **Where** in the process the human decision point belongs (after which node/step)
2. **What data** the human needs to see (inputs into the task)
3. **What data** the human must provide back (outputs from the task)
4. **What actions** the human can take (outcomes — e.g. Approve/Reject, Retry/Skip)
5. **What happens next** on each outcome (which path the automation takes)

If the business description is ambiguous about what the human sees or decides, ask one focused question before proceeding.

---

## Step 3 — Design the Schema

The HITL schema uses a flat list format — **not JSON Schema**:

```json
{
  "inputs":   [{ "name": "fieldName", "type": "string" }],
  "outputs":  [{ "name": "fieldName", "type": "string" }],
  "inOuts":   [{ "name": "fieldName", "type": "string" }],
  "outcomes": [{ "name": "Approve",  "type": "string" }]
}
```

| Field | Purpose | Human can… |
|---|---|---|
| `inputs` | Data passed into the task | Read only |
| `outputs` | Data the human fills in | Write |
| `inOuts` | Data the human can read and modify | Read + Write |
| `outcomes` | Named action buttons | Click one to complete |

**Supported types:** `string`, `number`, `boolean`, `date`

### Design rules

- `inputs`: include everything the human needs to make their decision — IDs, amounts, context
- `outputs`: include only what the automation needs back from the human
- `outcomes`: at minimum one. Use named outcomes that match the business action (e.g. `Approve`/`Reject`, not just `Submit`)
- Keep schemas focused — only ask for what the automation actually uses downstream

### Common patterns

**Approval gate:**
```json
{
  "inputs":   [{ "name": "invoiceId", "type": "string" }, { "name": "amount", "type": "number" }],
  "outcomes": [{ "name": "Approve", "type": "string" }, { "name": "Reject", "type": "string" }]
}
```

**Data enrichment:**
```json
{
  "inputs":   [{ "name": "rawExtract", "type": "string" }],
  "outputs":  [{ "name": "vendorName", "type": "string" }, { "name": "costCenter", "type": "string" }],
  "outcomes": [{ "name": "Submit", "type": "string" }]
}
```

**Exception escalation:**
```json
{
  "inputs":   [{ "name": "agentReasoning", "type": "string" }, { "name": "confidenceScore", "type": "number" }],
  "outputs":  [{ "name": "action", "type": "string" }, { "name": "notes", "type": "string" }],
  "outcomes": [{ "name": "Retry", "type": "string" }, { "name": "Skip", "type": "string" }, { "name": "Escalate", "type": "string" }]
}
```

**Write-back validation (human approves before agent writes to external system):**
```json
{
  "inputs":   [{ "name": "proposedChange", "type": "string" }, { "name": "targetSystem", "type": "string" }],
  "inOuts":   [{ "name": "finalValue", "type": "string" }],
  "outcomes": [{ "name": "Approve", "type": "string" }, { "name": "Reject", "type": "string" }]
}
```

---

## Step 4 — Add the HITL Node

### Surface: Flow

```bash
uip flow hitl add <path-to-flow-file> \
  --schema '<json-schema-string>' \
  --label "<human-readable label>" \
  --priority normal \
  --timeout PT24H
```

| Option | Values | Default |
|---|---|---|
| `--schema` | JSON string (see Step 3) | `{ outcomes: [{ name: "Submit" }] }` |
| `--label` | canvas label | `"Human in the Loop"` |
| `--priority` | `low` `normal` `high` `critical` | `normal` |
| `--timeout` | ISO 8601 duration | `PT24H` |
| `--position` | `x,y` canvas coordinates | `0,0` |

The command returns `NodeId` — save it for edge wiring.

**After adding — wire the edges:**

The HITL node has three output handles: `completed`, `cancelled`, `timeout`. Wire all three:

```bash
# Completed → happy path
uip flow edge add <file> --source <hitl-node-id>:completed --target <next-node-id>:input

# Cancelled → cancellation handler
uip flow edge add <file> --source <hitl-node-id>:cancelled --target <cancel-node-id>:input

# Timeout → timeout handler
uip flow edge add <file> --source <hitl-node-id>:timeout --target <timeout-node-id>:input
```

The node also produces two runtime variables:
- `<hitl-node-id>.result` — the data the human filled in
- `<hitl-node-id>.status` — `"completed"`, `"cancelled"`, or `"timeout"`

Reference these in subsequent script nodes as `=<hitl-node-id>.result.fieldName`.

**Validate after wiring:**
```bash
uip flow validate <file> --format json
```

See [../uipath-flow/references/flow-hitl.md](../uipath-flow/references/flow-hitl.md) for the complete Flow HITL reference.

---

### Surface: Coded Agent

The Coded Agent escalation CLI (`uip agent escalation add`) is currently in-flight. Until it ships, guide the user to configure the escalation manually in `agent.json` and insert the `interrupt(CreateTask(...))` call in the agent source.

**`agent.json` escalation entry:**
```json
{
  "escalations": [
    {
      "name": "<escalation-name>",
      "inputSchema": { "inputs": [...], "inOuts": [...] },
      "outputSchema": { "outputs": [...], "outcomes": [...] }
    }
  ]
}
```

**Agent source (Python):**
```python
from uipath.sdk import interrupt, CreateTask

response = interrupt(CreateTask(
    escalation_name="<escalation-name>",
    data={ "fieldName": value }
))
# response contains the human's outputs and chosen outcome
```

---

### Surface: Maestro

The Maestro HITL CLI is not yet available. Guide the user to add the HITL node manually in the Maestro process designer, using the schema designed in Step 3 as the configuration reference. Note that in Maestro, field names in `outputs`/`inOuts` must exactly match the declared process variable names and types.

---

## Step 5 — Report to the User

After completing the wiring:

1. **What was inserted** — node ID, label, and insertion point in the automation
2. **Schema summary** — what the human will see and what they must provide
3. **Edges wired** — which handles were connected and to which nodes
4. **Runtime variables** — how to reference `result` and `status` in downstream nodes
5. **Validation result** — pass/fail, and any errors to fix
6. **Next step** — validate locally, then pack and publish via `uipath-development` skill
