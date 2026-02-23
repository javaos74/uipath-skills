---
description: Find and discover UiPath SDK methods for your needs
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
---

# Find UiPath SDK Methods

I'll help you discover the right UiPath SDK methods for your task. The UiPath SDK is extensive with services for queues, buckets, assets, jobs, processes, and more.

## What This Skill Does

This skill helps you:
- 🔍 Search SDK documentation for methods
- 📚 Find relevant services and operations
- 💡 See code examples and parameters
- 🔗 Get links to detailed documentation
- ✨ Generate integration code for your agent

## Prerequisites

- UiPath SDK installed (`uipath` package via `uv sync`)
- Basic understanding of what you want to accomplish

## Workflow

### Step 1: Understand Your Requirement

I'll ask you to describe what you're trying to accomplish in natural language. For example:
- "How do I upload a file to a storage bucket?"
- "I need to get items from an Orchestrator queue"
- "How can I read configuration from assets?"
- "I want to trigger a job in Orchestrator"

### Step 2: Search SDK Documentation

I'll search through:
- `.agent/SDK_REFERENCE.md` files in your project
- UiPath Python SDK documentation
- Common patterns and examples

The SDK is organized into services:
- **Buckets** (`uipath.buckets`) - Storage operations
- **Queues** (`uipath.queues`) - Queue management
- **Assets** (`uipath.assets`) - Configuration storage
- **Jobs** (`uipath.jobs`) - Job execution and monitoring
- **Processes** (`uipath.processes`) - Process management
- **Activities** (`uipath.activities`) - Activity execution
- **Document Understanding** (`uipath.du`) - Document processing
- **Action Center** (`uipath.action_center`) - Human-in-the-loop

### Step 3: Present Matching Methods

I'll show you relevant methods with:

```
📦 Service: uipath.buckets
🔧 Method: upload()

Description:
Upload a file to a UiPath storage bucket

Parameters:
- bucket_name (str): Name of the bucket
- file_path (str): Local file path to upload
- remote_path (str, optional): Remote path in bucket

Returns:
- BucketFile: Uploaded file metadata

Example:
from uipath import UiPath

uipath = UiPath()
result = await uipath.buckets.upload(
    bucket_name="my-bucket",
    file_path="./data.csv",
    remote_path="uploads/data.csv"
)
print(f"Uploaded: {result.name}")
```

### Step 4: Generate Integration Code

Based on the method you select, I'll generate ready-to-use code for your agent:

**For async agents:**
```python
from uipath import UiPath

async def main(input: Input) -> Output:
    uipath = UiPath()

    # Upload file to bucket
    file = await uipath.buckets.upload(
        bucket_name=input.bucket_name,
        file_path=input.file_path
    )

    return Output(
        file_name=file.name,
        file_size=file.size
    )
```

**For sync agents:**
```python
from uipath import UiPath

def process_data(input: Input) -> Output:
    uipath = UiPath()

    # Upload file to bucket (sync version)
    file = uipath.buckets.upload(
        bucket_name=input.bucket_name,
        file_path=input.file_path
    )

    return Output(file_name=file.name)
```

### Step 5: Show Related Methods

I'll also show related methods you might need:

```
Related Methods:
- buckets.download() - Download file from bucket
- buckets.list() - List files in bucket
- buckets.delete() - Delete file from bucket
- buckets.get_metadata() - Get file information
```

## Common SDK Services

### Storage Operations (Buckets)

```python
# Upload
await uipath.buckets.upload(bucket_name, file_path, remote_path)

# Download
await uipath.buckets.download(bucket_name, remote_path, local_path)

# List files
files = await uipath.buckets.list(bucket_name, prefix="/uploads/")

# Delete
await uipath.buckets.delete(bucket_name, remote_path)
```

### Queue Operations

```python
# Add item to queue
await uipath.queues.add_item(
    queue_name="ProcessingQueue",
    data={"customer_id": 123, "action": "process"}
)

# Get item from queue
item = await uipath.queues.get_item(queue_name="ProcessingQueue")

# Update item status
await uipath.queues.set_transaction_status(
    item_id=item.id,
    status="Successful"
)

# Bulk add items
await uipath.queues.bulk_add_items(queue_name, items_list)
```

### Asset Management

```python
# Get asset value
value = await uipath.assets.get_value(asset_name="ApiKey")

# Get asset by name
asset = await uipath.assets.get(asset_name="DatabaseConfig")

# List all assets
assets = await uipath.assets.list()
```

### Job Management

```python
# Start a job
job = await uipath.jobs.start(
    process_name="MyProcess",
    input_arguments={"param1": "value1"}
)

# Get job status
job_info = await uipath.jobs.get(job_id=job.id)

# Wait for job completion
result = await uipath.jobs.wait_for_completion(job_id=job.id)

# Get job logs
logs = await uipath.jobs.get_logs(job_id=job.id)
```

### Document Understanding

```python
# Process document
result = await uipath.du.classify_and_extract(
    file_path="invoice.pdf",
    document_type="Invoice"
)

# Validate extraction
validation = await uipath.du.validate(
    document_id=result.id,
    validation_rules=rules
)
```

### Action Center (HITL)

```python
# Create action
action = await uipath.action_center.create_action(
    title="Approval Required",
    assigned_to="user@example.com",
    data={"amount": 5000, "vendor": "Acme Corp"}
)

# Wait for action completion
result = await uipath.action_center.wait_for_action(action_id=action.id)
```

## Bindings Configuration

Many SDK methods require bindings in `bindings.json`:

```json
{
  "buckets": {
    "my-bucket": {
      "folderId": "folder-id-here"
    }
  },
  "queues": {
    "ProcessingQueue": {
      "folderId": "folder-id-here"
    }
  },
  "assets": {
    "ApiKey": {
      "folderId": "folder-id-here"
    }
  }
}
```

I'll remind you if bindings are needed for the method you choose.

## Search Categories

Tell me what you need, and I'll find the right methods:

**File Operations:**
- Upload/download files
- File processing
- CSV/Excel handling

**Queue Management:**
- Queue operations
- Transaction processing
- Bulk operations

**Configuration:**
- Asset management
- Environment variables
- Settings storage

**Automation:**
- Job triggering
- Process execution
- Robot management

**AI/ML:**
- Document processing
- Text extraction
- ML model integration

**Human Interaction:**
- Approval workflows
- Task assignment
- Form collection

## Example Searches

### Example 1: "How do I upload a CSV file?"

I would find:
- `buckets.upload()` - Primary method
- Show parameters and example
- Suggest `buckets.list()` for verification
- Provide complete integration code

### Example 2: "I need to process queue items"

I would find:
- `queues.get_item()` - Get next item
- `queues.set_transaction_status()` - Update status
- Show transaction pattern
- Explain error handling

### Example 3: "How to get configuration values?"

I would find:
- `assets.get_value()` - Get asset value
- `assets.get()` - Get full asset
- Show credential vs text assets
- Explain bindings setup

## Documentation Links

For detailed SDK documentation:
- **Python SDK Docs**: https://uipath.github.io/uipath-python/
- **SDK Reference**: Check `.agent/SDK_REFERENCE.md` in your project
- **API Reference**: https://docs.uipath.com/

## Best Practices

✅ **Do:**
- Use async methods when possible (better performance)
- Configure bindings in `bindings.json` for resources
- Add proper error handling
- Use type hints for better IDE support

❌ **Don't:**
- Hardcode folder IDs (use bindings)
- Forget to await async methods
- Skip authentication setup
- Ignore SDK exceptions

## Integration with Other Skills

This skill works well with:
- `/uipath-coded-agents:add-tool` - Add discovered method as agent tool
- `/uipath-coded-agents:create-agent` - Use methods in new agents
- `/uipath-coded-agents:run` - Test the methods immediately

## Let's Find Your Method!

Tell me what you're trying to accomplish, and I'll find the right SDK methods for you!

**Example prompts:**
- "Find methods to upload files to UiPath"
- "How do I work with Orchestrator queues?"
- "Show me document processing capabilities"
- "I need to trigger jobs from my agent"
