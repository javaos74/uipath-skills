# Shared Agent Instructions

All diagnostic sub-agents follow these rules.

## Startup

1. Create `.investigation/`, `.investigation/evidence/`, `.investigation/raw/` if they don't exist

## Available Tools & Resources

### uip CLI
The primary tool for interacting with the UiPath platform. Always use `--format json` for structured output.
- Discover commands: `uip --help` or `uip <subcommand> --help`
- Some commands support `-o, --output <path>` to save results directly to a directory.

### Documentation Search
Search UiPath documentation and knowledge base:
```
uip docsai ask "<question>" --source [docs, technical_solution_articles]
```
Use this to look up error messages, features, configuration, and troubleshooting guidance. Run multiple queries with different keyword combinations for thorough coverage.

### Knowledge Base (references/)
Product knowledge base with per-product documentation, features, and diagnostic playbooks.

**Start here:** Read `references/summary.md` — it routes you to the correct product/package sub-folder. Follow its links to drill down.

**What playbooks are:** Playbooks describe what can be tested from the client side and what conditions might generate a particular issue. They provide context — failure modes, contributing factors, known patterns, and what to look for. They are NOT step-by-step test scripts. Use them to inform your approach, not as a checklist to execute blindly.

## Raw Data Rule

- Write full raw responses to `.investigation/raw/` **immediately**
- Do NOT keep raw data in context — write first, read back only specific fields if needed
- Evidence files reference raw files via `raw_data_ref`

## Data Integrity

Follow the data correlation rules in `references/investigation_guide.md` (and the product-specific guide if one exists). If data doesn't match the user's reported problem, discard it.

If you cannot retrieve the data you need: set `needs_user_input: true` and explain the gap. Do NOT substitute unrelated data or fabricate findings.

## It Is OK to Not Find a Root Cause

Not every investigation will identify a root cause. If you've exhausted available evidence and hypotheses without a clear answer, that is a valid outcome — not a failure. Report what you found, what was ruled out, and recommend the user open a UiPath support ticket with the evidence gathered.

## Constraints

- Do NOT generate or execute code (no Python scripts, no inline code). Shell commands for file I/O and uip are fine.
- Do NOT perform work outside your role (see your agent file for boundaries)
- If you need user input: set `needs_user_input: true` and `user_question` in your output, then stop

## Output Schemas

See `schemas/` for the canonical JSON schemas: `state.schema.md`, `hypotheses.schema.md`, `evidence.schema.md`.
