# Embedding Agents in Flow Projects

Low-code agents can exist as **standalone projects** (their own project in a solution) or as **embedded agents** (a subdirectory inside a flow project). This guide covers when and how to embed agents in flows.

## Standalone vs Embedded

| Aspect | Standalone | Embedded |
|--------|-----------|----------|
| Location | Own directory in solution | Subdirectory inside flow project |
| project.uiproj | Has its own | No — governed by parent flow |
| Lifecycle | Independent versioning and publish | Published with parent flow |
| Use case | Agent runs on its own or is referenced externally | Agent is a step within a flow |
| CLI init | `uip lowcodeagents init` in solution dir | Manual setup inside flow project |

### When to Use Standalone

- The agent is the primary deliverable
- Multiple flows or processes need to reference the same agent
- The agent will be deployed and tested independently
- The agent has its own evaluation sets

### When to Embed

- The agent is one step in a larger flow orchestration
- The agent is tightly coupled to the flow's logic and data
- You want a single deployable unit (flow + agent)

## Embedded Agent Structure

An embedded agent lives as a subdirectory inside a flow project. It has the same internal structure as a standalone agent, except it has no `project.uiproj`.

```
<FlowProject>/
├── <FlowName>.flow             # Parent flow file
├── project.uiproj              # Flow project file (governs the agent too)
├── entry-points.json           # Flow entry points
├── <AgentName>/                # Embedded agent subdirectory
│   ├── agent.json              # Agent configuration
│   ├── entry-points.json       # Agent entry points
│   ├── flow-layout.json        # Agent UI layout
│   ├── evals/                  # Agent evaluation sets
│   │   ├── eval-sets/
│   │   └── evaluators/
│   ├── features/               # Agent features (memory spaces)
│   └── resources/              # Agent resources (escalations, tools, etc.)
└── ...
```

### Key Constraints

1. **No project.uiproj** — the embedded agent does not have its own project file. It is governed by the parent flow's `project.uiproj`.

2. **Published together** — the embedded agent is bundled and uploaded as part of the parent flow project. There is no way to publish it independently.

3. **Flow references the agent** — the parent `.flow` file contains a node that references the embedded agent subdirectory. The flow orchestrates when and how the agent is invoked.

4. **Features and resources work normally** — embedded agents can have memory spaces, escalations, tools, contexts, and MCPs, structured exactly as in standalone agents.

## Creating an Embedded Agent

### Step 1: Start with an existing flow project

The flow project must already exist (created via `uip flow init` or equivalent).

### Step 2: Create the agent subdirectory

Create a directory inside the flow project with the agent's name. Add the required files:

- `agent.json` — same schema as standalone agents
- `entry-points.json` — same schema, `filePath` points to the agent relative to the flow project
- `flow-layout.json` — minimal: `{ "zoom": 0.81 }`

### Step 3: Configure agent.json

Follow the same configuration steps as a standalone agent:
- Set model, temperature, tokens in `settings`
- Define `inputSchema` and `outputSchema`
- Write system and user messages with `contentTokens`

### Step 4: Wire the flow

In the parent `.flow` file, add a node that invokes the embedded agent. The flow passes data to the agent's input schema and receives the agent's output.

> For flow-side wiring details, read the `uipath-flow` skill's orchestration guide. The agent node type and configuration depends on how the flow references embedded agents.

### Step 5: Validate both

Validate the agent:
```bash
cd <FlowProject>/<AgentName>
uip lowcodeagents validate --output json
```

Validate the flow:
```bash
cd <FlowProject>
uip flow validate --output json
```

## Converting Standalone to Embedded

1. Copy the agent project directory into the flow project directory
2. Delete `project.uiproj` from the copied agent directory
3. Add a node in the `.flow` file that references the embedded agent
4. Update the solution to remove the standalone agent project reference (if it was registered)
5. Validate both the agent and the flow

> **Note:** Embedded agent support details may be refined as more examples become available. The core file structure (agent.json, entry-points.json, features/, resources/) remains the same regardless of standalone vs embedded.
