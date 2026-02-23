---
description: Add Human-in-the-Loop (HITL) capability using UiPath Action Center
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion
---

# Add Human-in-the-Loop Capability

I'll help you add Human-in-the-Loop (HITL) capability to your agent using UiPath Action Center, enabling human approval and intervention in agent workflows.

## What is HITL?

Human-in-the-Loop allows agents to:
- 🛑 Pause execution and request human approval
- 📝 Collect additional information from humans
- ✅ Validate agent decisions before proceeding
- 🔀 Handle exceptions that require human judgment

**Use Cases:**
- Approval workflows (expense approval, order confirmation)
- Exception handling (ambiguous cases, errors)
- Data validation (verify extracted information)
- Compliance requirements (regulatory approvals)

## What This Skill Does

- 🎯 Add Action Center integration to agents
- 🔄 Implement interrupt/resume pattern
- 📋 Create approval and data collection tasks
- ⏸️ Pause agent execution for human input
- ✨ Resume with human-provided data
- 🧪 Test HITL workflows locally

## Prerequisites

- Existing UiPath agent (LangChain, LlamaIndex, or plain Python)
- UiPath Action Center access
- Authentication configured (`/uipath-coded-agents:auth`)
- Understanding of your approval workflow

## HITL Patterns

### Pattern 1: Simple Approval

Agent requests yes/no approval:
```
Agent: "Should I delete these 100 files?"
Human: "Yes" or "No"
Agent: Proceeds or cancels based on response
```

### Pattern 2: Data Collection

Agent requests additional information:
```
Agent: "I need the customer's email address"
Human: Provides "customer@example.com"
Agent: Continues with provided data
```

### Pattern 3: Validation

Agent asks human to validate extracted data:
```
Agent: "I extracted: Name='John', Amount=$500. Is this correct?"
Human: Confirms or corrects
Agent: Proceeds with validated data
```

### Pattern 4: Exception Handling

Agent encounters ambiguity:
```
Agent: "Found 3 matching customers. Which one?"
Human: Selects correct customer
Agent: Continues with selected customer
```

## Workflow

### Step 1: Detect Agent Framework

I'll determine your agent type:
- **LangChain** - Use LangGraph interrupt pattern
- **LlamaIndex** - Use Workflow with human-in-the-loop step
- **Plain Python** - Use direct Action Center SDK calls

### Step 2: Add Action Center Dependency

I'll ensure Action Center SDK is available:

```toml
[project]
dependencies = [
    "uipath>=2.4.0",
    "uipath-langchain>=0.4.0",  # if using LangChain
]
```

### Step 3: Configure Action Center Binding

I'll add Action Center configuration to `bindings.json`:

```json
{
  "action_center": {
    "folderId": "your-folder-id",
    "catalog": "default"
  }
}
```

### Step 4: Implement HITL

I'll add HITL capability based on your framework:

## LangChain Implementation

### Simple Approval Workflow

```python
from langgraph.graph import StateGraph
from langgraph.checkpoint.memory import MemorySaver
from typing import TypedDict, Literal
from uipath import UiPath

class State(TypedDict):
    """Agent state."""
    message: str
    action: str
    approval_required: bool
    approved: bool | None

def agent_step(state: State) -> State:
    """Agent decides if approval is needed."""
    # Example: Deletion requires approval
    if state["action"] == "delete" and len(items) > 10:
        return {
            **state,
            "approval_required": True
        }
    return state

async def request_approval(state: State) -> State:
    """Request human approval via Action Center."""
    uipath = UiPath()

    # Create action in Action Center
    action = await uipath.action_center.create_action(
        title=f"Approval Required: {state['action']}",
        priority="High",
        assigned_to="user@example.com",
        data={
            "action": state["action"],
            "item_count": 100,
            "description": state["message"]
        },
        form_schema={
            "type": "object",
            "properties": {
                "approved": {
                    "type": "boolean",
                    "title": "Approve this action?"
                },
                "comments": {
                    "type": "string",
                    "title": "Comments (optional)"
                }
            }
        }
    )

    # Wait for human response
    result = await uipath.action_center.wait_for_action(
        action_id=action.id,
        timeout_seconds=3600  # 1 hour timeout
    )

    return {
        **state,
        "approved": result.data.get("approved", False),
        "approval_required": False
    }

def should_request_approval(state: State) -> Literal["approve", "execute"]:
    """Route based on approval requirement."""
    if state.get("approval_required"):
        return "approve"
    return "execute"

def should_execute(state: State) -> Literal["execute", "cancel"]:
    """Route based on approval decision."""
    if state.get("approved"):
        return "execute"
    return "cancel"

# Build graph
workflow = StateGraph(State)

workflow.add_node("agent", agent_step)
workflow.add_node("request_approval", request_approval)
workflow.add_node("execute", execute_action)
workflow.add_node("cancel", cancel_action)

workflow.set_entry_point("agent")
workflow.add_conditional_edges(
    "agent",
    should_request_approval,
    {"approve": "request_approval", "execute": "execute"}
)
workflow.add_conditional_edges(
    "request_approval",
    should_execute,
    {"execute": "execute", "cancel": "cancel"}
)

# Use checkpointer for persistence
memory = MemorySaver()
app = workflow.compile(checkpointer=memory)

# Run with interruption support
async def main(input: Input) -> Output:
    """Main entry with HITL support."""
    result = await app.ainvoke(
        {"message": input.message, "action": input.action},
        config={"configurable": {"thread_id": "123"}}
    )
    return Output(status=result["status"])
```

### Data Collection Workflow

```python
async def collect_data(state: State) -> State:
    """Collect additional data from human."""
    uipath = UiPath()

    action = await uipath.action_center.create_action(
        title="Additional Information Required",
        priority="Medium",
        assigned_to="user@example.com",
        data={"context": state["context"]},
        form_schema={
            "type": "object",
            "properties": {
                "customer_email": {
                    "type": "string",
                    "title": "Customer Email",
                    "format": "email"
                },
                "phone_number": {
                    "type": "string",
                    "title": "Phone Number"
                },
                "preferred_contact": {
                    "type": "string",
                    "title": "Preferred Contact Method",
                    "enum": ["email", "phone", "sms"]
                }
            },
            "required": ["customer_email"]
        }
    )

    result = await uipath.action_center.wait_for_action(action.id)

    return {
        **state,
        "customer_email": result.data["customer_email"],
        "phone_number": result.data.get("phone_number"),
        "contact_method": result.data["preferred_contact"]
    }
```

## LlamaIndex Implementation

### Workflow with Human Step

```python
from llama_index.core.workflow import (
    Workflow,
    StartEvent,
    StopEvent,
    step,
    Event
)
from uipath import UiPath
from pydantic import BaseModel

class ApprovalRequestEvent(Event):
    """Event to request approval."""
    action: str
    data: dict

class ApprovalResponseEvent(Event):
    """Event with approval result."""
    approved: bool
    comments: str | None

class HITLWorkflow(Workflow):
    """Workflow with human-in-the-loop."""

    @step
    async def start(self, ev: StartEvent) -> ApprovalRequestEvent:
        """Initial step - determine if approval needed."""
        input_data = ev.input

        # Check if approval is required
        if input_data.action == "delete" and input_data.count > 10:
            return ApprovalRequestEvent(
                action=input_data.action,
                data={"count": input_data.count}
            )

        # No approval needed, skip to execution
        return StopEvent(result={"status": "executed"})

    @step
    async def request_approval(
        self, ev: ApprovalRequestEvent
    ) -> ApprovalResponseEvent:
        """Request approval from human."""
        uipath = UiPath()

        action = await uipath.action_center.create_action(
            title=f"Approval Required: {ev.action}",
            data=ev.data,
            form_schema={
                "type": "object",
                "properties": {
                    "approved": {"type": "boolean"},
                    "comments": {"type": "string"}
                }
            }
        )

        result = await uipath.action_center.wait_for_action(action.id)

        return ApprovalResponseEvent(
            approved=result.data["approved"],
            comments=result.data.get("comments")
        )

    @step
    async def handle_response(
        self, ev: ApprovalResponseEvent
    ) -> StopEvent:
        """Handle approval response."""
        if ev.approved:
            # Execute action
            result = await execute_action()
            return StopEvent(result={"status": "executed", "result": result})
        else:
            # Cancel
            return StopEvent(result={
                "status": "cancelled",
                "reason": ev.comments
            })

# Create workflow
workflow = HITLWorkflow()

async def main(input: Input) -> Output:
    """Main entry point."""
    result = await workflow.run(input=input)
    return Output(**result)
```

## Plain Python Implementation

### Direct Action Center Usage

```python
from pydantic import BaseModel, Field
from uipath import UiPath
from uipath.tracing import traced

class Input(BaseModel):
    """Agent input."""
    action: str
    items: list[str]
    auto_approve: bool = False

class Output(BaseModel):
    """Agent output."""
    status: str
    approved: bool
    items_processed: int

@traced(span_name="request_approval")
async def request_approval(action: str, items: list[str]) -> dict:
    """Request approval for action."""
    uipath = UiPath()

    # Create approval task
    task = await uipath.action_center.create_action(
        title=f"Approve: {action}",
        priority="High",
        assigned_to="manager@example.com",
        data={
            "action": action,
            "item_count": len(items),
            "items_preview": items[:5]  # Show first 5 items
        },
        form_schema={
            "type": "object",
            "properties": {
                "approved": {
                    "type": "boolean",
                    "title": "Approve this action?",
                    "description": f"Approve {action} on {len(items)} items"
                },
                "comments": {
                    "type": "string",
                    "title": "Comments"
                }
            },
            "required": ["approved"]
        }
    )

    # Wait for response (with timeout)
    try:
        result = await uipath.action_center.wait_for_action(
            action_id=task.id,
            timeout_seconds=3600  # 1 hour
        )
        return {
            "approved": result.data["approved"],
            "comments": result.data.get("comments"),
            "status": "completed"
        }
    except TimeoutError:
        return {
            "approved": False,
            "comments": "Approval timed out",
            "status": "timeout"
        }

async def main(input: Input) -> Output:
    """Main agent with HITL."""

    # Check if approval is needed
    if not input.auto_approve and len(input.items) > 10:
        approval = await request_approval(input.action, input.items)

        if not approval["approved"]:
            return Output(
                status="cancelled",
                approved=False,
                items_processed=0
            )

    # Execute action
    processed = await execute_action(input.action, input.items)

    return Output(
        status="completed",
        approved=True,
        items_processed=processed
    )
```

## Form Schema Examples

### Simple Yes/No Approval

```python
form_schema = {
    "type": "object",
    "properties": {
        "approved": {
            "type": "boolean",
            "title": "Approve this action?"
        }
    },
    "required": ["approved"]
}
```

### Data Collection Form

```python
form_schema = {
    "type": "object",
    "properties": {
        "customer_name": {
            "type": "string",
            "title": "Customer Name"
        },
        "email": {
            "type": "string",
            "title": "Email Address",
            "format": "email"
        },
        "amount": {
            "type": "number",
            "title": "Amount",
            "minimum": 0
        },
        "priority": {
            "type": "string",
            "title": "Priority",
            "enum": ["Low", "Medium", "High"]
        },
        "comments": {
            "type": "string",
            "title": "Additional Comments",
            "multiline": true
        }
    },
    "required": ["customer_name", "email", "amount"]
}
```

### Validation Form

```python
form_schema = {
    "type": "object",
    "properties": {
        "extracted_data_correct": {
            "type": "boolean",
            "title": "Is the extracted data correct?"
        },
        "corrections": {
            "type": "object",
            "title": "Corrections (if any)",
            "properties": {
                "invoice_number": {"type": "string"},
                "total_amount": {"type": "number"},
                "vendor_name": {"type": "string"}
            }
        }
    }
}
```

## Advanced HITL Patterns

### Timeout Handling

```python
try:
    result = await uipath.action_center.wait_for_action(
        action_id=action.id,
        timeout_seconds=1800  # 30 minutes
    )
except TimeoutError:
    # Handle timeout - use default, escalate, or cancel
    return handle_timeout()
```

### Escalation

```python
# First try with primary approver
action1 = await uipath.action_center.create_action(
    assigned_to="manager@example.com",
    timeout_seconds=1800
)

try:
    result = await uipath.action_center.wait_for_action(action1.id)
except TimeoutError:
    # Escalate to senior manager
    action2 = await uipath.action_center.create_action(
        title=f"ESCALATED: {original_title}",
        assigned_to="senior_manager@example.com",
        priority="Critical"
    )
    result = await uipath.action_center.wait_for_action(action2.id)
```

### Multi-Stage Approval

```python
# Stage 1: Manager approval
manager_approval = await request_approval("manager@example.com")

if manager_approval["approved"] and amount > 10000:
    # Stage 2: Director approval for large amounts
    director_approval = await request_approval("director@example.com")
    final_approved = director_approval["approved"]
else:
    final_approved = manager_approval["approved"]
```

### Parallel Approvals

```python
import asyncio

# Request approval from multiple people simultaneously
tasks = [
    uipath.action_center.create_action(assigned_to="approver1@example.com"),
    uipath.action_center.create_action(assigned_to="approver2@example.com"),
    uipath.action_center.create_action(assigned_to="approver3@example.com")
]

actions = await asyncio.gather(*tasks)

# Wait for all approvals
results = await asyncio.gather(*[
    uipath.action_center.wait_for_action(a.id) for a in actions
])

# Require all approvals
all_approved = all(r.data["approved"] for r in results)
```

## Testing HITL Locally

### Mock Action Center for Testing

```python
class MockActionCenter:
    """Mock Action Center for local testing."""

    async def create_action(self, **kwargs):
        """Simulate action creation."""
        print(f"\n{'='*50}")
        print(f"ACTION REQUIRED: {kwargs['title']}")
        print(f"{'='*50}")
        print(f"Data: {kwargs.get('data')}")
        print(f"Assigned to: {kwargs.get('assigned_to')}")

        return type('Action', (), {'id': 'mock-123'})()

    async def wait_for_action(self, action_id, timeout_seconds=None):
        """Simulate waiting for human response."""
        print(f"\nWaiting for human response...")
        print(f"(In production, human would respond via Action Center UI)")

        # Simulate approval
        response = input("Approve? (y/n): ")
        comments = input("Comments (optional): ")

        return type('Result', (), {
            'data': {
                'approved': response.lower() == 'y',
                'comments': comments if comments else None
            },
            'status': 'Completed'
        })()

# Use in testing
if os.getenv("TESTING"):
    uipath.action_center = MockActionCenter()
```

## Bindings Configuration

Add Action Center configuration:

```json
{
  "action_center": {
    "folderId": "your-folder-id",
    "catalog": "default",
    "default_assignee": "user@example.com"
  }
}
```

## Update Input/Output Models

```python
class Input(BaseModel):
    """Agent input with approval options."""
    action: str
    items: list[str]
    auto_approve: bool = Field(
        default=False,
        description="Skip approval for automated runs"
    )
    approval_timeout: int = Field(
        default=3600,
        description="Approval timeout in seconds"
    )

class Output(BaseModel):
    """Agent output with approval details."""
    status: str
    approved: bool
    approver: str | None = None
    approval_time: str | None = None
    items_processed: int
```

## Best Practices

✅ **Do:**
- Set reasonable timeouts (30 mins - 1 hour)
- Provide clear context in approval forms
- Show relevant data for decision making
- Handle timeouts gracefully
- Log all approval decisions
- Test HITL flows thoroughly
- Use appropriate priority levels

❌ **Don't:**
- Request approval for trivial operations
- Use very short timeouts (<5 minutes)
- Forget to handle timeout errors
- Assign to invalid users
- Block on approvals without timeout
- Skip testing HITL workflows

## Monitoring HITL

Track HITL metrics:

```python
@traced(span_name="hitl_approval")
async def request_approval_with_metrics(action: str) -> dict:
    """Request approval with metrics."""
    start_time = time.time()

    result = await request_approval(action)

    metrics = {
        "approval_time_seconds": time.time() - start_time,
        "approved": result["approved"],
        "action_type": action
    }

    # Log metrics to monitoring system
    logger.info("HITL metrics", extra=metrics)

    return result
```

## Next Steps

After adding HITL:
1. **Test locally** with mock Action Center
2. **Test in alpha** with real Action Center
3. **Create evaluations** that test approval flows
4. **Monitor approval metrics**
5. **Deploy** with `/uipath-coded-agents:deploy`

## Let's Add HITL to Your Agent!

Tell me:
- What requires approval in your agent?
- Who should approve? (user emails or roles)
- What data should be shown in approval form?
- What's the timeout for approvals?

**Example prompts:**
- "Add approval for delete operations over 10 items"
- "Add data collection for missing customer email"
- "Add validation step for extracted invoice data"
- "Add escalation workflow for high-value transactions"
