# UiPath SDK Assistant

Comprehensive reference guide for creating, running, and evaluating UiPath coded agents with AI-powered assistance in Claude Code.

## Quick Start

### Access the Documentation

```bash
# Open the comprehensive SDK reference
/uipath-coded-agents:uipath
```

This skill provides detailed documentation on:
- **Authentication** - Authenticate with UiPath Cloud or on-premise
- **Building Agents** - Create agents with Pydantic models and add monitoring
- **Running Agents** - Execute agents with interactive input collection
- **Evaluations** - Comprehensive testing framework with multiple evaluator types

## Features

- **📚 Complete Documentation**: Comprehensive guides for all SDK features
- **🚀 Agent Creation**: Templates and patterns for building agents
- **▶️ Agent Execution**: Schema-driven input collection and execution
- **🧪 Testing Framework**: Multiple evaluator types (output-based and trajectory-based)
- **📊 Monitoring**: Automatic tracing with `@traced()` decorator

## Main Skill

| Skill | Description |
|-------|-------------|
| `/uipath-coded-agents:uipath` | Complete SDK reference with all documentation |
## Documentation Structure

The `/uipath-coded-agents:uipath` skill provides organized reference documentation:

### Getting Started
- **[Authentication](references/authentication.md)** - Set up UiPath authentication

### Building Agents
- **[Creating Agents](references/creating-agents.md)** - Build agents with Pydantic models
- **[Tracing](references/tracing.md)** - Add monitoring and debugging with `@traced()`

### Running Agents
- **[Running Agents](references/running-agents.md)** - Execute agents with inputs

### Testing & Evaluation
- **[Evaluations](references/evaluations.md)** - Comprehensive testing overview
- **[Creating Evaluations](references/evaluations/creating-evaluations.md)** - Design test cases
- **[Evaluators Guide](references/evaluations/evaluators/README.md)** - All evaluator types
- **[Evaluation Sets](references/evaluations/evaluation-sets.md)** - Test file structure
- **[Running Evaluations](references/evaluations/running-evaluations.md)** - Execute tests
- **[Best Practices](references/evaluations/best-practices.md)** - Patterns and optimization

## Example Workflow

A typical agent development workflow:

1. **Authenticate** - Set up UiPath authentication via CLI
2. **Build Agent** - Create an agent using the scaffold template
3. **Add Tracing** - Implement monitoring with `@traced()` decorator
4. **Test Locally** - Run your agent with test inputs
5. **Create Evaluations** - Design comprehensive test cases
6. **Validate** - Run evaluations to ensure agent quality

## Project Structure

When you create a UiPath agent project, it generates:

```
my-agent-project/
├── pyproject.toml          # Project dependencies and configuration
├── main.py                 # Agent implementation with Pydantic models
├── uipath.json             # UiPath project metadata
├── entry-points.json       # Agent definitions and JSON schemas
├── README.md               # Generated project documentation
├── .env                    # Environment variables (optional)
└── evaluations/
    ├── eval-sets/          # Test case definitions (JSON files)
    └── evaluators/         # Evaluator configuration files
```

## Requirements

- Python 3.12+
- `uv` (package manager) - https://docs.astral.sh/uv/
- Claude Code CLI
- UiPath SDK (installed automatically via `uv sync`)

## Getting Started

1. **Review the documentation** by running `/uipath-coded-agents:uipath`
2. **Create an agent** using the CLI: `uv run uipath init` and `uv run uipath create-agent`
3. **Implement your business logic** in the generated `main.py`
4. **Test your agent** by running it with `uv run uipath run`
5. **Create evaluations** to validate agent behavior
6. **Deploy** to UiPath Cloud or on-premise

## Common Issues

### "UiPath SDK not found"

Ensure dependencies are installed:

```bash
uv sync
uv run uipath --version
```

### Agent creation or execution fails

Verify your project setup:
- Check that `pyproject.toml` exists and is correctly formatted
- Ensure `entry-points.json` is generated with `uv run uipath init`
- Verify Python 3.12+ is available: `python --version`

### Authentication issues

Review the [Authentication](references/authentication.md) guide for:
- Setting environment variables (UIPATH_URL)
- Using different authentication modes
- Handling proxy configurations

## Learning Resources

- **[UiPath Python SDK Docs](https://uipath.github.io/uipath-python/)** - Official documentation
- **[UiPath Platform](https://www.uipath.com/)** - Main UiPath website
- **[Evaluation Framework](references/evaluations.md)** - Comprehensive testing guide
- **[Best Practices](references/evaluations/best-practices.md)** - Agent patterns and optimization

## Support

- **GitHub Issues**: https://github.com/UiPath/uipath-python/issues
- **Documentation**: https://uipath.github.io/uipath-python/
- **Community**: https://community.uipath.com/

## License

MIT License - See project LICENSE file for details
