# Evaluations Guide

Evaluation sets define test cases for verifying agent behavior. Each test case provides inputs and expected outputs, and evaluators score the agent's actual performance.

## Table of Contents

- [File Structure](#file-structure)
- [Evaluation Set Schema](#evaluation-set-schema)
- [Evaluator Types](#evaluator-types)
- [Creating Test Cases](#creating-test-cases)
- [Running Evaluations](#running-evaluations)
- [Best Practices](#best-practices)

## File Structure

```
evals/
├── eval-sets/
│   ├── evaluation-set-default.json         # Default eval set (created by init)
│   └── evaluation-set-<timestamp>.json     # Additional eval sets
└── evaluators/
    ├── evaluator-default.json              # Output similarity evaluator
    └── evaluator-default-trajectory.json   # Trajectory/behavior evaluator
```

Every evaluation set references evaluators by ID. The evaluator files must exist in `evals/evaluators/` and their `id` must match the `evaluatorRefs` entries in the eval set.

## Evaluation Set Schema

```json
{
  "fileName": "evaluation-set-default.json",
  "id": "<UUID>",
  "name": "<EVAL_SET_DISPLAY_NAME>",
  "batchSize": 10,
  "evaluatorRefs": [
    "<EVALUATOR_UUID_1>",
    "<EVALUATOR_UUID_2>"
  ],
  "evaluations": [
    {
      "id": "<UUID>",
      "name": "<TEST_CASE_NAME>",
      "inputs": {
        "<FIELD_NAME>": "<TEST_VALUE>"
      },
      "expectedOutput": {
        "<FIELD_NAME>": "<EXPECTED_VALUE>"
      },
      "evaluationCriterias": {
        "<EVALUATOR_UUID>": {
          "expectedAgentBehavior": "<DESCRIPTION_OF_EXPECTED_BEHAVIOR>"
        }
      },
      "simulationInstructions": "<OPTIONAL_SIMULATION_CONTEXT>",
      "simulatedToolToCall": "<OPTIONAL_TOOL_NAME>"
    }
  ],
  "modelSettings": [],
  "createdAt": "<ISO_TIMESTAMP>",
  "updatedAt": "<ISO_TIMESTAMP>",
  "agentMemoryEnabled": false,
  "agentMemorySettings": [],
  "lineByLineEvaluation": false
}
```

### Key Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | UUID for the eval set |
| `name` | string | Descriptive name (e.g., "Smoke Test", "Edge Cases") |
| `batchSize` | number | Parallel evaluation batch size. Default 10. |
| `evaluatorRefs` | array | UUIDs of evaluators to apply to all test cases |
| `evaluations` | array | Individual test cases |
| `evaluations[].inputs` | object | Input values matching agent's `inputSchema` fields |
| `evaluations[].expectedOutput` | object | Expected output values for similarity scoring |
| `evaluations[].evaluationCriterias` | object | Per-evaluator criteria, keyed by evaluator UUID |
| `evaluations[].simulationInstructions` | string | Optional context for trajectory evaluator |
| `evaluations[].simulatedToolToCall` | string | Tool the simulated user should call (for escalation testing) |

### Input Field Matching

Test case `inputs` field names and types must match the agent's `inputSchema.properties`. If the agent requires `documentFields` (string), the test case must provide `"documentFields": "..."`.

## Evaluator Types

### Default Output Evaluator (Semantic Similarity)

Scores how closely the agent's actual output matches the expected output using LLM-based semantic comparison.

```json
{
  "fileName": "evaluator-default.json",
  "id": "<UUID>",
  "name": "Default Evaluator",
  "description": "An evaluator that uses a LLM to score the similarity of the actual output to the expected output",
  "category": 1,
  "type": 5,
  "prompt": "As an expert evaluator, analyze the semantic similarity of these JSON contents to determine a score from 0-100. Focus on comparing the meaning and contextual equivalence of corresponding fields, accounting for alternative valid expressions, synonyms, and reasonable variations in language while maintaining high standards for accuracy and completeness. Provide your score with a justification, explaining briefly and concisely why you gave that score.\n----\nExpectedOutput:\n{{ExpectedOutput}}\n----\nActualOutput:\n{{ActualOutput}}\n",
  "model": "same-as-agent",
  "targetOutputKey": "*",
  "createdAt": "<ISO_TIMESTAMP>",
  "updatedAt": "<ISO_TIMESTAMP>"
}
```

| Field | Value | Description |
|-------|-------|-------------|
| `category` | `1` | Output evaluator category |
| `type` | `5` | LLM-based semantic similarity type |
| `prompt` | template | Scoring prompt with `{{ExpectedOutput}}` and `{{ActualOutput}}` placeholders |
| `model` | `"same-as-agent"` | Use the same model as the agent, or specify a model identifier |
| `targetOutputKey` | `"*"` | Evaluate all output fields |

### Default Trajectory Evaluator (Behavior Assessment)

Scores how well the agent behaved during execution — whether it used the right tools, escalated correctly, and followed instructions.

```json
{
  "fileName": "evaluator-default-trajectory.json",
  "id": "<UUID>",
  "name": "Default Trajectory Evaluator",
  "description": "An evaluator that judges the agent based on its run history and expected behavior",
  "category": 3,
  "type": 7,
  "prompt": "As an expert evaluator, determine how well the agent did on a scale of 0-100. Focus on if the simulation was successful and if the agent behaved according to the expected output accounting for alternative valid expressions, and reasonable variations in language while maintaining high standards for accuracy and completeness. Provide your score with a justification, explaining briefly and concisely why you gave that score.\n----\nUserOrSyntheticInputGivenToAgent:\n{{UserOrSyntheticInput}}\n----\nSimulationInstructions:\n{{SimulationInstructions}}\n----\nExpectedAgentBehavior:\n{{ExpectedAgentBehavior}}\n----\nAgentRunHistory:\n{{AgentRunHistory}}\n",
  "model": "same-as-agent",
  "targetOutputKey": "*",
  "createdAt": "<ISO_TIMESTAMP>",
  "updatedAt": "<ISO_TIMESTAMP>"
}
```

| Field | Value | Description |
|-------|-------|-------------|
| `category` | `3` | Trajectory evaluator category |
| `type` | `7` | LLM-based trajectory assessment type |
| `prompt` | template | Scoring prompt with `{{UserOrSyntheticInput}}`, `{{SimulationInstructions}}`, `{{ExpectedAgentBehavior}}`, `{{AgentRunHistory}}` placeholders |

### Custom Evaluator Prompts

Customize the `prompt` field to score specific aspects. For example, the BadDebtAgent uses a custom output evaluator that:
- Ignores the `explanation` field
- Deducts 15 points per incorrect field value
- Tolerates formatting differences (e.g., `100` vs `100%`, case differences)

And a custom trajectory evaluator that:
- Gives 0 points if escalation was triggered incorrectly
- Gives 0 points if escalation was missed when required
- Gives 100 points for correct escalation behavior

## Creating Test Cases

### Step 1: Identify Scenarios

Cover these categories:
- **Happy path**: Standard inputs → expected outputs
- **Edge cases**: Boundary values, empty optional fields, unusual combinations
- **Escalation triggers**: Inputs that should (and shouldn't) trigger escalations
- **Resource usage**: Cases that exercise tools, contexts, or memory spaces

### Step 2: Build the Test Case

Each evaluation entry needs:

```json
{
  "id": "<UUID>",
  "name": "ShouldEscalate_SpecificPlusPTP",
  "inputs": {
    "bad_debt_allowance_percentage": "35",
    "bad_debt_amount": "3500",
    "open_balance": "17500",
    "average_overdue_days": "100",
    "country": "United Kingdom",
    "invoiceNumber": "CASE004",
    "customerName": "TestCo",
    "tesorio_comment": "Specific Provision",
    "tesorio_tag": "Promise of payment (PTP)"
  },
  "expectedOutput": {
    "isSpecific": "True",
    "bad_debt_allowance_percentage": "100",
    "bad_debt_amount": "17500.00",
    "adjustedAllowanceAmount": "17500.00",
    "region": "EMEA",
    "isContradiction": "True"
  },
  "evaluationCriterias": {
    "<TRAJECTORY_EVALUATOR_UUID>": {
      "expectedAgentBehavior": "Agent should detect contradiction between specific provision and PTP tag, and trigger escalation"
    }
  },
  "simulatedToolToCall": "escalate_contradiction_escalation"
}
```

### Step 3: Reference Evaluators

Ensure every evaluator UUID in `evaluatorRefs` has a matching file in `evals/evaluators/`. The evaluator's `id` field must match the UUID referenced in the eval set.

## Running Evaluations

Low-code agent evaluations are run through Studio Web:

1. **Bundle and upload** the solution: `uip solution bundle --output json && uip solution upload --output json`
2. Open the agent in **Studio Web**
3. Navigate to the **Evaluate** tab
4. Select an evaluation set and run it

Results show per-test-case scores for each evaluator, with detailed justifications.

> There is no local evaluation command for low-code agents. All evaluation execution happens through Studio Web.

## Best Practices

1. **Start with a smoke test** — create 2-3 basic test cases that cover the agent's primary function before adding edge cases.

2. **Name test cases descriptively** — `ShouldEscalate_SpecificPlusPTP` is better than `test_1`. Names should tell you what the case tests at a glance.

3. **Test escalation boundaries** — for agents with escalations, include cases that should trigger escalation AND cases that should NOT. The trajectory evaluator catches escalation errors that output similarity misses.

4. **Match agent inputSchema exactly** — test case `inputs` keys must match `inputSchema.properties` names. Missing required fields or extra fields cause evaluation failures.

5. **Use both evaluator types** — output evaluators check the result; trajectory evaluators check the process. An agent might produce the right answer through the wrong process (e.g., escalating when it shouldn't, then using the reviewer's answer).

6. **Customize evaluator prompts** when defaults are too lenient — if specific output fields must be exact (amounts, flags), add per-field deduction rules to the evaluator prompt.

7. **Test with realistic data** — use values representative of production inputs, not placeholder strings. This catches formatting, type coercion, and edge-case handling issues.
