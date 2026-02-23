---
description: Add a new tool or capability to an existing UiPath agent
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Add Tool to Existing Agent

I'll help you extend your existing UiPath agent with new tools and capabilities. This works with all agent frameworks: LangChain, LlamaIndex, OpenAI Agents, and plain Python agents.

## What This Skill Does

- ✨ Add new tools/functions to existing agents
- 🔍 Auto-detect agent framework (LangChain/LlamaIndex/OpenAI/Python)
- 🛠️ Generate tool code with proper decorators and signatures
- 📦 Integrate UiPath SDK methods
- 🔄 Update Input models if needed
- ✅ Regenerate schemas and test agent

## Prerequisites

- Existing UiPath agent with `main.py`
- `entry-points.json` file (created by `uipath init`)
- `pyproject.toml` with dependencies

If you don't have an agent yet, use `/uipath-coded-agents:create-agent` first!

## Workflow

### Step 0: Agent Detection

I'll automatically detect your agent type:

**LangChain/LangGraph Agent:**
```python
# Detected by imports:
from langgraph.graph import StateGraph
from langchain_core.tools import tool
```

**LlamaIndex Agent:**
```python
# Detected by imports:
from llama_index.core.workflow import Workflow, step
from llama_index.core.tools import FunctionTool
```

**OpenAI Agents:**
```python
# Detected by imports:
from openai import OpenAI
from openai.agents import Agent
```

**Plain Python Agent:**
```python
# Simple async function without framework
async def main(input: Input) -> Output:
    pass
```

### Step 1: Describe Your Tool

I'll ask you to describe what capability you want to add:

**Examples:**
- "Add ability to upload files to storage bucket"
- "Add queue item retrieval"
- "Add email sending capability"
- "Add document classification"
- "Add approval workflow via Action Center"

### Step 2: Generate Tool Code

Based on your agent framework, I'll generate the appropriate tool:

#### For LangChain Agents

```python
from langchain_core.tools import tool
from uipath import UiPath

@tool
async def upload_to_bucket(
    bucket_name: str,
    file_path: str,
    remote_path: str = None
) -> dict:
    """Upload a file to UiPath storage bucket.

    Args:
        bucket_name: Name of the bucket
        file_path: Local file path to upload
        remote_path: Optional remote path in bucket

    Returns:
        dict with file_name, file_size, upload_time
    """
    uipath = UiPath()
    result = await uipath.buckets.upload(
        bucket_name=bucket_name,
        file_path=file_path,
        remote_path=remote_path
    )

    return {
        "file_name": result.name,
        "file_size": result.size,
        "upload_time": result.created_at
    }

# Add to agent's tools list
tools = [upload_to_bucket, existing_tool1, existing_tool2]
```

#### For LlamaIndex Agents

```python
from llama_index.core.tools import FunctionTool
from uipath import UiPath

async def upload_to_bucket(
    bucket_name: str,
    file_path: str,
    remote_path: str = None
) -> dict:
    """Upload a file to UiPath storage bucket."""
    uipath = UiPath()
    result = await uipath.buckets.upload(
        bucket_name=bucket_name,
        file_path=file_path,
        remote_path=remote_path
    )

    return {
        "file_name": result.name,
        "file_size": result.size
    }

# Create tool
upload_tool = FunctionTool.from_defaults(
    fn=upload_to_bucket,
    name="upload_to_bucket",
    description="Upload a file to UiPath storage bucket"
)

# Add to agent's tools
tools = [upload_tool, existing_tool1, existing_tool2]
```

#### For OpenAI Agents

```python
from openai.agents import function_tool
from uipath import UiPath

@function_tool
async def upload_to_bucket(
    bucket_name: str,
    file_path: str,
    remote_path: str = None
) -> dict:
    """Upload a file to UiPath storage bucket.

    Args:
        bucket_name: Name of the bucket
        file_path: Local file path to upload
        remote_path: Optional remote path in bucket
    """
    uipath = UiPath()
    result = await uipath.buckets.upload(
        bucket_name=bucket_name,
        file_path=file_path,
        remote_path=remote_path
    )

    return {
        "file_name": result.name,
        "file_size": result.size
    }
```

#### For Plain Python Agents

```python
from uipath import UiPath
from uipath.tracing import traced

@traced(span_name="upload_to_bucket")
async def upload_to_bucket(
    bucket_name: str,
    file_path: str,
    remote_path: str = None
) -> dict:
    """Upload a file to UiPath storage bucket."""
    uipath = UiPath()
    result = await uipath.buckets.upload(
        bucket_name=bucket_name,
        file_path=file_path,
        remote_path=remote_path
    )

    return {
        "file_name": result.name,
        "file_size": result.size
    }

# Call from main
async def main(input: Input) -> Output:
    result = await upload_to_bucket(
        bucket_name=input.bucket_name,
        file_path=input.file_path
    )
    return Output(status="uploaded", file=result["file_name"])
```

### Step 3: Update Input Model (If Needed)

If your tool requires new input parameters, I'll update the Input model:

```python
class Input(BaseModel):
    """Agent input with new fields for the tool."""
    # Existing fields
    message: str

    # New fields for upload tool
    bucket_name: str = Field(description="Storage bucket name")
    file_path: str = Field(description="Path to file to upload")
    remote_path: str | None = Field(default=None, description="Remote path in bucket")
```

### Step 4: Add Bindings (If Needed)

If the tool uses UiPath resources, I'll update `bindings.json`:

```json
{
  "buckets": {
    "my-data-bucket": {
      "folderId": "your-folder-id"
    }
  },
  "queues": {
    "ProcessingQueue": {
      "folderId": "your-folder-id"
    }
  }
}
```

### Step 5: Regenerate Schemas

I'll run `uipath init` to update entry-points.json:

```bash
uv run uipath init --no-agents-md-override
```

This ensures your agent schemas reflect the new capabilities.

### Step 6: Test the Agent

I'll test the agent with the new tool:

```bash
uv run uipath run main '{
  "message": "test",
  "bucket_name": "my-data-bucket",
  "file_path": "./test.csv"
}'
```

## Common Tool Patterns

### Storage Tools (Buckets)

**Upload Tool:**
```python
@tool
async def upload_file(bucket: str, file: str) -> dict:
    """Upload file to bucket."""
    uipath = UiPath()
    return await uipath.buckets.upload(bucket, file)
```

**Download Tool:**
```python
@tool
async def download_file(bucket: str, remote: str, local: str) -> dict:
    """Download file from bucket."""
    uipath = UiPath()
    return await uipath.buckets.download(bucket, remote, local)
```

### Queue Tools

**Add Queue Item:**
```python
@tool
async def add_queue_item(queue: str, data: dict) -> dict:
    """Add item to Orchestrator queue."""
    uipath = UiPath()
    return await uipath.queues.add_item(queue, data)
```

**Get Queue Item:**
```python
@tool
async def get_queue_item(queue: str) -> dict:
    """Get next item from queue."""
    uipath = UiPath()
    item = await uipath.queues.get_item(queue)
    return {"id": item.id, "data": item.data}
```

### Asset Tools

**Get Configuration:**
```python
@tool
async def get_config(asset_name: str) -> str:
    """Get configuration from UiPath asset."""
    uipath = UiPath()
    return await uipath.assets.get_value(asset_name)
```

### Job Tools

**Trigger Job:**
```python
@tool
async def trigger_job(process: str, args: dict) -> dict:
    """Start a UiPath job."""
    uipath = UiPath()
    job = await uipath.jobs.start(process, args)
    return {"job_id": job.id, "status": job.status}
```

### Document Processing Tools

**Classify Document:**
```python
@tool
async def classify_document(file_path: str) -> dict:
    """Classify document using Document Understanding."""
    uipath = UiPath()
    result = await uipath.du.classify(file_path)
    return {"type": result.document_type, "confidence": result.confidence}
```

### Action Center Tools (HITL)

**Request Approval:**
```python
@tool
async def request_approval(title: str, data: dict, assigned_to: str) -> dict:
    """Request human approval via Action Center."""
    uipath = UiPath()
    action = await uipath.action_center.create_action(
        title=title,
        data=data,
        assigned_to=assigned_to
    )
    result = await uipath.action_center.wait_for_action(action.id)
    return {"approved": result.status == "Completed", "data": result.data}
```

## Tool Categories

### Data Operations
- File upload/download
- CSV/Excel processing
- Data transformation
- Database operations

### Orchestrator Integration
- Queue management
- Asset access
- Job triggering
- Robot management

### AI & Document Processing
- Document classification
- Text extraction
- ML model inference
- OCR operations

### Human Interaction
- Approval workflows
- Form collection
- Task assignment
- Notification sending

### External Integration
- API calls
- Email sending
- Webhook handling
- Third-party services

## Integration with SDK Discovery

Use `/uipath-coded-agents:find-sdk` first to discover the right SDK methods, then use this skill to add them as tools!

**Example workflow:**
1. `/uipath-coded-agents:find-sdk "how to upload files"`
2. Find `buckets.upload()` method
3. `/uipath-coded-agents:add-tool "add bucket upload capability"`
4. Tool is generated and integrated

## Modified Files

After running this skill, these files will be updated:

```
main.py              ✏️  Updated with new tool function
entry-points.json    🔄  Regenerated with updated schemas
bindings.json        ➕  Added resource bindings (if needed)
Input model          ➕  New fields added (if needed)
```

## Best Practices

✅ **Do:**
- Use descriptive tool names (e.g., `upload_to_bucket` not `tool1`)
- Add comprehensive docstrings
- Include parameter types and descriptions
- Add error handling in tools
- Use `@traced()` for monitoring (plain Python)
- Test tools after adding

❌ **Don't:**
- Add too many tools at once (add incrementally)
- Forget to update Input model for required parameters
- Skip bindings configuration
- Ignore async/await requirements
- Hardcode credentials or secrets

## Error Handling in Tools

Always add proper error handling:

```python
@tool
async def upload_file_safe(bucket: str, file: str) -> dict:
    """Upload file with error handling."""
    try:
        uipath = UiPath()
        result = await uipath.buckets.upload(bucket, file)
        return {"success": True, "file": result.name}
    except FileNotFoundError:
        return {"success": False, "error": "File not found"}
    except Exception as e:
        return {"success": False, "error": str(e)}
```

## Testing Tools

After adding a tool, test it:

```bash
# Test with minimal input
uv run uipath run main '{"message": "test", "bucket_name": "my-bucket", "file_path": "./test.csv"}'

# Test with full parameters
uv run uipath run main '{
  "message": "upload",
  "bucket_name": "my-bucket",
  "file_path": "./data.csv",
  "remote_path": "uploads/data.csv"
}'
```

## Next Steps

After adding tools:
1. **Test thoroughly** with `/uipath-coded-agents:run`
2. **Create evaluations** with `/uipath-coded-agents:eval`
3. **Add more tools** as needed
4. **Deploy** with `/uipath-coded-agents:deploy`

## Let's Add Your Tool!

Tell me what capability you want to add to your agent, and I'll:
1. Detect your agent framework
2. Generate the tool code
3. Update schemas and bindings
4. Test the agent

**Example prompts:**
- "Add file upload to storage bucket"
- "Add queue item processing"
- "Add document classification tool"
- "Add approval workflow capability"
