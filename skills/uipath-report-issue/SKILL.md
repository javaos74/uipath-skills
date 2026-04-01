---
name: uipath-report-issue
description: "Report a skill issue with auto-captured context. TRIGGER when: user says 'report issue', 'report bug', 'something is wrong', 'file a bug', 'this isn't working', 'skill bug', or invokes /report-issue. DO NOT TRIGGER when: user is asking a question, requesting help, or describing expected behavior."
metadata:
  allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
---

# UiPath Skill Issue Reporter

Captures diagnostic context from the current project and files a structured GitHub Issue on [UiPath/skills](https://github.com/UiPath/skills).

## When to Use

- User hit a problem while using any UiPath skill (flow, coded-workflows, rpa-workflows, coded-agents, coded-apps, platform, servo)
- User explicitly asks to report a bug or file an issue
- A skill produced incorrect output, wrong CLI commands, or bad JSON

## Prerequisites

- `gh` CLI authenticated with access to `UiPath/skills` (`gh auth status`)
- If not authenticated, tell the user to run: `gh auth login`

## Workflow

### Step 1 — Ask what went wrong

Ask the user a **single question**:

> What went wrong? Describe what you were trying to do and what happened instead.

Store their response as `USER_DESCRIPTION`.

### Step 2 — Detect skill context

Run these checks in order. Stop at the first match.

```bash
# 1. Flow
ls *.flow flow_files/*.flow 2>/dev/null && echo "SKILL=uipath-flow"

# 2. Coded Agents (Python)
test -f pyproject.toml && grep -q "uipath" pyproject.toml 2>/dev/null && echo "SKILL=uipath-coded-agents"

# 3. Coded Workflows (C#)
test -f project.json && ls *.cs 2>/dev/null | head -1 && echo "SKILL=uipath-coded-workflows"

# 4. RPA Workflows (XAML)
test -f project.json && ls *.xaml 2>/dev/null | head -1 && echo "SKILL=uipath-rpa-workflows"

# 5. Coded Apps
test -f package.json && test -d .uipath && echo "SKILL=uipath-coded-apps"

# 6. Platform (no project, auth-only)
echo "SKILL=uipath-platform"
```

If detection is ambiguous or wrong, ask the user to confirm.

### Step 3 — Capture diagnostic context

Collect the following. **NEVER capture secrets, tokens, passwords, or connection IDs.** Sanitize all output before including it.

#### Always capture

```bash
# CLI version
uip --version 2>&1

# Auth status (tenant/org info only, NOT tokens)
uip login status --output json 2>&1 | grep -v -i "token\|secret\|password\|key"

# OS and shell
uname -a
echo $SHELL
```

#### Per-skill context

| Skill | What to capture |
|---|---|
| **uipath-flow** | `.flow` file content (strip `bindings_v2.json` secrets), `uip flow validate` output, `project.uiproj`, directory listing |
| **uipath-coded-workflows** | `project.json` (dependencies), last `uip rpa validate` output, list of `.cs` files |
| **uipath-rpa-workflows** | `project.json`, last `uip rpa get-errors` output, list of `.xaml` files |
| **uipath-coded-agents** | `pyproject.toml`, `bindings.json` (strip secrets), `evaluations/` listing |
| **uipath-coded-apps** | `package.json`, `.uipath/` listing, last build errors |
| **uipath-platform** | `uip login status` output, last command + error |
| **uipath-servo** | `servo` version, last command + error, `servo targets` output |

#### Sanitization rules

Before including any file content:

1. Remove lines containing: `token`, `secret`, `password`, `apiKey`, `connectionId`, `credentials`, `authorization`
2. Replace GUIDs in `bindings_v2.json` connection fields with `<REDACTED>`
3. Truncate files longer than 200 lines — include first 100 and last 50 with `... [truncated] ...` in between
4. Never include `~/.uipath/.auth` or any auth token files

### Step 4 — Build the issue body

Structure the GitHub Issue with this template:

```markdown
## Description

{USER_DESCRIPTION}

## Skill

`{DETECTED_SKILL}`

## Environment

- **uip version:** {version}
- **OS:** {os}
- **Tenant:** {tenant_name} (org: {org_name})

## Diagnostic Context

<details>
<summary>Project structure</summary>

{directory listing}

</details>

<details>
<summary>Validation / error output</summary>

{validation output or last error}

</details>

<details>
<summary>Relevant file content</summary>

{sanitized file content}

</details>

## Steps to Reproduce

1. {inferred from context — e.g., "Created a flow with `uip flow init`"}
2. {next step}
3. {step where it failed}

## Expected vs Actual

- **Expected:** {what should have happened}
- **Actual:** {what happened instead}
```

### Step 5 — Confirm with user before filing

Show the user:
1. The issue **title** (short, descriptive)
2. A **summary** of what will be included (not the full body)
3. Ask: **"Should I file this issue on UiPath/skills? (yes/no)"**

> **NEVER file an issue without explicit user confirmation.**

### Step 6 — Create the GitHub Issue

```bash
gh issue create --repo UiPath/skills \
  --title "[{SKILL}] {short_description}" \
  --label "bug,{SKILL}" \
  --body "{ISSUE_BODY}"
```

If the label doesn't exist yet, create without labels and note it in the output.

After creation, show the user the issue URL.

### Step 7 — Optional: Post to Slack

If a Slack notification channel is configured, post a short summary:

> **New skill issue filed:** [{title}]({issue_url})
> **Skill:** {SKILL} | **Reporter:** {user} | **Summary:** {one-line}

Skip this step if no Slack channel is configured. Do not ask the user to configure one.

## Labels Convention

| Label | When |
|---|---|
| `bug` | Always |
| `uipath-flow` | Flow skill issues |
| `uipath-coded-workflows` | Coded workflow issues |
| `uipath-rpa-workflows` | RPA/XAML issues |
| `uipath-coded-agents` | Agent issues |
| `uipath-coded-apps` | App issues |
| `uipath-platform` | Platform/auth/orchestrator issues |
| `uipath-servo` | Servo/UI automation issues |
| `skill-content` | Wrong instructions, missing docs |
| `cli-gap` | Missing CLI command or flag |
| `expression-error` | Wrong expression syntax or Jint issue |

## Anti-Patterns

- **Never file an issue without user confirmation**
- **Never include secrets, tokens, or credentials** in the issue body
- **Never include full conversation history** — summarize, don't dump
- **Never auto-assign** — let the maintainers triage
- **Never include customer/business data** — only project structure and error messages
