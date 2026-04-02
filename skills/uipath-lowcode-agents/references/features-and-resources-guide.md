# Features and Resources Guide

Features and resources extend a low-code agent's capabilities beyond basic prompt-based reasoning. Features provide context (memory spaces for RAG), while resources provide actions (escalations, tools, contexts, MCPs).

## Table of Contents

- [Overview](#overview)
- [Features: Memory Spaces](#features-memory-spaces)
- [Resources: Escalations](#resources-escalations)
- [Resources: Tools](#resources-tools)
- [Resources: Contexts](#resources-contexts)
- [Resources: MCPs](#resources-mcps)
- [Directory Naming](#directory-naming)

## Overview

| Type | Purpose | Directory | Config File |
|------|---------|-----------|-------------|
| Memory Space | RAG — retrieves similar past cases for few-shot learning | `features/<Name>/` | `feature.json` |
| Escalation | Routes to human reviewers via Action Center | `resources/<Name>/` | `resource.json` |
| Tool | Calls other processes, API workflows, or agents | `resources/<Name>/` | `resource.json` |
| Context | References ECS indexes for document grounding | `resources/<Name>/` | `resource.json` |
| MCP | Connects to MCP servers | `resources/<Name>/` | `resource.json` |

Each feature and resource must have a unique identifier (`referenceKey` for features, `id` for resources) across the entire project.

## Features: Memory Spaces

Memory spaces enable dynamic few-shot learning. The agent retrieves similar past cases from an indexed memory space and uses them as examples when processing new inputs.

### Directory Structure

```
features/
└── <MemorySpaceName>/
    └── feature.json
```

### feature.json Schema

```json
{
  "$featureType": "memorySpace",
  "id": "<UUID>",
  "referenceKey": "<UUID>",
  "folderPath": "solution_folder",
  "name": "<DISPLAY_NAME>",
  "memorySpaceName": "<MEMORY_SPACE_NAME>",
  "description": "",
  "isEnabled": true,
  "dynamicFewShotSettings": {
    "isEnabled": true,
    "threshold": 0.21,
    "resultCount": 3,
    "searchMode": "hybrid",
    "fieldSettings": [
      {
        "id": "<UUID>",
        "name": "<INPUT_FIELD_NAME>",
        "weight": 1
      }
    ]
  }
}
```

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `$featureType` | string | Always `"memorySpace"` |
| `id` | string | Unique UUID for this feature |
| `referenceKey` | string | UUID used in bindings to link to Orchestrator index |
| `folderPath` | string | Orchestrator folder path. Use `"solution_folder"` for solution-relative. |
| `name` | string | Display name for the memory space |
| `memorySpaceName` | string | Name of the memory space in Orchestrator |
| `isEnabled` | boolean | Whether the memory space is active |
| `dynamicFewShotSettings.isEnabled` | boolean | Enable few-shot retrieval |
| `dynamicFewShotSettings.threshold` | number | Similarity threshold (0.0–1.0). Lower = more results. Typical: 0.2–0.3. |
| `dynamicFewShotSettings.resultCount` | number | Max examples to retrieve. Typical: 3–5. |
| `dynamicFewShotSettings.searchMode` | string | `"hybrid"`, `"semantic"`, or `"keyword"` |
| `dynamicFewShotSettings.fieldSettings` | array | Input fields to use for similarity search, with relative weights |

### Search Modes

| Mode | Description | Best For |
|------|-------------|----------|
| `hybrid` | Combines semantic and keyword search | General use (recommended) |
| `semantic` | Vector similarity only | Meaning-based matching |
| `keyword` | Exact/partial keyword matching | Structured data with known terms |

### Example: Memory Space from BadDebtAgent

```json
{
  "$featureType": "memorySpace",
  "id": "32d424af-03ff-49b8-b4e0-6e2ff79cccc8",
  "referenceKey": "c6bf99a8-7967-4cfe-b384-cd8cf8f3ea95",
  "folderPath": "solution_folder",
  "name": "COE28595_MemorySpace",
  "memorySpaceName": "MemorySpace",
  "description": "",
  "isEnabled": true,
  "dynamicFewShotSettings": {
    "isEnabled": true,
    "threshold": 0.21,
    "resultCount": 3,
    "searchMode": "hybrid",
    "fieldSettings": [
      {
        "id": "1d66838b-0fbd-4f35-970a-5fb0a96037f0",
        "name": "tesorio_comment",
        "weight": 1
      },
      {
        "id": "8f37cfd0-c352-4fb2-b50c-4fb30bef77d1",
        "name": "tesorio_tag",
        "weight": 1
      }
    ]
  }
}
```

This memory space searches for similar cases using `tesorio_comment` and `tesorio_tag` fields (equally weighted), returning the top 3 matches above a 0.21 similarity threshold using hybrid search.

## Resources: Escalations

Escalations route decisions to human reviewers via UiPath Action Center when the agent encounters situations requiring human judgment.

### Directory Structure

```
resources/
└── <EscalationName>/
    └── resource.json
```

### resource.json Schema (Escalation)

```json
{
  "$resourceType": "escalation",
  "id": "<UUID>",
  "name": "<DISPLAY_NAME>",
  "description": "<WHEN_TO_ESCALATE>",
  "channels": [
    {
      "id": "<UUID>",
      "name": "Channel",
      "description": "Channel description",
      "inputSchema": {
        "type": "object",
        "properties": { },
        "required": []
      },
      "outputSchema": {
        "type": "object",
        "properties": { }
      },
      "outcomeMapping": {
        "<OUTCOME_NAME>": "<ACTION>"
      },
      "recipients": [
        {
          "type": 2,
          "value": "<GROUP_UUID>",
          "displayName": "<GROUP_NAME>"
        }
      ],
      "type": "actionCenter",
      "labels": ["<LABEL>"],
      "properties": {
        "appName": "<ESCALATION_APP_NAME>",
        "appVersion": 1,
        "folderName": null,
        "resourceKey": "<UUID>",
        "isActionableMessageEnabled": false
      }
    }
  ],
  "isAgentMemoryEnabled": false,
  "governanceProperties": {
    "isEscalatedAtRuntime": false
  },
  "escalationType": 0
}
```

### Key Escalation Fields

| Field | Description |
|-------|-------------|
| `description` | Tells the agent when to trigger this escalation. Be specific. |
| `channels[].inputSchema` | Data the agent sends to the reviewer |
| `channels[].outputSchema` | Data the reviewer can override |
| `channels[].outcomeMapping` | Maps reviewer actions to agent behavior. `"continue"` resumes the agent, `"end"` stops it. |
| `channels[].recipients` | Action Center groups who receive the escalation. Type 2 = group. |
| `channels[].labels` | Tags for categorizing escalations in Action Center |
| `channels[].properties.appName` | Name of the escalation app in Action Center |

### Outcome Mapping

| Outcome | Action | Description |
|---------|--------|-------------|
| `"continue"` | Agent resumes | Use when reviewer provides overrides and agent should incorporate them |
| `"end"` | Agent stops | Use when the escalation resolves the task entirely |

### Example: Escalation from BadDebtAgent

The Contradiction Escalation triggers when `isContradiction` is true, sends invoice data to a reviewer group, and continues with reviewer overrides:

```json
{
  "$resourceType": "escalation",
  "id": "46632561-ac2a-4597-b62a-771c5719a6e4",
  "name": "Contradiction Escalation",
  "description": "Use this escalation when isContradiction is equivalent to true. Gets human input.",
  "channels": [
    {
      "id": "2d0f1a97-b183-47ff-9bd4-9f8c46231af3",
      "name": "Channel",
      "description": "Channel description",
      "inputSchema": {
        "type": "object",
        "properties": {
          "InvoiceNumber": { "type": "string", "description": "The unique identifier for the invoice" },
          "OpenBalance": { "type": "string", "description": "The current open balance of the account" },
          "Explanation": { "type": "string", "description": "The explanation for the escalation" }
        },
        "required": ["InvoiceNumber", "OpenBalance"]
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "BDAllowance": { "type": "string" },
          "bdAllowanceAmount": { "type": "string" },
          "Explanation": { "type": "string" }
        }
      },
      "outcomeMapping": { "Process": "continue" },
      "recipients": [
        {
          "type": 2,
          "value": "b3e8ecff-ee05-4f34-a97b-62b8a01550a6",
          "displayName": "COE28595_ActionGroup"
        }
      ],
      "type": "actionCenter",
      "labels": ["Contradiction"],
      "properties": {
        "appName": "COE28595_EscalationApp",
        "appVersion": 1,
        "folderName": null,
        "resourceKey": "08271606-7162-4baf-8b7d-0cff19e0e659",
        "isActionableMessageEnabled": false
      }
    }
  ],
  "isAgentMemoryEnabled": false,
  "governanceProperties": { "isEscalatedAtRuntime": false },
  "escalationType": 0
}
```

## Resources: Tools

Tools allow the agent to invoke external processes, API workflows, or other agents as callable actions during execution.

### Directory Structure

```
resources/
└── <ToolName>/
    └── resource.json
```

### resource.json Schema (Tool)

Tools follow the same general structure as escalations with `$resourceType: "tool"`. The schema includes:

```json
{
  "$resourceType": "tool",
  "id": "<UUID>",
  "name": "<TOOL_DISPLAY_NAME>",
  "description": "<WHAT_THE_TOOL_DOES>",
  ...
}
```

Tool resources can reference:
- **Other processes** — invoke RPA workflows or coded workflows
- **API workflows** — call external APIs through UiPath
- **Other agents** — orchestrate sub-agents

> **Note:** Specific tool resource schemas are being refined. Follow the general resource pattern (unique `id`, descriptive `name` and `description`, input/output schemas). Check Studio Web for the latest tool configuration options.

## Resources: Contexts

Contexts connect the agent to Enterprise Content Service (ECS) indexes for document-based context grounding.

### Directory Structure

```
resources/
└── <ContextName>/
    └── resource.json
```

### resource.json Schema (Context)

```json
{
  "$resourceType": "context",
  "id": "<UUID>",
  "name": "<CONTEXT_DISPLAY_NAME>",
  "description": "<WHAT_DOCUMENTS_THIS_PROVIDES>",
  ...
}
```

Context resources reference ECS indexes that contain indexed documents. The agent can search these indexes to ground its responses in specific document content.

> **Note:** Specific context resource schemas are being refined. Follow the general resource pattern. Check Studio Web for the latest context configuration options.

## Resources: MCPs

MCP (Model Context Protocol) resources connect the agent to MCP servers, enabling structured tool and resource access through the MCP protocol.

### Directory Structure

```
resources/
└── <McpName>/
    └── resource.json
```

### resource.json Schema (MCP)

```json
{
  "$resourceType": "mcp",
  "id": "<UUID>",
  "name": "<MCP_DISPLAY_NAME>",
  "description": "<WHAT_THE_MCP_SERVER_PROVIDES>",
  ...
}
```

> **Note:** Specific MCP resource schemas are being refined. Follow the general resource pattern. Check Studio Web for the latest MCP configuration options.

## Directory Naming

Feature and resource directories use descriptive PascalCase or descriptive names:

```
features/
├── CustomerMemorySpace/
└── ProductCatalog/

resources/
├── Contradiction Escalation/      # Spaces allowed
├── InvoiceLookupTool/
├── DocumentIndex/
└── SlackMcpServer/
```

The directory name is for human readability. The `name` field inside the JSON config is what the agent sees and references.
