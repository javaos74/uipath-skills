# Agent Workflow

Follow these steps in order when the user asks to interact with an external service.

**CRITICAL RULES:**
1. You MUST use the `Agent` tool to delegate each step. Do NOT run `uip is` commands directly — not even as a fallback.
2. Do NOT read the agent files yourself — the spawned agent will read them.
3. Each Agent call should tell the agent to read the specific file and execute the step.
4. Steps are **strictly sequential**. Do NOT run steps in parallel. Ex: Do NOT run Step 3 until Step 2 returns successfully.   Each step depends on the previous step's output.
5. If an agent errors, retry the agent — do NOT fall back to running commands directly.

## Progress Checklist

```
- [ ] Step 1: Find connector (get Key)
- [ ] Step 2: Find connection + ping (get Id, confirm Enabled)
- [ ] Step 3: Discover capabilities (activities first, then resources)
- [ ] Step 3T: (Triggers only) Get trigger objects → get trigger metadata
- [ ] Step 4: Resolve reference fields (if any)
- [ ] Step 5: Execute operation
```

---

## Step 1: Find the Connector

Agent file: [agents/connectors.md](agents/connectors.md). Use the Agent tool with this prompt:

```yaml
input:
  vendor: "<VENDOR>"
task: Find the connector key for this vendor. Use --output json on all uip commands. Return Key and whether HTTP fallback was used.
```

**Expect back:** connector `Key`, whether HTTP fallback was used

See [agents/connectors.md — Response Fields](agents/connectors.md#response-fields) and [agents/connectors.md — HTTP Connector Fallback](agents/connectors.md#http-connector-fallback).

---

## Step 2: Find a Connection + Ping

Agent file: [agents/connections.md](agents/connections.md). Use the Agent tool with this prompt:

```yaml
input:
  connectorKey: "<CONNECTOR_KEY>"
  isHttpFallback: <true/false>
  vendorName: "<VENDOR>"
task: Find a connection, ping it, and return Id, Name, State, and ping status. Use --output json on all uip commands.
```

**Expect back:** connection `Id`, `State`, ping status (must be `Enabled`)

See [agents/connections.md — Selecting a Connection](agents/connections.md#selecting-a-connection) and [agents/connections.md — Response Fields](agents/connections.md#response-fields).

---

## Step 3: Discover Capabilities

Agent file: [agents/activities.md](agents/activities.md). Use the Agent tool with this prompt:

```yaml
input:
  connectorKey: "<CONNECTOR_KEY>"
  connectionId: "<CONNECTION_ID>"
  userIntent: "<USER_INTENT>"
task: Check activities first. If no match, list resources and describe the target. Use --output json on all uip commands. Return match type (activity/resource), name, operation, field metadata, and whether describe succeeded.
```

**Expect back:** match type, object/activity name, operation, field metadata, describe status

See [agents/activities.md — When to Use Activities vs Resources vs Triggers](agents/activities.md#when-to-use-activities-vs-resources-vs-triggers) and [agents/activities.md — Response Fields](agents/activities.md#response-fields).

---

## Step 3T: Trigger Metadata (if trigger workflow)

Use this **instead of Step 3** when the user's task involves event triggers.

Agent file: [agents/triggers.md](agents/triggers.md). Use the Agent tool with this prompt:

```yaml
input:
  connectorKey: "<CONNECTOR_KEY>"
  connectionId: "<CONNECTION_ID>"
task: List trigger activities, get trigger objects, and get trigger metadata. Use --output json on all uip commands. Present choices to the user. Return trigger activities, selected operation, selected object, and field definitions.
```

**Expect back:** trigger activities, selected operation/object, field definitions

See [agents/triggers.md — Trigger Discovery Flow](agents/triggers.md#trigger-discovery-flow) and [agents/triggers.md — CRUD vs Non-CRUD Triggers](agents/triggers.md#crud-vs-non-crud-triggers).

---

## Step 4: Resolve Reference Fields

**Skip if:** Step 3 returned no reference fields and describe succeeded.

Agent file: [agents/resources.md](agents/resources.md). Use the Agent tool with this prompt:

```yaml
input:
  connectorKey: "<CONNECTOR_KEY>"
  connectionId: "<CONNECTION_ID>"
  resourceName: "<RESOURCE>"
  referenceFields: <REFERENCE_FIELDS_JSON>
  describeAvailable: <true/false>
  userProvidedFields: <USER_FIELDS>
task: Resolve all reference fields and return field-to-ID mappings. Use --output json on all uip commands.
```

**Expect back:** resolved field-to-ID mappings

See [agents/resources.md — Reference Fields (CRITICAL)](agents/resources.md#reference-fields-critical) and [agents/resources.md — Field Dependency Chains](agents/resources.md#field-dependency-chains-field-actions).

---

## Step 5: Execute

Agent file: [agents/resources.md](agents/resources.md). Use the Agent tool with this prompt:

```yaml
input:
  connectorKey: "<CONNECTOR_KEY>"
  connectionId: "<CONNECTION_ID>"
  resourceName: "<RESOURCE>"
  operation: "<create|list|get|update|delete|replace>"
  body: <BODY_JSON>
  query: <QUERY_PARAMS>
  isHttpFallback: <true/false>
task: Execute the operation and return the result. Use --output json on all uip commands.
```

**Expect back:** the execution result

See [agents/resources.md — Execute Operations](agents/resources.md#execute-operations) and [agents/resources.md — Read-Only Field Recovery](agents/resources.md#read-only-field-recovery).

---

## Agent File Reference

| File | Purpose | When to use |
|---|---|---|
| `agents/connectors.md` | Connector discovery + HTTP fallback | Step 1 |
| `agents/connections.md` | Connection selection + ping | Step 2 |
| `agents/activities.md` | Activities check, resource listing, describe | Step 3 |
| `agents/triggers.md` | Trigger activities, objects, metadata | Step 3T |
| `agents/resources.md` | Reference fields, execute, error recovery, pagination | Steps 4–5 |
