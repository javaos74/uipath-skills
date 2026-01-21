---
description: Run a UiPath agent with interactive input collection
allowed-tools: Bash, Read, Glob, AskUserQuestion
---

# Run a UiPath Agent

Execute your UiPath agent with interactive, schema-driven input collection.

## Context-Aware Execution

This skill automatically detects your UiPath project! The context includes:
- ✅ Available agents (from cached entry-points.json)
- ✅ Agent input/output schemas
- ✅ Project configuration

**You can just type `/uipath-coded-agents:run`** and the skill will:
1. Check cached context for available agents
2. Auto-select if only one agent exists
3. Show menu if multiple agents found
4. Proceed directly to input collection

No need to specify agent name if you only have one!

## Workflow

### Step 0: Automatic Context Detection
The extension automatically detects and caches:
- Your UiPath project (uipath.json)
- All agents from entry-points.json
- Evaluation files
- Project metadata

Cache is refreshed every 5 minutes or when files change.

### Step 1: Project Verification
I'll verify that your project has:
- `uipath.json` - Project configuration
- `entry-points.json` - Agent entry points with schemas

If missing, create an agent first with `/uipath-coded-agents:create-agent`.

### Step 2: Agent Discovery
I'll read `entry-points.json` to find all available agents and their schemas:
- **File path** and **entry point** (e.g., main.py:main)
- **Input schema** with field types and descriptions
- **Output schema** with expected return fields

If multiple agents exist, I'll prompt you to select one.

### Step 3: Input Collection
I'll parse the agent's JSON schema and generate interactive prompts for each input field:

**For simple types:**
```
Enter field_name (number) - Description: 42
Enter description (string) - Agent input: hello
```

**For enums:**
```
Select action (string) - Choose an action:
  1. process
  2. analyze
  3. export
Choice: 1
```

**For optional fields:**
```
Enter description (string) - Optional agent description [press Enter to skip]:
```

### Step 4: Execution
I'll execute:
```bash
uv run uipath run <entrypoint> '<json-input>'
```

The agent runs with your provided inputs and returns structured output.

### Step 5: Results Display
Results are shown in a formatted output panel:

```
EXECUTION RESULTS
═══════════════════════════════════════════════════════════

Status:           ✅ SUCCESS
Execution Time:   0.45 seconds
Agent:            my-agent (agent.py:run)
Input:            {"action": "process", "data": "sample"}

OUTPUT:
{
  "status": "completed",
  "result": "processed successfully"
}
```

### Step 6: Follow-up Actions
After execution, you can:
- **Run again** with different inputs
- **Create evaluation tests** for this agent
- **View trace data** for debugging

## Supported Input Types

The skill supports all JSON schema types:
- **string** - Text input
- **number** - Decimal numbers
- **integer** - Whole numbers
- **boolean** - Yes/No toggle
- **array** - List of items
- **object** - Complex nested data
- **enum** - Choice from predefined options

## Error Handling

If execution fails, I'll display:
- Error message from the agent
- Stack trace for debugging
- Suggestions for fixing the issue
- Option to re-run with modified inputs

## Integration

Execution traces are automatically collected and can be:
- Viewed in UiPath Cloud
- Analyzed for performance
- Used for debugging and optimization

Create agents with `/uipath-coded-agents:create-agent` and test them with this skill!
