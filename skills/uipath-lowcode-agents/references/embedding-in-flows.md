# Inline Agents in Flow Projects

Agents can be embedded as a subdirectory inside a flow project instead of existing as standalone projects.

## Standalone vs Inline

| Aspect | Standalone | Inline |
|--------|-----------|--------|
| Location | Own project in solution | Subdirectory inside flow project |
| Files | agent.json, entry-points.json, project.uiproj, flow-layout.json | agent.json only (plus features/, resources/) |
| Lifecycle | Independent publish | Published with parent flow |
| Best for | Agent runs on its own or is referenced externally | Agent is a step within a flow |

## Inline Agent Structure

An inline agent contains only the definition files — no entry-points.json, no flow-layout.json, no project.uiproj:

```
<FlowProject>/
├── <FlowName>.flow
├── project.uiproj              # Flow's project file
├── entry-points.json           # Flow's entry points
├── <AgentName>/                # Inline agent subdirectory
│   ├── agent.json              # Agent definition
│   ├── features/               # Agent features (future)
│   └── resources/              # Agent resources (future)
└── ...
```

## Creating an Inline Agent

### Step 1: Start with an existing flow project

The flow project must already exist.

### Step 2: Create the agent subdirectory

Create a directory inside the flow project. Add `agent.json` with the same schema as a standalone agent (see [agent-json-format.md](agent-json-format.md)).

### Step 3: Configure agent.json

Same configuration as standalone: model settings, system/user messages with contentTokens, input/output schemas.

### Step 4: Validate the agent definition

```bash
cd <FlowProject>/<AgentName>
uip lowcodeagents validate --output json
```

### Flow Wiring

Wiring the inline agent into the parent flow (adding the agent node, connecting edges) is handled by the `uipath-flow` skill. This skill only covers the agent definition itself.
