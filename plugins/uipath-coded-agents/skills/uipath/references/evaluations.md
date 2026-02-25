# UiPath Evaluations

Create comprehensive test cases and execute evaluations for your UiPath agents using the UiPath evaluation framework.

## What is an Evaluation?

Evaluations assess agent performance by comparing actual outputs against expected results. The framework provides tools to create test cases, define evaluation criteria, and run comprehensive test suites.

## Two Types of Evaluators

**📊 Output-Based Evaluators** - Measure final results and validate outputs:
- ExactMatchEvaluator
- JsonSimilarityEvaluator
- LLMJudgeOutputEvaluator
- ContainsEvaluator

**🔄 Trajectory-Based Evaluators** - Examine execution patterns and decision sequences:
- TrajectoryEvaluator

## Documentation

### Detailed Guides

- **[Creating Evaluations](evaluations/creating-evaluations.md)**
  - Define evaluation details
  - Collect test cases
  - Organize by scenario (happy path, edge cases, errors)
  - Mock external calls

- **[Evaluators Guide](evaluations/evaluators/README.md)**
  - All available evaluator types
  - Configuration options
  - Choosing the right evaluator
  - Creating custom evaluators
  - Evaluation scoring

- **[Evaluation Sets](evaluations/evaluation-sets.md)**
  - Evaluation set file structure
  - Test case schema
  - Complete examples
  - Mocking strategies
  - Best practices for organization

- **[Running Evaluations](evaluations/running-evaluations.md)**
  - Execution configuration
  - Understanding results
  - Detailed analysis
  - Performance optimization
  - Troubleshooting

- **[Best Practices & Common Patterns](evaluations/best-practices.md)**
  - Evaluation best practices
  - Common patterns by agent type
  - Test organization strategies
  - Performance optimization
  - Quick reference guides

## Generated File Structure

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

## Common Patterns at a Glance

### Calculator/Deterministic Agents
```
Evaluators: ExactMatchEvaluator
Tests: Happy path, boundary values, error cases
Scoring: 1.0 (pass) or 0.0 (fail)
```
See [Best Practices](evaluations/best-practices.md#pattern-1-calculatordeterministic-agents)

### Natural Language Agents
```
Evaluators: LLMJudgeOutputEvaluator, ContainsEvaluator
Tests: Semantic equivalence, required keywords, various phrasings
Scoring: 0.0-1.0 range based on semantic similarity
```
See [Best Practices](evaluations/best-practices.md#pattern-2-natural-language-agents)

### Multi-Step Orchestration Agents
```
Evaluators: TrajectoryEvaluator, JsonSimilarityEvaluator
Tests: Tool sequences, decision flows, output structure
Scoring: 0.0-1.0 based on execution path and output match
```
See [Best Practices](evaluations/best-practices.md#pattern-3-multi-step-orchestration-agents)

### API Integration Agents
```
Evaluators: JsonSimilarityEvaluator, ExactMatchEvaluator
Tests: Success paths, error responses, mocked API calls
Scoring: 0.0-1.0 based on response structure match
```
See [Best Practices](evaluations/best-practices.md#pattern-4-api-integration-agents)

## Key Concepts

### Evaluation Scoring

All evaluators return numeric scores:
- **1.0** - Perfect pass
- **0.5-0.9** - Partial success (for similarity-based evaluators)
- **0.0** - Complete failure

Results also include justification, execution metrics, and complete traces.

### Test Case Organization

Organize tests by scenario:
- **Happy Path Tests** - Normal operations with typical inputs
- **Edge Case Tests** - Boundary values, empty/null values, large datasets
- **Error Scenario Tests** - Invalid inputs, missing fields, error handling

See [Creating Evaluations](evaluations/creating-evaluations.md#organizing-test-cases)

### Schema Validation

Evaluations are validated against:
- Agent's input schema from `entry-points.json`
- Agent's output schema from `entry-points.json`
- Required field constraints
- Type compatibility

## Mocking External Calls

Sometimes your agent calls external APIs or functions. You can mock these:

### Function Mocking
Mock specific function calls with return values or exceptions.

### LLM Call Mocking
Mock LLM interactions without making real API calls.

See [Evaluation Sets](evaluations/evaluation-sets.md#mocking-strategies) for detailed examples.

## Integration with UiPath Cloud

Results can be:
- Reported to UiPath Cloud for monitoring
- Integrated with CI/CD pipelines
- Compared with previous runs
- Used for performance tracking

## Best Practices

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

## Additional Resources

For detailed information about the evaluation framework, scoring, and advanced features:
https://uipath.github.io/uipath-python/eval/
