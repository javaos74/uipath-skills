# OAuth Scopes Reference for UiPath TypeScript SDK

This document provides the complete mapping between SDK services/methods and their required OAuth scopes. Use this to determine which scopes an application needs based on the SDK services it uses.

## Scope Format

Scopes follow a hierarchy:
- **Broad scope** (e.g., `OR.Assets`) grants full access (read + write)
- **Granular scope** (e.g., `OR.Assets.Read`) grants restricted access

When in doubt, use the broad scope. Use granular scopes for least-privilege access.

## Complete Service-to-Scope Mapping

### Assets Service

```typescript
import { Assets } from '@uipath/uipath-typescript/assets';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `OR.Assets` or `OR.Assets.Read` |
| `getById()` | `OR.Assets` or `OR.Assets.Read` |

### Buckets Service

```typescript
import { Buckets } from '@uipath/uipath-typescript/buckets';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `OR.Administration` or `OR.Administration.Read` |
| `getById()` | `OR.Administration` or `OR.Administration.Read` |
| `getFileMetaData()` | `OR.Administration` or `OR.Administration.Read` |
| `getReadUri()` | `OR.Administration` or `OR.Administration.Read` |
| `uploadFile()` | `OR.Administration` |

### Entities Service (Data Fabric)

```typescript
import { Entities } from '@uipath/uipath-typescript/entities';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `DataFabric.Schema.Read` |
| `getById()` | `DataFabric.Schema.Read` |
| `getAllRecords()` | `DataFabric.Data.Read` |
| `getRecordById()` | `DataFabric.Data.Read` |
| `insertRecordById()` | `DataFabric.Data.Write` |
| `insertRecordsById()` | `DataFabric.Data.Write` |
| `updateRecordsById()` | `DataFabric.Data.Write` |
| `deleteRecordsById()` | `DataFabric.Data.Write` |
| `downloadAttachment()` | `DataFabric.Data.Read` |

**Note:** Data Fabric operations typically need both `DataFabric.Schema.Read` (to discover entities) AND `DataFabric.Data.Read`/`DataFabric.Data.Write` (to access data).

### ChoiceSets Service (Data Fabric)

```typescript
import { ChoiceSets } from '@uipath/uipath-typescript/entities';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `DataFabric.Schema.Read` |
| `getById()` | `DataFabric.Schema.Read` |

### Processes Service

```typescript
import { Processes } from '@uipath/uipath-typescript/processes';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `OR.Execution` or `OR.Execution.Read` |
| `getById()` | `OR.Execution` or `OR.Execution.Read` |
| `start()` | `OR.Jobs` or `OR.Jobs.Write` |

**Note:** Starting processes requires a different scope than listing them.

### ProcessInstances Service (Maestro)

```typescript
import { ProcessInstances } from '@uipath/uipath-typescript/maestro';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `PIMS` |
| `getById()` | `PIMS` |
| `getExecutionHistory()` | `PIMS` |
| `getBpmn()` | `PIMS` |
| `cancel()` | `PIMS` |
| `pause()` | `PIMS` |
| `resume()` | `PIMS` |
| `getVariables()` | `PIMS` |
| `getIncidents()` | `PIMS` |

### MaestroProcesses Service

```typescript
import { MaestroProcesses } from '@uipath/uipath-typescript/maestro';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `PIMS` |
| `getIncidents()` | `PIMS` |

### Cases Service

```typescript
import { Cases } from '@uipath/uipath-typescript/cases';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `PIMS` |

### CaseInstances Service

```typescript
import { CaseInstances } from '@uipath/uipath-typescript/cases';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `PIMS OR.Execution.Read` |
| `getById()` | `PIMS OR.Execution.Read` |
| `close()` | `PIMS` |
| `pause()` | `PIMS` |
| `resume()` | `PIMS` |
| `reopen()` | `PIMS` |
| `getExecutionHistory()` | `PIMS` |
| `getStages()` | `PIMS OR.Execution.Read` |
| `getActionTasks()` | `PIMS` |

### Queues Service

```typescript
import { Queues } from '@uipath/uipath-typescript/queues';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `OR.Queues` or `OR.Queues.Read` |
| `getById()` | `OR.Queues` or `OR.Queues.Read` |

### Tasks Service (Action Center)

```typescript
import { Tasks } from '@uipath/uipath-typescript/tasks';
```

| Method | Required Scope |
|--------|---------------|
| `getAll()` | `OR.Tasks` or `OR.Tasks.Read` |
| `getById()` | `OR.Tasks` or `OR.Tasks.Read` |
| `getUsers()` | `OR.Tasks` or `OR.Tasks.Read` |
| `create()` | `OR.Tasks` or `OR.Tasks.Write` |
| `assign()` | `OR.Tasks` or `OR.Tasks.Write` |
| `reassign()` | `OR.Tasks` or `OR.Tasks.Write` |
| `unassign()` | `OR.Tasks` or `OR.Tasks.Write` |
| `complete()` | `OR.Tasks` or `OR.Tasks.Write` |

## Quick Scope Builder

To determine the minimum scopes for an app, find all SDK service imports and combine the required scopes:

**Example 1:** App uses Processes (list + start) and Tasks (read + complete)
```
OR.Execution.Read OR.Jobs.Write OR.Tasks
```

**Example 2:** App uses Entities (CRUD) and ChoiceSets (read)
```
DataFabric.Schema.Read DataFabric.Data.Read DataFabric.Data.Write
```

**Example 3:** App uses Maestro Processes and Case management
```
PIMS
```

**Example 4:** Full-featured app with everything
```
OR.Assets OR.Administration DataFabric.Schema.Read DataFabric.Data.Read DataFabric.Data.Write PIMS OR.Execution OR.Jobs.Write OR.Queues OR.Tasks
```

## UiPath External Application Resource Mapping

When adding scopes in the UiPath Admin UI (External Applications → Edit → "Add scopes"), scopes are grouped into **resource categories** selected from a dropdown. Here's how SDK scopes map to UI resources:

| Resource in UI Dropdown | SDK Scopes Under This Resource |
|---|---|
| **UiPath.Orchestrator** | `OR.Assets`, `OR.Assets.Read`, `OR.Administration`, `OR.Administration.Read`, `OR.Execution`, `OR.Execution.Read`, `OR.Jobs`, `OR.Jobs.Write`, `OR.Queues`, `OR.Queues.Read`, `OR.Tasks`, `OR.Tasks.Read`, `OR.Tasks.Write` |
| **Data Fabric API** | `DataFabric.Schema.Read`, `DataFabric.Data.Read`, `DataFabric.Data.Write` |
| **PIMS** | `PIMS` |

**Direct edit URL pattern:** `{baseUrl}/{orgName}/portal_/admin/external-apps/oauth/edit/{clientId}`

## All Available Scopes (Alphabetical)

| Scope | Services |
|-------|----------|
| `DataFabric.Data.Read` | Entities (read records, download attachments) |
| `DataFabric.Data.Write` | Entities (insert, update, delete records) |
| `DataFabric.Schema.Read` | Entities (list/get entities), ChoiceSets |
| `OR.Administration` | Buckets (full access) |
| `OR.Administration.Read` | Buckets (read-only) |
| `OR.Assets` | Assets (full access) |
| `OR.Assets.Read` | Assets (read-only) |
| `OR.Execution` | Processes (full access to listing) |
| `OR.Execution.Read` | Processes (read-only listing) |
| `OR.Jobs` | Processes (start jobs) |
| `OR.Jobs.Write` | Processes (start jobs) |
| `OR.Queues` | Queues (full access) |
| `OR.Queues.Read` | Queues (read-only) |
| `OR.Tasks` | Tasks (full access) |
| `OR.Tasks.Read` | Tasks (read-only) |
| `OR.Tasks.Write` | Tasks (write operations) |
| `PIMS` | MaestroProcesses, ProcessInstances, Cases, CaseInstances |
