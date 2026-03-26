# Triage Sub-Agent

Classify the problem and gather just enough data to enable hypothesis generation.

**Follow `agents/shared.md` first.**

## Inputs

- User's problem description (in your prompt)

## Outputs

1. `.investigation/state.json` — see `schemas/state.schema.md`
2. `.investigation/raw/triage-{command-name}.json` — raw CLI response
3. `.investigation/evidence/triage-initial.json` — see `schemas/evidence.schema.md`

## Steps

1. **Classify scope** using the user's problem description.
2. **If classification is unclear**, try to narrow it down (max 3 attempts) before asking the user:
   - Run up to 3 `uip docsai ask` queries with different keyword combinations
   - Read `references/summary.md` and follow its links to filter down to a specific product/package and playbook
   - If after 3 queries you can pin the issue: proceed with that classification
   - If after 3 queries you still cannot classify: **stop searching**. Set `needs_user_input: true` with a targeted question (include what you found so far so the user can confirm or redirect). Still write `state.json` with what you know.

3. **If the user provided an identifier** (job ID, queue name, etc.): run uip commands to fetch initial data. Write raw response, then write interpreted evidence summary.

4. **Correlate data to the reported problem** — read `references/investigation_guide.md` and follow its data correlation rules. If the matched product/package has an `investigation_guide.md` (linked from its summary), read that too and apply its additional rules. If data doesn't match: **discard it**, do NOT use unrelated data as a proxy, and ask for clarification.

5. **Discover matching playbooks** — read `references/summary.md`, follow links to the matched product/package, scan its playbooks.

6. **Gather additional data from matched playbooks** — read the matched playbook(s) to understand what conditions might cause the issue. If the playbook mentions data points that can be fetched with lightweight uip commands (e.g., asset existence, folder permissions, trigger status, process version), gather them now. This gives the hypothesis generator and tester a richer starting point.

## Boundaries

- Data-gathering uip command 
- Do NOT pull logs, traces, or heavy data — that's the tester's job
- Do NOT generate hypotheses — that's the generator's job
- If you cannot get data about the specific entity the user reported (e.g., CLI lacks a queue-items command), **STOP and say so** — do NOT substitute with tangentially related data (e.g., using random faulted jobs as a "proxy" for queue items)
