---
description: UiPath Python SDK assistant - Create, run, and evaluate coded agents
allowed-tools: Bash, Read, Write, Glob, Grep
---

# UiPath Python SDK Assistant

Welcome to the UiPath Python SDK Assistant! This tool helps you create, run, and evaluate UiPath coded agents with AI-powered assistance.

The assistant automatically detects your UiPath project structure—no setup needed!

## 📍 Project Context (Auto-Detected)

I've detected your current directory. Analyzing project structure...

**Project Status:**
- UiPath Project: Checking...
- Agents: Detecting...
- Evaluations: Scanning...

The context is cached and automatically refreshed as you work. You can use skills directly without needing this menu!

---

## Available Commands

### 🚀 Create a New Agent
**Command:** `/uipath-coded-agents:create-agent [agent-name]`
- Creates a new UiPath agent from scratch
- Interactive setup with input/output field configuration
- AI-powered business logic implementation
- Auto-generates Pydantic models and main function

### ▶️ Run an Agent
**Command:** `/uipath-coded-agents:run [agent-name]`
- Execute an existing UiPath agent interactively
- Schema-driven input prompts
- Displays results in output panel
- Test agents without leaving Claude Code
- ℹ️ Requires: entry-points.json (create with `/uipath-coded-agents:create-agent`)

### 🧪 Create & Run Evaluations
**Command:** `/uipath-coded-agents:eval`
- Create comprehensive evaluations for your agents
- Run evaluations against your agents
- Define expected inputs and outputs with custom evaluators
- View detailed results with pass/fail status
- Analyze performance metrics and insights
- ℹ️ Requires: entry-points.json and uipath.json

---

## 🎯 Smart Command Detection

Based on your project context, the extension will:
- ✅ Auto-show available agents when you run `/uipath-coded-agents:run`
- ✅ Auto-list evaluations when you run `/uipath-coded-agents:eval`
- ✅ Auto-detect missing requirements and show helpful guidance
- ✅ Cache project info for fast subsequent commands

**Example:**
- If you have agents, just type `/uipath-coded-agents:run` and select from list
- If you have evaluations, just type `/uipath-coded-agents:eval` without specifying file
- If something's missing, you'll get a clear message on how to fix it

---

## Quick Start

### First Time?
1. Start with: `/uipath-coded-agents:create-agent my-first-agent`
2. Then run: `/uipath-coded-agents:run my-first-agent`
3. Create & run evals: `/uipath-coded-agents:eval`

### Have a Project?
- Just type `/uipath-coded-agents:run` - auto-detects your agents
- Just type `/uipath-coded-agents:eval` - auto-discovers your evals

---

## Tips

- All agents use the UiPath SDK with automatic tracing
- Input/output fields are strongly typed with Pydantic
- Evaluations support multiple evaluation sets with custom evaluators
- **Context is cached automatically** - instant detection on subsequent commands
- The extension works globally—use it in any directory!
- Use the `/uipath-coded-agents` prefix for all skills: `/uipath-coded-agents:create-agent`, `/uipath-coded-agents:run`, etc.

---

## Context Awareness

**Automatic Detection:**
- Detects UiPath projects in current directory
- Caches agent and evaluation metadata
- Refreshes context every 5 minutes
- Makes context available to all skills via environment variables

**Use the skills with the `/uipath-coded-agents` prefix:**
```bash
/uipath-coded-agents:run           # Auto-detects agents from cache
/uipath-coded-agents:eval          # Auto-discovers evaluation files and creates evals
```

---

For more help, visit: https://uipath.github.io/uipath-python/
