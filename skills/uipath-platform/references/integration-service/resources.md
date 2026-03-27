# Resources

Resources represent the data objects available through a connector (e.g., Salesforce Account, Contact, Opportunity). Each resource supports a set of CRUD operations.

> Full command syntax and options: [uip-commands.md — Integration Service](../uip-commands.md#integration-service-is). Domain-specific usage patterns are shown inline below.

## Contents
- Listing and Describing Resources
- Response Fields
- Describe Response
- Describe Failures
- Execute Operations
- Pagination
- Execute Error Handling

For reference field resolution (simple refs, dependency chains, required field validation), see [reference-resolution.md](reference-resolution.md).

---

## Listing and Describing Resources

**Always pass `--connection-id`** to get connection-specific metadata including custom objects and fields. Without it, only standard objects/fields are returned.

## Response Fields

| Field | Description |
|---|---|
| **`Name`** | Resource identifier (used in commands) |
| `DisplayName` | Human-readable name |
| `Path` | API path for this resource |
| `Type` | Resource type (standard, custom) |
| `SubType` | Sub-type (e.g., method, entity) |

## Describe Response

The describe command fetches JSON Schema from the IS API (`Accept: application/schema+json`) and returns a compact summary:

| Section | Description |
|---|---|
| **operations** | Available operations — each with method, path, description, parameters (name, type, required, description) |
| **fields** | All fields — each with name, type, required flag, enum values (if any), $ref (if any) |

Use `--operation <Create|List|Retrieve|Update|Delete|Replace>` to filter to a single operation and reduce output.

Results are cached locally. Use `--refresh` to bypass cache after re-auth or schema changes.

---

## Describe Failures

Some resources return an error on describe. This is a **server-side metadata gap** — do not retry with `--refresh`.

**Recovery:**

1. **Skip describe entirely** — do not waste calls retrying.
2. **Infer fields from user context** — use the field names and values the user provided in their request.
3. **Infer reference fields from naming** — see [reference-resolution.md — Inferring References Without Describe](reference-resolution.md#inferring-references-without-describe).
4. **Attempt execute directly** — let the server validate. If a field is rejected, read the error and adjust.

---

## Execute Operations

| Verb | Description | `--body` | `--query` |
|---|---|---|---|
| `create` | Create a new record | Yes | No |
| `list` | Retrieve multiple records | No | Optional (`limit=10&offset=0`) |
| `get` | Get a single record by ID | No | Yes (`id=<RECORD_ID>`) |
| `update` | Partial update (PATCH) | Yes | Yes (`id=<RECORD_ID>`) |
| `delete` | Delete a record | No | Yes (`id=<RECORD_ID>`) |
| `replace` | Full replacement (PUT) | Yes | Yes (`id=<RECORD_ID>`) |

> **Update** (PATCH) = change specific fields. **Replace** (PUT) = overwrite entire record. Default to **Update** unless the user says "replace" or "overwrite".

---

## Pagination

`uip is resources execute list` may not return all results in a single call. **Always check for pagination** when searching for a specific item or listing all items.

### Connector pagination (elements-* headers)

Most IS connectors use the `elements-*` pagination protocol:

```bash
# First page
uip is resources execute list "<connector-key>" "<resource>" \
  --connection-id "<id>" --page-size 100 --format json
# → Check response: elements-has-more=true, elements-next-page-token="abc123"

# Next page (pass the token)
uip is resources execute list "<connector-key>" "<resource>" \
  --connection-id "<id>" --page-size 100 --next-page "abc123" --format json
# → Continue until elements-has-more=false or target item is found
```

**Stop early:** If you find the target item in the current page, no need to fetch remaining pages.

### Query-param pagination (offset/limit)

Some resources support `offset`/`limit` via `--query`:

```bash
uip is resources execute list "<connector-key>" "<object>" \
  --connection-id "<id>" --query "limit=50&offset=0" --format json
# → next page: --query "limit=50&offset=50"
```

Stop when the result set is empty or smaller than the limit.

### HTTP connector exception

Connectors with key `uipath-uipath-http` do NOT use the `elements-*` pagination headers. These depend on vendor-specific pagination. Handle on a case-by-case basis.

---

## Execute Error Handling

When an execute command fails, the CLI returns:
- **`Message`**: HTTP status (e.g., `400 Bad Request`)
- **`Instructions`**: The raw vendor error response body as JSON

Read the `Instructions` field to understand the actual vendor error and apply the fix directly. The CLI does not transform or interpret vendor errors — the raw response is passed through so the agent can act on it.

For the self-healing loop (read error → diagnose → discover correct values → fix → retry), see [agent-workflow.md — Error Self-Healing](agent-workflow.md#error-self-healing).
