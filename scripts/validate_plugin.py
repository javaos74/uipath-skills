"""
Structural validation for uipath-coded-agents plugin.

Checks:
  1. plugin.json and marketplace.json are valid JSON with required fields
  2. Every skill directory has a SKILL.md with required frontmatter keys
  3. Every reference linked from a SKILL.md actually exists on disk
  4. Every file under references/ is reachable from at least one SKILL.md
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
PLUGIN_DIR = REPO_ROOT / "plugins" / "uipath-coded-agents"
SKILLS_DIR = PLUGIN_DIR / "skills"

REQUIRED_PLUGIN_FIELDS = {"name", "version", "description", "author"}
REQUIRED_FRONTMATTER_KEYS = {"description", "allowed-tools", "user-invocable"}

errors: list[str] = []
warnings: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)
    print(f"  ERROR  {msg}")


def warn(msg: str) -> None:
    warnings.append(msg)
    print(f"  WARN   {msg}")


# ---------------------------------------------------------------------------
# 1. JSON manifest validation
# ---------------------------------------------------------------------------

def validate_json_manifest(path: Path, required_fields: set[str]) -> dict:
    if not path.exists():
        err(f"Missing file: {path.relative_to(REPO_ROOT)}")
        return {}
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as e:
        err(f"Invalid JSON in {path.relative_to(REPO_ROOT)}: {e}")
        return {}
    missing = required_fields - set(data.keys())
    for field in sorted(missing):
        err(f"{path.relative_to(REPO_ROOT)}: missing required field '{field}'")
    return data


# ---------------------------------------------------------------------------
# 2. SKILL.md frontmatter validation
# ---------------------------------------------------------------------------

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---", re.DOTALL)


def parse_frontmatter(content: str) -> dict[str, str]:
    m = FRONTMATTER_RE.match(content)
    if not m:
        return {}
    result: dict[str, str] = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            result[key.strip()] = value.strip()
    return result


def validate_skill_md(skill_dir: Path) -> None:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        err(f"Missing SKILL.md in {skill_dir.relative_to(PLUGIN_DIR)}")
        return
    content = skill_md.read_text()
    fm = parse_frontmatter(content)
    if not fm:
        err(f"{skill_md.relative_to(REPO_ROOT)}: no frontmatter found")
        return
    for key in REQUIRED_FRONTMATTER_KEYS:
        if key not in fm:
            err(f"{skill_md.relative_to(REPO_ROOT)}: frontmatter missing '{key}'")
        elif not fm[key]:
            err(f"{skill_md.relative_to(REPO_ROOT)}: frontmatter '{key}' is empty")


# ---------------------------------------------------------------------------
# 3. Reference link validation
# ---------------------------------------------------------------------------

# Matches markdown links: [text](path) — local paths only (no http)
# Deliberately restrictive: targets must look like file paths (no spaces, no newlines)
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^\s)]+)\)")

# Matches fenced code blocks (``` ... ```) to strip before link scanning
CODE_FENCE_RE = re.compile(r"```.*?```", re.DOTALL)
# Matches inline code (`...`)
INLINE_CODE_RE = re.compile(r"`[^`\n]+`")


def strip_code_blocks(content: str) -> str:
    """Remove fenced and inline code blocks so their contents aren't link-scanned."""
    content = CODE_FENCE_RE.sub("", content)
    content = INLINE_CODE_RE.sub("", content)
    return content


def resolve_link(source_file: Path, target: str) -> Path | None:
    """Resolve a markdown link target relative to its source file."""
    # Skip external links and skill cross-references (/uipath-coded-agents:*)
    if target.startswith("http") or target.startswith("/"):
        return None
    # Strip anchors
    target = target.split("#")[0]
    if not target:
        return None
    resolved = (source_file.parent / target).resolve()
    return resolved


def collect_links(md_file: Path) -> list[tuple[str, Path]]:
    """Return (link_text, resolved_target) for all local links in a markdown file."""
    content = strip_code_blocks(md_file.read_text())
    results = []
    for text, target in LINK_RE.findall(content):
        resolved = resolve_link(md_file, target)
        if resolved is not None:
            results.append((text, resolved))
    return results


def validate_links(md_file: Path, reachable: set[Path]) -> None:
    for text, target in collect_links(md_file):
        if not target.exists():
            err(
                f"{md_file.relative_to(REPO_ROOT)}: broken link '[{text}]' "
                f"-> '{target.relative_to(PLUGIN_DIR) if PLUGIN_DIR in target.parents else target}'"
            )
        else:
            reachable.add(target)


# ---------------------------------------------------------------------------
# 4. Orphan detection
# ---------------------------------------------------------------------------

def find_orphans(reachable: set[Path]) -> None:
    all_refs = set(PLUGIN_DIR.rglob("references/**/*.md"))
    for ref in sorted(all_refs):
        if ref not in reachable:
            warn(f"Orphaned reference (not linked from any SKILL.md): {ref.relative_to(REPO_ROOT)}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    print("Validating plugin structure...\n")

    # 1. JSON manifests
    print("[1/4] JSON manifests")
    validate_json_manifest(
        PLUGIN_DIR / ".claude-plugin" / "plugin.json",
        REQUIRED_PLUGIN_FIELDS,
    )
    marketplace = validate_json_manifest(
        REPO_ROOT / ".claude-plugin" / "marketplace.json",
        {"name", "owner", "plugins"},
    )
    if marketplace:
        plugin_names_in_manifest = {p["name"] for p in marketplace.get("plugins", [])}
        actual_plugin_dirs = {d.name for d in (REPO_ROOT / "plugins").iterdir() if d.is_dir()}
        for name in actual_plugin_dirs - plugin_names_in_manifest:
            warn(f"Plugin directory '{name}' not listed in marketplace.json")

    # 2. SKILL.md frontmatter
    print("\n[2/4] SKILL.md frontmatter")
    skill_dirs = [d for d in SKILLS_DIR.iterdir() if d.is_dir()]
    if not skill_dirs:
        err(f"No skill directories found under {SKILLS_DIR.relative_to(REPO_ROOT)}")
    for skill_dir in sorted(skill_dirs):
        validate_skill_md(skill_dir)

    # 3. Reference links
    print("\n[3/4] Reference links")
    reachable: set[Path] = set()
    all_md_files = list(PLUGIN_DIR.rglob("*.md"))
    for md_file in sorted(all_md_files):
        validate_links(md_file, reachable)

    # 4. Orphan detection
    print("\n[4/4] Orphan reference files")
    find_orphans(reachable)

    print(f"\n{'='*60}")
    if errors:
        print(f"FAILED — {len(errors)} error(s), {len(warnings)} warning(s)")
        return 1
    elif warnings:
        print(f"PASSED with {len(warnings)} warning(s)")
        return 0
    else:
        print("PASSED — no issues found")
        return 0


if __name__ == "__main__":
    sys.exit(main())
