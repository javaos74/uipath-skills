"""
Formats skill-eval-results.json into a GitHub PR comment (markdown table).

Usage:
    python report.py skill-eval-results.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _skill_badge(skills: list[str]) -> str:
    """Shorten skill names for the table: strip 'uipath-coded-agents:' prefix."""
    short = [s.replace("uipath-coded-agents:", "") for s in skills]
    return ", ".join(short) if short else "-"


def _token_fmt(n: int) -> str:
    if n >= 1000:
        return f"{n / 1000:.1f}k"
    return str(n)


def _interruption_cell(count: int, max_i: int) -> str:
    if count > max_i:
        return f"**{count}/{max_i}** :x:"
    if max_i == 0:
        return f"{count}/{max_i}"
    return f"{count}/{max_i}"


def format_comment(results: list[dict]) -> str:
    passed = sum(1 for r in results if r["passed"])
    total = len(results)
    summary_emoji = ":white_check_mark:" if passed == total else ":x:"

    lines = [
        "## Skill Eval Results",
        "",
        f"{summary_emoji} **{passed}/{total} cases passed**",
        "",
        "| Skill | Case | Interrupts | Skills invoked | Tokens in/out | Files | Status |",
        "|-------|------|:----------:|----------------|:-------------:|:-----:|:------:|",
    ]

    for r in results:
        status = ":white_check_mark:" if r["passed"] else ":x:"
        files = ":white_check_mark:" if r["task_success"] else (":x:" if r["expected_files"] else "-")
        tokens = f"{_token_fmt(r['total_input_tokens'])} / {_token_fmt(r['total_output_tokens'])}"
        interrupts = _interruption_cell(r["interruption_count"], r["max_interruptions"])
        skills = _skill_badge(r["skills_invoked"])

        lines.append(
            f"| {r['skill']} | {r['case_id']} | {interrupts} | {skills} | {tokens} | {files} | {status} |"
        )

    # Failure details block
    failed = [r for r in results if not r["passed"]]
    if failed:
        lines += ["", "### Failures", ""]
        for r in failed:
            lines.append(f"**`{r['case_id']}`**: {r['failure_reason']}")
            if r.get("missing_required_skills"):
                lines.append(f"- Skills not invoked: `{'`, `'.join(r['missing_required_skills'])}`")
            if r.get("missing_files"):
                lines.append(f"- Missing files: `{'`, `'.join(r['missing_files'])}`")
            if r.get("error"):
                lines.append(f"- Error: `{r['error']}`")
            lines.append("")

    # Per-case turn breakdown (collapsible)
    lines += ["", "<details>", "<summary>Per-turn token breakdown</summary>", ""]
    for r in results:
        if not r["turns"]:
            continue
        lines.append(f"**{r['case_id']}** ({len(r['turns'])} turn(s))")
        lines.append("")
        lines.append("| Turn | Input tok | Output tok | Interruption | Skills |")
        lines.append("|:----:|----------:|----------:|:------------:|--------|")
        for t in r["turns"]:
            interrupt_marker = ":warning:" if t["is_interruption"] else ""
            skills = _skill_badge(t["skills_invoked"])
            lines.append(
                f"| {t['turn']} | {t['input_tokens']:,} | {t['output_tokens']:,}"
                f" | {interrupt_marker} | {skills} |"
            )
        lines.append("")
    lines.append("</details>")

    return "\n".join(lines)


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python report.py <results.json>", file=sys.stderr)
        return 1

    path = Path(sys.argv[1])
    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        return 1

    results = json.loads(path.read_text())
    comment = format_comment(results)
    print(comment)
    return 0


if __name__ == "__main__":
    sys.exit(main())
