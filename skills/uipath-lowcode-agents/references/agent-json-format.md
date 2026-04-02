# Agent JSON Format Reference

Schemas for the core agent definition files.

## Project Directory Structure

After `uip lowcodeagents init <name>`:

```
<AgentName>/
├── agent.json              # Main agent configuration (edit this)
├── entry-points.json       # Entry point definition (must mirror agent.json schemas)
├── project.uiproj          # Project metadata
├── flow-layout.json        # UI layout — do not edit
├── .agent-builder/         # Studio Web artifacts — do not edit
├── features/               # Context grounding (future)
└── resources/              # Escalations, tools, etc. (future)
```

## agent.json

Primary configuration file. Edit directly.

```json
{
  "version": "1.0.0",
  "settings": {
    "model": "<MODEL_IDENTIFIER>",
    "maxTokens": 16384,
    "temperature": 0,
    "engine": "basic-v2",
    "maxIterations": 25,
    "mode": "standard"
  },
  "inputSchema": {
    "type": "object",
    "required": ["<FIELD_NAME>"],
    "properties": {
      "<FIELD_NAME>": {
        "type": "string",
        "description": "<FIELD_DESCRIPTION>"
      }
    }
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "<FIELD_NAME>": {
        "type": "string",
        "description": "<FIELD_DESCRIPTION>"
      }
    }
  },
  "metadata": {
    "storageVersion": "50.0.0",
    "isConversational": false,
    "targetRuntime": "pythonAgent",
    "showProjectCreationExperience": false
  },
  "type": "lowCode",
  "projectId": "<AUTO_GENERATED_UUID>",
  "messages": [
    {
      "role": "system",
      "content": "<SYSTEM_PROMPT>",
      "contentTokens": [
        { "type": "simpleText", "rawString": "<SYSTEM_PROMPT>" }
      ]
    },
    {
      "role": "user",
      "content": "{{input.fieldName}}",
      "contentTokens": [
        { "type": "variable", "rawString": "input.fieldName" }
      ]
    }
  ]
}
```

### Settings

| Field | Description |
|-------|-------------|
| `model` | LLM identifier (e.g., `"anthropic.claude-sonnet-4-6"`, `"gpt-4.1-2025-04-14"`) |
| `maxTokens` | Max output tokens. Common: 16384, 32768. |
| `temperature` | 0 = deterministic, higher = creative |
| `engine` | Use `"basic-v2"` |
| `maxIterations` | Max agent loop iterations. Default 25. |
| `mode` | Use `"standard"` |

### Schema Types

| Type | Use For |
|------|---------|
| `"string"` | Text, JSON strings, formatted data |
| `"number"` | Numeric values with decimals |
| `"integer"` | Whole numbers |
| `"boolean"` | True/false flags |
| `"object"` | Nested structures |
| `"array"` | Lists |

### Metadata (do not modify)

| Field | Value |
|-------|-------|
| `storageVersion` | Use value from init |
| `isConversational` | `false` (autonomous agents) |
| `targetRuntime` | `"pythonAgent"` |
| `type` | `"lowCode"` |
| `projectId` | Auto-generated UUID — do not edit |

## Messages

### System Message

Sets the agent's role and behavior. Typically plain text with no variables:

```json
{
  "role": "system",
  "content": "You are a classifier. Categorize the input and explain your reasoning.",
  "contentTokens": [
    { "type": "simpleText", "rawString": "You are a classifier. Categorize the input and explain your reasoning." }
  ]
}
```

### User Message

Templates input fields into the prompt using `{{input.fieldName}}`:

```json
{
  "role": "user",
  "content": "Document: {{input.documentText}} Category options: {{input.categories}}",
  "contentTokens": [
    { "type": "simpleText", "rawString": "Document: " },
    { "type": "variable", "rawString": "input.documentText" },
    { "type": "simpleText", "rawString": " Category options: " },
    { "type": "variable", "rawString": "input.categories" }
  ]
}
```

## contentTokens Construction

Every message needs both `content` (string) and `contentTokens` (array). Keep them in sync.

**Rules:**
1. Text outside `{{ }}` → `{ "type": "simpleText", "rawString": "<text>" }`
2. Text inside `{{ }}` → `{ "type": "variable", "rawString": "input.fieldName" }` (strip delimiters)
3. Every segment including whitespace gets its own entry

**Example — adjacent variables:**

Content: `"{{input.field1}} {{input.field2}}"`

```json
"contentTokens": [
  { "type": "variable", "rawString": "input.field1" },
  { "type": "simpleText", "rawString": " " },
  { "type": "variable", "rawString": "input.field2" }
]
```

**Common mistakes:**
- Forgetting to update contentTokens after editing content
- Including `{{` or `}}` in the variable rawString
- Missing whitespace tokens between adjacent variables

## entry-points.json

Defines how the agent is invoked. Schemas must exactly mirror agent.json.

```json
{
  "$schema": "https://cloud.uipath.com/draft/2024-12/entry-point",
  "$id": "entry-points.json",
  "entryPoints": [
    {
      "filePath": "/content/agent.json",
      "uniqueId": "<AUTO_GENERATED_UUID>",
      "type": "agent",
      "input": {
        "type": "object",
        "properties": { },
        "required": []
      },
      "output": {
        "type": "object",
        "properties": { }
      }
    }
  ]
}
```

### Sync Rule

| agent.json | entry-points.json |
|-----------|-------------------|
| `inputSchema.properties.<field>` | `entryPoints[0].input.properties.<field>` |
| `inputSchema.required` | `entryPoints[0].input.required` |
| `outputSchema.properties.<field>` | `entryPoints[0].output.properties.<field>` |

Do not modify `filePath`, `uniqueId`, or `type`.

## project.uiproj

```json
{
  "ProjectType": "Agent",
  "Name": "<AGENT_NAME>",
  "Description": null,
  "MainFile": null
}
```

Only `Name` and `Description` are editable. `ProjectType` and `MainFile` are fixed.

## Auto-Generated Files (do not edit)

| File | Managed By |
|------|------------|
| `flow-layout.json` | Studio Web |
| `.agent-builder/*` | Studio Web |
| `.project/JitCustomTypes.json` | Build system |
