---
description: Migrate your agent between frameworks (LangChain, LlamaIndex, OpenAI Agents)
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Migrate Agent Between Frameworks

I'll help you migrate your UiPath agent between different AI frameworks: LangChain, LlamaIndex, and OpenAI Agents SDK.

## What This Skill Does

- 🔄 Convert agents between frameworks
- 📋 Preserve Input/Output schemas
- 🛠️ Translate tools and functions
- 🔍 Maintain business logic
- ✅ Test both versions side-by-side
- 📊 Compare performance

## Supported Migrations

| From | To | Difficulty |
|------|-----|------------|
| **LangChain** → **LlamaIndex** | Medium |
| **LangChain** → **OpenAI Agents** | Easy |
| **LlamaIndex** → **LangChain** | Medium |
| **LlamaIndex** → **OpenAI Agents** | Easy |
| **OpenAI Agents** → **LangChain** | Easy |
| **OpenAI Agents** → **LlamaIndex** | Easy |
| **Plain Python** → **Any Framework** | Medium |

## Why Migrate?

### From LangChain to LlamaIndex
- **Better for RAG** - Superior document indexing and retrieval
- **Workflow-based** - Event-driven architecture
- **Observability** - Built-in tracing and monitoring

### From LangChain to OpenAI Agents
- **Simplicity** - Less boilerplate code
- **Native OpenAI** - Tight integration with OpenAI models
- **Ease of use** - Faster development

### From LlamaIndex to LangChain
- **More tools** - Larger ecosystem
- **Multi-agent** - Better multi-agent orchestration
- **Flexibility** - More customization options

### From OpenAI Agents to LangChain/LlamaIndex
- **Framework independence** - Not tied to OpenAI
- **More LLMs** - Support for multiple LLM providers
- **Advanced patterns** - Complex workflows and state management

## Prerequisites

- Existing UiPath agent
- Understanding of current framework
- Dependencies for target framework

## Workflow

### Step 0: Analyze Current Agent

I'll analyze your agent:
- Detect current framework
- Identify tools and functions
- Map state management
- Extract business logic
- Document Input/Output schemas

### Step 1: Create Backup

I'll create a backup before migration:

```bash
# Backup current agent
cp main.py main.py.backup
cp pyproject.toml pyproject.toml.backup
```

### Step 2: Update Dependencies

I'll update `pyproject.toml` for the target framework:

#### Migrating to LangChain

```toml
[project]
dependencies = [
    "uipath>=2.4.0",
    "uipath-langchain>=0.4.0",
    "langchain>=0.1.0",
    "langchain-openai>=0.0.5",  # or other LLM provider
    "langgraph>=0.0.20",
]
```

#### Migrating to LlamaIndex

```toml
[project]
dependencies = [
    "uipath>=2.4.0",
    "uipath-llamaindex>=0.3.0",
    "llama-index>=0.10.0",
    "llama-index-llms-openai>=0.1.0",  # or other LLM provider
]
```

#### Migrating to OpenAI Agents

```toml
[project]
dependencies = [
    "uipath>=2.4.0",
    "uipath-openai-agents>=0.1.0",
    "openai>=1.0.0",
]
```

### Step 3: Convert Code

I'll convert your agent code to the target framework.

## Migration Examples

### LangChain → LlamaIndex

**Before (LangChain):**
```python
from langchain_core.tools import tool
from langgraph.graph import StateGraph
from typing import TypedDict
from uipath import UiPath

class State(TypedDict):
    messages: list
    result: str

@tool
async def search_documents(query: str) -> str:
    """Search documents for information."""
    # Implementation
    return result

def agent_step(state: State) -> State:
    # Agent logic
    return new_state

graph = StateGraph(State)
graph.add_node("agent", agent_step)
graph.set_entry_point("agent")
app = graph.compile()

async def main(input: Input) -> Output:
    result = await app.ainvoke({"messages": [input.message]})
    return Output(result=result["result"])
```

**After (LlamaIndex):**
```python
from llama_index.core.workflow import (
    Workflow,
    StartEvent,
    StopEvent,
    step,
    Event
)
from llama_index.core.tools import FunctionTool
from uipath import UiPath

class SearchEvent(Event):
    query: str

class ResultEvent(Event):
    result: str

async def search_documents(query: str) -> str:
    """Search documents for information."""
    # Implementation (same)
    return result

class AgentWorkflow(Workflow):

    @step
    async def start(self, ev: StartEvent) -> SearchEvent:
        """Initial step."""
        return SearchEvent(query=ev.input.message)

    @step
    async def search(self, ev: SearchEvent) -> ResultEvent:
        """Search step."""
        result = await search_documents(ev.query)
        return ResultEvent(result=result)

    @step
    async def finalize(self, ev: ResultEvent) -> StopEvent:
        """Final step."""
        return StopEvent(result=Output(result=ev.result))

workflow = AgentWorkflow()

async def main(input: Input) -> Output:
    result = await workflow.run(input=input)
    return result
```

### LangChain → OpenAI Agents

**Before (LangChain):**
```python
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph

@tool
async def calculate(expression: str) -> float:
    """Evaluate a mathematical expression."""
    return eval(expression)

# LangGraph setup...
```

**After (OpenAI Agents):**
```python
from openai import OpenAI
from openai.agents import Agent, function_tool

@function_tool
async def calculate(expression: str) -> float:
    """Evaluate a mathematical expression."""
    return eval(expression)

client = OpenAI()

agent = Agent(
    name="calculator",
    instructions="You are a helpful calculator agent.",
    model="gpt-4",
    tools=[calculate]
)

async def main(input: Input) -> Output:
    response = await agent.run(input.message)
    return Output(result=response.content)
```

### LlamaIndex → LangChain

**Before (LlamaIndex):**
```python
from llama_index.core.workflow import Workflow, step, StartEvent, StopEvent
from llama_index.core.tools import FunctionTool

class DataWorkflow(Workflow):

    @step
    async def process(self, ev: StartEvent) -> StopEvent:
        # Processing logic
        return StopEvent(result=output)

workflow = DataWorkflow()
```

**After (LangChain):**
```python
from langgraph.graph import StateGraph
from langchain_core.tools import tool
from typing import TypedDict

class State(TypedDict):
    input: dict
    output: dict

@tool
async def process_data(data: dict) -> dict:
    """Process data."""
    # Processing logic (same)
    return result

def process_step(state: State) -> State:
    result = process_data(state["input"])
    return {"output": result}

graph = StateGraph(State)
graph.add_node("process", process_step)
graph.set_entry_point("process")
app = graph.compile()
```

### OpenAI Agents → LangChain

**Before (OpenAI Agents):**
```python
from openai import OpenAI
from openai.agents import Agent, function_tool

@function_tool
def get_weather(city: str) -> dict:
    """Get weather for a city."""
    return {"city": city, "temp": 72, "condition": "sunny"}

agent = Agent(
    name="weather",
    model="gpt-4",
    tools=[get_weather]
)
```

**After (LangChain):**
```python
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

@tool
def get_weather(city: str) -> dict:
    """Get weather for a city."""
    return {"city": city, "temp": 72, "condition": "sunny"}

llm = ChatOpenAI(model="gpt-4")
agent = create_react_agent(llm, tools=[get_weather])

async def main(input: Input) -> Output:
    result = await agent.ainvoke({"messages": [("user", input.message)]})
    return Output(result=result["messages"][-1].content)
```

## Tool Translation

### Tool Decorators

| Framework | Tool Decorator | Example |
|-----------|---------------|---------|
| **LangChain** | `@tool` | `from langchain_core.tools import tool` |
| **LlamaIndex** | `FunctionTool.from_defaults()` | `FunctionTool.from_defaults(fn=my_func)` |
| **OpenAI Agents** | `@function_tool` | `from openai.agents import function_tool` |

### Converting Tools

```python
# LangChain tool
@tool
async def search(query: str) -> str:
    """Search for information."""
    return result

# To LlamaIndex
async def search(query: str) -> str:
    """Search for information."""
    return result

search_tool = FunctionTool.from_defaults(
    fn=search,
    name="search",
    description="Search for information"
)

# To OpenAI Agents
@function_tool
async def search(query: str) -> str:
    """Search for information."""
    return result
```

## State Management Translation

### LangChain State → LlamaIndex Events

**LangChain:**
```python
class State(TypedDict):
    messages: list
    context: str
    result: str
```

**LlamaIndex:**
```python
class MessageEvent(Event):
    messages: list

class ContextEvent(Event):
    context: str

class ResultEvent(Event):
    result: str
```

### LlamaIndex Events → OpenAI Agents

LlamaIndex events become function calls in OpenAI Agents.

## Step 4: Preserve Schemas

I'll ensure Input/Output schemas remain identical:

```python
# These stay the same regardless of framework
class Input(BaseModel):
    message: str
    context: str | None = None

class Output(BaseModel):
    result: str
    confidence: float
```

## Step 5: Install Dependencies

```bash
# Remove old dependencies
uv remove uipath-langchain  # or uipath-llamaindex, etc.

# Add new dependencies
uv add uipath-llamaindex  # or target framework

# Sync
uv sync
```

## Step 6: Regenerate Schemas

```bash
# Update entry-points.json
uv run uipath init --no-agents-md-override
```

## Step 7: Test Both Versions

I'll test both old and new versions side-by-side:

```bash
# Test original (from backup)
cp main.py.backup main.py.original
uv run python -c "from main_original import main; ..."

# Test migrated
uv run uipath run main '{"message": "test"}'

# Compare outputs
```

## Step 8: Performance Comparison

I'll compare performance metrics:

```python
import time

async def benchmark(input_data, iterations=10):
    """Benchmark agent performance."""
    start = time.time()

    for _ in range(iterations):
        result = await main(input_data)

    duration = time.time() - start
    avg_time = duration / iterations

    return {
        "total_time": duration,
        "avg_time": avg_time,
        "iterations": iterations
    }

# Run benchmark on both versions
old_metrics = benchmark(test_input)  # Using backed up version
new_metrics = benchmark(test_input)  # Using migrated version

# Compare
print(f"Old: {old_metrics['avg_time']:.3f}s per run")
print(f"New: {new_metrics['avg_time']:.3f}s per run")
print(f"Speedup: {old_metrics['avg_time'] / new_metrics['avg_time']:.2f}x")
```

## Migration Challenges

### Challenge 1: State Management Differences

**LangChain** uses `TypedDict` state shared across nodes.
**LlamaIndex** uses events passed between steps.

**Solution:** Map state fields to events.

### Challenge 2: Tool Format Differences

Different frameworks have different tool signatures.

**Solution:** Keep tool implementation, change decorator.

### Challenge 3: Async Handling

Some frameworks handle async differently.

**Solution:** Ensure all async functions use `await` properly.

### Challenge 4: LLM Configuration

LLM setup differs between frameworks.

**Solution:**
```python
# LangChain
from langchain_openai import ChatOpenAI
llm = ChatOpenAI(model="gpt-4")

# LlamaIndex
from llama_index.llms.openai import OpenAI
llm = OpenAI(model="gpt-4")

# OpenAI Agents
from openai import OpenAI
client = OpenAI()
```

## Migration Checklist

Before migrating:
- [ ] Backup current agent
- [ ] Document current behavior
- [ ] Create test cases
- [ ] Run evaluations on original

During migration:
- [ ] Update dependencies
- [ ] Convert code structure
- [ ] Translate tools
- [ ] Map state/events
- [ ] Update LLM configuration
- [ ] Preserve Input/Output schemas

After migration:
- [ ] Test migrated agent
- [ ] Compare with original
- [ ] Run evaluations
- [ ] Benchmark performance
- [ ] Update documentation

## Rollback Plan

If migration fails:

```bash
# Restore from backup
cp main.py.backup main.py
cp pyproject.toml.backup pyproject.toml

# Restore dependencies
uv sync

# Test original
uv run uipath run main '{"message": "test"}'
```

## Best Practices

✅ **Do:**
- Create comprehensive backups
- Test thoroughly before deploying
- Compare performance metrics
- Keep original for reference
- Document migration decisions
- Run evaluations on both versions

❌ **Don't:**
- Migrate without backup
- Skip testing
- Change business logic during migration
- Forget to update dependencies
- Deploy without validation
- Mix old and new framework code

## When to Migrate

**Good reasons:**
- Framework limitations blocking new features
- Performance improvements needed
- Better ecosystem fit
- Team expertise in target framework
- Better tooling/debugging in target

**Bad reasons:**
- Latest trend/hype
- Minor performance difference
- No clear benefit
- Agent works fine as-is

## Framework Comparison

| Feature | LangChain | LlamaIndex | OpenAI Agents |
|---------|-----------|------------|---------------|
| **RAG** | Good | Excellent | Basic |
| **Multi-Agent** | Excellent | Good | Good |
| **Simplicity** | Medium | Medium | High |
| **Flexibility** | High | High | Medium |
| **LLM Support** | Excellent | Excellent | OpenAI only |
| **Tools Ecosystem** | Excellent | Good | Growing |
| **Learning Curve** | Steep | Medium | Gentle |

## Post-Migration

After successful migration:

1. **Delete backup** (after confirming stability)
2. **Update documentation**
3. **Notify team** of framework change
4. **Monitor performance** in production
5. **Create new evaluations** if needed
6. **Update CI/CD** if framework-specific

## Troubleshooting

### Import Errors

```
Error: No module named 'langchain'
```

**Fix:**
```bash
uv add langchain langchain-openai langgraph
uv sync
```

### Tool Not Working

```
Error: Tool 'search' not found
```

**Fix:** Check tool decorator and registration.

### State Not Passed

```
Error: KeyError: 'messages'
```

**Fix:** Verify state/event mapping is correct.

### Performance Degradation

If migrated agent is slower:
- Check async usage
- Verify LLM configuration
- Profile with tracing
- Compare tool execution

## Next Steps

After migration:
1. **Test thoroughly** with `/uipath-coded-agents:run`
2. **Run evaluations** with `/uipath-coded-agents:eval`
3. **Compare performance**
4. **Deploy** with `/uipath-coded-agents:deploy`

## Let's Migrate Your Agent!

Tell me:
- Current framework?
- Target framework?
- Reason for migration?
- Any specific concerns?

**Example prompts:**
- "Migrate my LangChain agent to LlamaIndex for better RAG"
- "Convert OpenAI Agents to LangChain for flexibility"
- "Move LlamaIndex agent to LangChain for multi-agent"

I'll guide you through the complete migration process!
