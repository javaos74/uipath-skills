---
description: Create a new UiPath coded agent with AI-powered implementation
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion
---

# Create a New UiPath Agent

I'll guide you through creating a new UiPath agent with AI-powered business logic implementation.

## Step 0: Prerequisites Check

Before creating an agent, I need to verify that `.claude/cpr.sh` exists. This resolver script allows the command to access plugin templates.

If `.claude/cpr.sh` doesn't exist, please run the plugin setup skill first:

```
/uipath-coded-agents:setup
```

This will create the necessary resolver script. After that, you can proceed with creating your agent.

Once the resolver is in place, I will:

1. **Setup pyproject.toml**: Check if `pyproject.toml` exists; if not, I'll:
   - Copy the template to current working directory: `cp $(./.claude/cpr.sh uipath-coded-agents)/templates/pyproject.toml ./pyproject.toml`
     - Note that if the resolver fails, setup the plugin and try again.
   - Replace `{AGENT_NAME}` with the actual agent name
   - Replace `{AGENT_DESCRIPTION}` with the agent description you provide

2. **Install dependencies**: Run `uv sync` to install dependencies and create the virtual environment.

3. **Verify SDK**: Verify the UiPath SDK is available using `uv run uipath --version`.

4. **Authentication** (if needed): If any command requires authentication, run:
   ```bash
   uv run uipath auth --alpha
   ```

All subsequent commands will be executed using `uv run` to ensure they run within the project's virtual environment.

## Workflow

### Step 1: Define Agent Schema
I'll ask you to specify:
- **Agent Description**: What does this agent do?
- **Input Fields**: Name, type, description for each input parameter
- **Output Fields**: Name, type, description for each output

The schemas should be written as pydantic types.

### Step 2: Generate Template
I'll create a `main.py` file with:
- Pydantic models for Input and Output based on your schema
- UiPath SDK initialization
- `@traced()` decorator for monitoring
- Function signature with type hints

### Step 3: Implement Business Logic
I'll ask you to describe your agent's functionality, then implement the main function with:
- Proper error handling
- UiPath SDK method calls
- Input validation
- Output formatting

### Step 4: Generate Entry Points
I'll run `uv run uipath init` to generate:
- `entry-points.json` with JSON schemas
- Documentation files (AGENTS.md, etc.)
- Agent structure and metadata

## Generated Template

The created agent will follow this structure:

```python
from pydantic import BaseModel, Field
from uipath.platform import UiPath
from uipath.tracing import traced

class Input(BaseModel):
    # Generated fields based on your inputs
    pass

class Output(BaseModel):
    # Generated fields based on your outputs
    pass

@traced()
async def main(input: Input) -> Output:
    """Your agent's business logic implementation."""
    # AI-implemented logic will go here
    pass
```

## Next Steps

Once your agent is created, you can ask the user to:
- **Run it**: Use `/uipath-coded-agents:run` to execute with interactive inputs
- **Create Evaluations**: Use `/uipath-coded-agents:create-eval` to build evaluation test cases
- **Run Evaluations**: Use `/uipath-coded-agents:eval` to create evaluations or validate your agent

## Important Notes

- All agents are automatically traced for monitoring and debugging
- Input/output fields are strongly typed with Pydantic
- The agent works globally and can call any UiPath SDK services
- Generated `entry-points.json` enables integration with UiPath Cloud
- If you require authentication at any point, use `/uipath-coded-agents:auth` to authenticate with UiPath

Let's create your agent! Provide your agent name and I'll guide you through the setup.
