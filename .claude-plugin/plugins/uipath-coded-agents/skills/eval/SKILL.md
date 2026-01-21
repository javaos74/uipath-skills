---
description: Create and run evaluations for UiPath agents
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion
---

# Evaluations

Create comprehensive test cases and execute evaluations for your UiPath agents using the UiPath evaluation framework.

## What is an Evaluation?

Evaluations assess agent performance by comparing actual outputs against expected results. The framework provides two evaluation categories:

### 📊 Output-Based Evaluators
Measure final results and validate outputs:
- **ExactMatchEvaluator** - Verify exact string matching
- **JsonSimilarityEvaluator** - Compare JSON structure similarity
- **LLMJudgeOutputEvaluator** - LLM-powered semantic assessment of outputs
- **ContainsEvaluator** - Check if output contains specific text

Use these for validating what your agent returns.

### 🔄 Trajectory-Based Evaluators
Examine execution patterns and decision sequences:
- **TrajectoryEvaluator** - Validate tool call sequences, frequencies, and arguments during agent execution

Use these for validating how your agent makes decisions and executes steps.

## Quick Start

### Create New Evaluations
- Define test cases with input/output pairs
- Specify evaluation criteria (exact match, JSON similarity, LLM judge, trajectory, etc.)
- Organize tests by scenario (happy path, edge cases, errors)

### Run Existing Evaluations
- Execute all or selected evaluation sets
- Configure parallel workers and caching
- View detailed results with scores (0.0-1.0 range), justification, and execution traces

## Unified Workflow

### Phase 1: Setup Check
I'll verify your project has:
- `uipath.json` - Project configuration
- `entry-points.json` - Agent definitions
- `evaluations/` directory for test cases

If missing, create an agent first with `/uipath-coded-agents:create-agent`.

### Phase 2: Action Selection
I'll ask what you want to do:
1. **Create new evaluations** - Design test cases for your agent
2. **Run existing evaluations** - Execute and analyze test results

## Creating Evaluations

### Define Evaluation Details
I'll ask for:
- **Evaluation Set Name** - Identifier for this evaluation set
- **Description** - What scenarios this covers
- **Target Agent** - Which agent to test
- **Number of Test Cases** - How many tests to create

### Collect Test Cases
For each test, I'll guide you through:
- **Inputs** - Based on agent's input schema with validation
- **Expected Output** - What the agent should return
- **Evaluation Criteria** - How to validate (from available evaluators)
- **Test Metadata** - ID, name, and purpose

### Available Evaluators

#### Output-Based Evaluators

**ExactMatchEvaluator** (`uipath-exact-match`)
- Verifies exact string matching
- Best for: Deterministic results, specific outputs, calculator agents
- Configuration: `case_sensitive`, `negated`
- Score: 1.0 (match) or 0.0 (no match)

**ContainsEvaluator** (`uipath-contains`)
- Checks if output contains specific text
- Best for: Partial text validation, keyword checking
- Configuration: `searchText`, `ignoreCase`
- Score: 1.0 (contains) or 0.0 (not found)

**JsonSimilarityEvaluator** (`uipath-json-similarity`)
- Compares JSON structure and content similarity
- Best for: Complex JSON responses, flexible structure validation
- Provides similarity score (0.0-1.0) for partial matches
- Score: Range 0.0-1.0 based on JSON similarity

**LLMJudgeOutputEvaluator** (`uipath-llm-judge-output-semantic-similarity`)
- LLM-based semantic validation of outputs
- Best for: Natural language outputs, semantic equivalence, flexible responses
- Configuration: `model`, `temperature`, `prompt`
- Score: 0-100 (converted to 0.0-1.0 scale)
- Requires: API credentials for LLM

**LLMJudgeStrictJSONSimilarityOutputEvaluator** (`uipath-llm-judge-output-strict-json-similarity`)
- LLM validates strict JSON structure matching
- Best for: Strict JSON validation with LLM intelligence
- Configuration: `model`, `temperature`, `prompt`
- Score: 0-100 (converted to 0.0-1.0 scale)

#### Trajectory-Based Evaluators

**TrajectoryEvaluator** (`uipath-llm-judge-trajectory-similarity`)
- Evaluates agent's execution trajectory and decision sequence
- Best for: Multi-step agents, tool usage validation, behavior verification
- Validates: Tool call sequences, frequencies, arguments, execution order
- Configuration: `model`, `temperature`, `expectedAgentBehavior`
- Score: 0-100 (converted to 0.0-1.0 scale)
- Requires: Agent execution traces available

#### Custom Evaluators

When built-in evaluators are insufficient, implement domain-specific validators with:
- Custom validation logic
- Specialized scoring algorithms
- Integrations with external validation systems
- Industry-specific rules or compliance checks

### Choosing the Right Evaluator

| Scenario | Recommended Evaluator | Reason |
|----------|---------------------|--------|
| Mathematical/calculator output | ExactMatchEvaluator | Deterministic results need exact match |
| Text must contain keywords | ContainsEvaluator | Check for required keywords |
| Complex JSON structures | JsonSimilarityEvaluator | Flexible structure matching |
| Natural language output | LLMJudgeOutputEvaluator | Semantic equivalence over exact match |
| Multi-step decisions | TrajectoryEvaluator | Validate execution flow and tool usage |
| Strict JSON validation | LLMJudgeStrictJSONSimilarityOutputEvaluator | LLM ensures structure correctness |
| Domain-specific rules | Custom Evaluator | Implement business-specific validation |

### Evaluation Scoring

All evaluators return numeric scores:
- **1.0** - Perfect pass
- **0.5-0.9** - Partial success (for similarity-based evaluators)
- **0.0** - Complete failure

Results also include:
- **Justification** - Why the score was given
- **Execution metrics** - Performance data
- **Complete traces** - Full execution history for debugging

#### Creating Custom Evaluators

Evaluators are defined in `evaluations/evaluators/` as JSON files.

**ExactMatchEvaluator Example:**
```json
{
  "version": "1.0",
  "id": "ExactMatchEvaluator",
  "description": "Checks if the response text exactly matches the expected value.",
  "evaluatorTypeId": "uipath-exact-match",
  "evaluatorConfig": {
    "name": "ExactMatchEvaluator",
    "targetOutputKey": "result",
    "negated": false,
    "ignoreCase": false,
    "defaultEvaluationCriteria": {
      "expectedOutput": {
        "result": "5.0"
      }
    }
  }
}
```

**ContainsEvaluator Example:**
```json
{
  "version": "1.0",
  "id": "ContainsEvaluator",
  "description": "Checks if the response text includes the expected value.",
  "evaluatorTypeId": "uipath-contains",
  "evaluatorConfig": {
    "name": "ContainsEvaluator",
    "targetOutputKey": "result",
    "negated": false,
    "ignoreCase": false,
    "defaultEvaluationCriteria": {
      "searchText": "5"
    }
  }
}
```

**JsonSimilarityEvaluator Example:**
```json
{
  "version": "1.0",
  "id": "JsonSimilarityEvaluator",
  "description": "Checks if the response JSON is similar to the expected JSON structure.",
  "evaluatorTypeId": "uipath-json-similarity",
  "evaluatorConfig": {
    "name": "JsonSimilarityEvaluator",
    "targetOutputKey": "*",
    "defaultEvaluationCriteria": {
      "expectedOutput": {
        "result": 5.0
      }
    }
  }
}
```

**LLMJudgeOutputEvaluator Example:**
```json
{
  "version": "1.0",
  "id": "LLMJudgeOutputEvaluator",
  "description": "Uses an LLM to judge semantic similarity between expected and actual output.",
  "evaluatorTypeId": "uipath-llm-judge-output-semantic-similarity",
  "evaluatorConfig": {
    "name": "LLMJudgeOutputEvaluator",
    "targetOutputKey": "*",
    "model": "gpt-4.1-2025-04-14",
    "temperature": 0.0,
    "prompt": "Compare the following outputs and evaluate their semantic similarity.\n\nActual Output: {{ActualOutput}}\nExpected Output: {{ExpectedOutput}}\n\nProvide a score from 0-100 where 100 means semantically identical and 0 means completely different.",
    "defaultEvaluationCriteria": {
      "expectedOutput": {
        "result": 5.0
      }
    }
  }
}
```

**LLMJudgeStrictJSONSimilarityOutputEvaluator Example:**
```json
{
  "version": "1.0",
  "id": "LLMJudgeStrictJSONSimilarityOutputEvaluator",
  "description": "Uses an LLM to judge strict JSON similarity between expected and actual output.",
  "evaluatorTypeId": "uipath-llm-judge-output-strict-json-similarity",
  "evaluatorConfig": {
    "name": "LLMJudgeStrictJSONSimilarityOutputEvaluator",
    "targetOutputKey": "*",
    "model": "gpt-4.1-2025-04-14",
    "temperature": 0.0,
    "prompt": "Compare the following JSON outputs for strict structural similarity.\n\nActual Output: {{ActualOutput}}\nExpected Output: {{ExpectedOutput}}\n\nEvaluate if the JSON structure and values match precisely. Provide a score from 0-100 where 100 means exact match and 0 means completely different.",
    "defaultEvaluationCriteria": {
      "expectedOutput": {
        "result": 5.0
      }
    }
  }
}
```

**TrajectoryEvaluator Example:**
```json
{
  "version": "1.0",
  "id": "TrajectoryEvaluator",
  "description": "Evaluates the agent's execution trajectory and decision sequence.",
  "evaluatorTypeId": "uipath-llm-judge-trajectory-similarity",
  "evaluatorConfig": {
    "name": "TrajectoryEvaluator",
    "model": "gpt-4.1-2025-04-14",
    "temperature": 0.0,
    "prompt": "Evaluate the agent's execution trajectory based on the expected behavior.\n\nExpected Agent Behavior: {{ExpectedAgentBehavior}}\nAgent Run History: {{AgentRunHistory}}\n\nProvide a score from 0-100 based on how well the agent followed the expected trajectory.",
    "defaultEvaluationCriteria": {
      "expectedAgentBehavior": "The agent should correctly perform the calculation and return the result."
    }
  }
}
```

**Key Fields in evaluatorConfig:**
- `name` - Display name of the evaluator
- `targetOutputKey` - Which output field to evaluate ("*" for all fields, or specific field name like "result")
- `negated` - (optional) Boolean to negate the evaluation result
- `ignoreCase` - (optional) For text-based evaluators, ignore case differences
- `model` - (LLM evaluators only) Model to use (e.g., "gpt-4.1-2025-04-14")
- `temperature` - (LLM evaluators only) Temperature for LLM (0.0 for deterministic)
- `prompt` - (LLM evaluators only) Evaluation prompt with {{ActualOutput}}, {{ExpectedOutput}}, {{ExpectedAgentBehavior}}, {{AgentRunHistory}} placeholders
- `searchText` - (ContainsEvaluator only) Text to search for in the output
- `defaultEvaluationCriteria` - Default expected output structure for the evaluator

### Generated File Structure
```
evaluations/
├── eval-sets/
│   ├── <eval-name>.json
│   └── <another-eval>.json
└── evaluators/
    ├── exact-match.json
    ├── json-similarity.json
    └── llm-judge-semantic-similarity.json
```

#### Creating Eval Sets

Evaluation sets are defined in `evaluations/eval-sets/` as JSON files.

**Basic Eval Set Schema:**
```json
{
  "version": "1.0",
  "id": "my-eval-set",
  "name": "My Evaluation Set",
  "evaluatorRefs": ["ExactMatchEvaluator", "JsonSimilarityEvaluator"],
  "evaluations": [
    {
      "id": "test-1-basic",
      "name": "Basic test case",
      "inputs": {
        "param1": "value1",
        "param2": 42
      },
      "evaluationCriterias": {
        "ExactMatchEvaluator": {
          "expectedOutput": {
            "result": "expected-value"
          }
        },
        "JsonSimilarityEvaluator": {
          "expectedOutput": {
            "result": "expected-value"
          }
        }
      }
    },
    {
      "id": "test-2-edge-case",
      "name": "Edge case test",
      "inputs": {
        "param1": "edge",
        "param2": 0
      },
      "evaluationCriterias": {
        "ExactMatchEvaluator": {
          "expectedOutput": {
            "result": "edge-result"
          }
        }
      }
    }
  ]
}
```

**With Mocking:**
```json
{
  "version": "1.0",
  "id": "eval-with-mocking",
  "name": "Evaluation with Mocked Functions",
  "evaluatorRefs": ["ExactMatchEvaluator"],
  "evaluations": [
    {
      "id": "test-mocked-function",
      "name": "Test with mocked external call",
      "inputs": {
        "param1": "value"
      },
      "evaluationCriterias": {
        "ExactMatchEvaluator": {
          "expectedOutput": {
            "result": "mocked-result"
          }
        }
      },
      "mockingStrategy": {
        "type": "mockito",
        "behaviors": [
          {
            "function": "external_function",
            "arguments": {
              "args": [],
              "kwargs": {}
            },
            "then": [
              {
                "type": "return",
                "value": {
                  "key": "mocked-value"
                }
              }
            ]
          }
        ]
      }
    }
  ]
}
```

**Key Fields:**
- `id` - Unique identifier for the eval set
- `name` - Human-readable name
- `evaluatorRefs` - List of evaluator IDs to use from `evaluations/evaluators/`
- `evaluations` - Array of test cases
  - `id` - Unique test case identifier
  - `name` - Test case description
  - `inputs` - Input parameters (must match agent's input schema)
  - `evaluationCriterias` - Map of evaluator ID to evaluation criteria
    - Contains evaluator-specific fields (e.g., `expectedOutput`, `expectedAgentBehavior`)
  - `mockingStrategy` (optional) - Mock external functions or LLM calls

#### Mocking Strategies

**Function Mocking (mockito):**
```json
"mockingStrategy": {
  "type": "mockito",
  "behaviors": [
    {
      "function": "external_api_call",
      "arguments": {
        "args": ["param1"],
        "kwargs": {"key": "value"}
      },
      "then": [
        {
          "type": "return",
          "value": {
            "status": "success",
            "data": "mocked-response"
          }
        }
      ]
    },
    {
      "function": "another_function",
      "arguments": {
        "args": [],
        "kwargs": {}
      },
      "then": [
        {
          "type": "raise",
          "value": {
            "_target_": "ValueError"
          }
        }
      ]
    }
  ]
}
```

**LLM Call Mocking:**
```json
"mockingStrategy": {
  "type": "llm",
  "prompt": "Test prompt describing the expected LLM behavior",
  "toolsToSimulate": [
    {
      "name": "tool_name"
    },
    {
      "name": "another_tool"
    }
  ]
}
```

**Mockito Mock Behavior Types (for functions):**
- `type: "return"` - Return a value
- `type: "raise"` - Throw an exception

**LLM Mock Fields:**
- `prompt` - Description of how the LLM should behave
- `toolsToSimulate` - Array of tools the LLM can call/simulate
  - `name` - Tool identifier

## Running Evaluations

### Evaluation Discovery
I'll scan for evaluation sets in `evaluations/eval-sets/*.json`.

Display format:
```
AVAILABLE EVALUATIONS
═════════════════════════════════════════════════════════

1. evaluations/eval-sets/happy-path-scenarios.json
   └─ Tests: 3 | Last run: 2 hours ago

2. evaluations/eval-sets/edge-cases.json
   └─ Tests: 5 | Last run: Never

3. evaluations/eval-sets/error-scenarios.json
   └─ Tests: 4 | Last run: 1 day ago
```

### Execution Configuration
I'll ask for:
- **Evaluation Set** - Which eval set to run
- **Number of Workers** - Parallel execution (1-8, default: 4)
- **Enable Mocker Cache** - Cache LLM responses for reproducibility (default: False)
- **Report to Studio** - Send results to UiPath Cloud (optional, default: False)

### Evaluation Execution
```bash
uv run uipath eval <entrypoint> <eval-file> \
  --workers 4 \
  --no-report \
  --output-file eval-results.json
```

### Results Display

Results include:
- **Numeric Scores** - Typically 0.0-1.0 range for each test
- **Detailed Justification** - Why each evaluator gave that score
- **Execution Metrics** - Test execution time and performance data
- **Complete Traces** - Full execution history including function calls and state changes

### Understanding Results

**Pass vs Fail:**
- **Pass (1.0)** - Evaluator criteria fully met
- **Partial (0.5-0.9)** - Similarity-based evaluators show partial match
- **Fail (0.0)** - Evaluator criteria not met

**Result Breakdown:**
```
Test: calculate_sum
├─ Input: {"num1": 5, "num2": 3}
├─ Expected Output: {"result": 8}
├─ Actual Output: {"result": 8}
├─ ExactMatchEvaluator: PASS (1.0) - Output exactly matches expected
├─ JsonSimilarityEvaluator: PASS (1.0) - JSON structure identical
└─ Execution Time: 125ms
```

### Detailed Analysis
For each failing or warning test, I'll show:
- Input/output pairs
- Expected vs actual results
- Evaluator scores and justification
- Execution traces for debugging
- Suggestions for fixes

### Follow-up Actions

After running evaluations, ask user if they would like to:
- **Create More Evaluations** - Add additional evaluation sets
- **Fix Issues** - I can help modify agent code
- **Re-run Evaluations** - Execute with different config
- **View Details** - Detailed breakdown of each test
- **Export Results** - Save results to JSON
- **Compare Runs** - Track improvements over time

## Test Organization

### Test Case Types

**Happy Path Tests:**
- Normal operations with typical inputs
- Expected successful outcomes
- Standard use cases

**Edge Case Tests:**
- Boundary values (0, min, max)
- Empty/null values
- Large datasets
- Special characters

**Error Scenario Tests:**
- Invalid input types
- Missing required fields
- Out-of-range values
- Expected error messages

### Schema Validation

Evaluations are validated against:
- Agent's input schema from `entry-points.json`
- Agent's output schema from `entry-points.json`
- Required field constraints
- Type compatibility

## Analysis & Metrics

**Test Coverage:**
- Input space coverage - Which input combinations are tested
- Output validation - Coverage of different scenarios
- Edge cases - Boundary conditions and error paths
- Gap recommendations - Suggest missing test cases

**Performance Tracking:**
- Execution time per test and total
- Pass rate trends
- Score distribution across evaluators
- Performance improvements over time

## Integration with UiPath Cloud

Results can be:
- Reported to UiPath Cloud for monitoring
- Integrated with CI/CD pipelines
- Compared with previous runs
- Used for performance tracking

## Evaluation Best Practices

✅ **Do:**
- Use multiple evaluators for comprehensive validation
- Mix output-based and trajectory-based evaluators for complex agents
- Create separate eval sets for different scenarios (happy path, edge cases, errors)
- Use trajectory evaluators for agents with multiple steps/tools
- Use LLM evaluators for natural language or fuzzy matching scenarios
- Start with ExactMatch for deterministic outputs, then add LLM evaluators for flexibility

❌ **Don't:**
- Use only ExactMatch for natural language outputs
- Forget to test edge cases and error scenarios
- Use trajectory evaluators when output-based is sufficient
- Set too strict criteria early in development
- Skip schema validation during test creation

## Common Evaluation Patterns

### Calculator/Deterministic Agents
```
Evaluators: ExactMatchEvaluator
Tests: Happy path, boundary values, error cases
Scoring: 1.0 (pass) or 0.0 (fail)
```

### Natural Language Agents
```
Evaluators: LLMJudgeOutputEvaluator, ContainsEvaluator
Tests: Semantic equivalence, required keywords, various phrasings
Scoring: 0.0-1.0 range based on semantic similarity
```

### Multi-Step Orchestration Agents
```
Evaluators: TrajectoryEvaluator, JsonSimilarityEvaluator
Tests: Tool sequences, decision flows, output structure
Scoring: 0.0-1.0 based on execution path and output match
```

## Documentation

For detailed information about the evaluation framework, scoring, and advanced features:
https://uipath.github.io/uipath-python/eval/

Start by creating evaluations or running existing ones!
