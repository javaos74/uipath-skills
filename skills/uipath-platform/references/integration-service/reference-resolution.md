# Reference Resolution

How to resolve reference fields — fields whose values must be looked up from another resource before create/update operations.

> Full command syntax and options: [uip-commands.md — Integration Service](../uip-commands.md#integration-service-is). Domain-specific usage patterns are shown inline below.

## Contents
- Reference Fields (CRITICAL)
- Simple Reference Fields (no dependencies)
- Field Dependency Chains
- Inferring References Without Describe
- Validate Required Fields Before Executing

---

## Reference Fields (CRITICAL)

Some fields in the describe response have a `reference` section — their value must be looked up from another resource. For each reference field: list the `referencedObject`, collect the `lookupValue` from results, and present options to the user.

A reference field in the describe output:

```json
{
  "field": "departmentId",
  "referencedObject": "departments",
  "lookupValue": "id",
  "hint": "Resolve by executing: is resources execute list ... \"departments\" ..."
}
```

### Example: Creating a Zoho Desk Ticket

```bash
# 1. Describe → discover referenceFields: departmentId → "departments", contactId → "contacts"
uip is resources describe "uipath-zoho-desk" "tickets" \
  --connection-id "<id>" --operation Create --format json

# 2. Resolve references
uip is resources execute list "uipath-zoho-desk" "departments" --connection-id "<id>" --format json
# → { "id": "1892000000006907", "name": "Engineering" }
uip is resources execute list "uipath-zoho-desk" "contacts" --connection-id "<id>" --format json
# → { "id": "1892000000048009", "name": "John Doe" }

# 3. Execute with resolved IDs
uip is resources execute create "uipath-zoho-desk" "tickets" \
  --connection-id "<id>" \
  --body '{"departmentId": "1892000000006907", "subject": "Bug report", "contactId": "1892000000048009"}' \
  --format json
```

### Simple reference fields (no dependencies)

For reference fields with no parent dependency, resolve directly by listing the referenced object and matching the user's value:

```bash
# Resolve Slack channel "#test-slack" to its channel ID
uip is resources execute list "uipath-salesforce-slack" "curated_channels?types=public_channel,private_channel" \
  --connection-id "<id>" --format json
# → { "id": "C1234567890", "name": "test-slack" }
```

**Present options to the user** when multiple matches exist. Use the resolved IDs (not display names) in `--body` or `--query`.

---

## Field Dependency Chains

Some reference fields **depend on other fields** — the child field's valid values are scoped by the parent field's selection. The connector's underlying metadata encodes this in `reference.path` using template variables like `{fields.project.key}`.

### How to detect dependencies

When two fields share the same `reference.objectName` (e.g., both reference `"project"`), or when a field's reference path contains `{otherField}`, they form a dependency chain. Resolve them **in order** — parent first, then child using the parent's resolved value.

**CRITICAL: If a parent field value is NOT in the user's prompt, you MUST ask the user for it BEFORE attempting to resolve any child fields.** Do not resolve child fields without a scoped parent — the results will be wrong or ambiguous.

### Common pattern: Jira project → issue type

The Jira `curated_create_issue` resource has this dependency:

```
fields.project.key  → reference.path: /project/search                          (no dependency)
fields.issuetype.id → reference.path: /project/{fields.project.key}/issuetypes (depends on project.key)
```

**Wrong** — listing `issuetype` globally returns Bug types from ALL projects:
```bash
uip is resources execute list "uipath-atlassian-jira" "issuetype" \
  --connection-id "<id>" --format json
# → Bug (id=1), Bug (id=10004), Bug (id=12947), ... dozens of duplicates
```

**Correct** — resolve project first, then list issue types scoped to that project:
```bash
# Step 1: Resolve project
uip is resources execute list "uipath-atlassian-jira" "project" \
  --connection-id "<id>" --format json
# → { "key": "ENGCE", "name": "Integration Service", "id": "10845" }

# Step 2: Resolve issue types FOR that project (scoped path)
uip is resources execute list "uipath-atlassian-jira" "project/ENGCE/issuetypes" \
  --connection-id "<id>" --format json
# → { "id": "10004", "name": "Bug" }  ← only issue types valid for ENGCE
```

### General rule

When resolving reference fields:
1. **Sort fields by dependency** — fields with no `{template}` in their reference path come first
2. **Resolve parent fields** — list the parent resource, pick the value
3. **Substitute into child path** — replace `{parentField}` in the child's reference path with the resolved value
4. **Resolve child fields** — list the scoped resource using the substituted path

This pattern applies across connectors (Jira, Salesforce, ServiceNow, Zoho, etc.) wherever child fields are scoped by parent selections.

---

## Inferring References Without Describe

When describe metadata is unavailable (see [resources.md — Describe Failures](resources.md#describe-failures)), infer reference fields from naming conventions:

- Fields ending in **`Id`** (e.g., `PromotionId`, `AccountId`) typically reference the object with the matching base name (`Promotion`, `Account`).
- List the inferred object to resolve the ID: `is resources execute list "<connector-key>" "<base-name>" --connection-id "<id>" --format json`
- Match the user's value by `Name` or `DisplayName` in the results.

### Example: Coupon → Promotion (no describe available)

```bash
# User wants: create coupon "XYZ" for promotion "Chandu Test"
# Infer: PromotionId → list Promotion objects
uip is resources execute list "uipath-salesforce-sfdc" "Promotion" \
  --connection-id "<id>" --format json
# → { "Id": "<promotion-id>", "Name": "Summer Sale" }

# Use resolved Id in create
uip is resources execute create "uipath-salesforce-sfdc" "Coupon" \
  --connection-id "<id>" \
  --body '{"CouponCode": "SAVE20", "PromotionId": "<promotion-id>"}' --format json
```

---

## Validate Required Fields Before Executing

After resolving references, **check every required field** from the describe response against what the user provided. This is a hard gate — do NOT execute until all required fields have values.

**Process:**
1. Collect all fields where `required: true` from the describe output's `requiredFields`
2. For each required field, check if the user's prompt contains a value for it
3. If any required field is missing, **ask the user** before proceeding:
   - List the missing fields with their `displayName` and `description`
   - For reference fields, explain what kind of value is expected (e.g., "Which Jira project should this issue be created in?")
   - Wait for the user's response before continuing
4. Only after all required fields are accounted for, proceed to execute

**Example — user says "Create a Jira ticket with issue type Bug":**
- Required fields from describe: `fields.project.key` (Project), `fields.issuetype.id` (Issue type), `fields.summary` (Summary)
- User provided: issue type = Bug
- User did NOT provide: project, summary
- **Ask:** "To create this Jira Bug, I need: (1) Which project? (e.g., ENGCE) (2) What should the summary/title be?"
- Wait for response, resolve references with provided values, then execute

> **Do NOT guess or skip missing required fields.** A missing required field will cause a runtime error. It is always better to ask than to assume.
