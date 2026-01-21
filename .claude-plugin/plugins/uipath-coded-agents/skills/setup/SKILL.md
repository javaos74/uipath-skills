---
description: Bootstrap plugin environment and setup resolver for accessing plugin files
---

# Plugin Environment Setup

I'll set up the plugin environment so that all commands can access plugin template files.

First, let me create the `.claude/cpr.sh` resolver script that will dynamically locate the plugin directory:

```bash
mkdir -p .claude

cat > .claude/cpr.sh << 'EOF'
#!/bin/bash
# Claude Plugin Root resolver - finds plugin directory even when installed to cache

# Get plugin name from first argument
if [ -z "$1" ]; then
    echo "Error: Plugin name required as first argument" >&2
    exit 1
fi
PLUGIN_NAME="$1"

# Try CLAUDE_PLUGIN_ROOT first
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
    echo "$CLAUDE_PLUGIN_ROOT"
    exit 0
fi

# Fallback: query installed plugins (handle both plugin name and plugin@marketplace formats)
if [ -f ~/.claude/plugins/installed_plugins.json ]; then
    PLUGIN_PATH=$(jq -r ".plugins | to_entries[] | select(.key == \"$PLUGIN_NAME\" or (.key | test(\"^$PLUGIN_NAME@\"))) | .value[0].installPath" ~/.claude/plugins/installed_plugins.json 2>/dev/null | head -1)
    if [ -n "$PLUGIN_PATH" ]; then
        echo "$PLUGIN_PATH"
        exit 0
    fi
fi

# Last resort: use current directory if we have matching plugin structure
if [ -f "./.claude-plugin/plugin.json" ]; then
    if jq -e ".name == \"$PLUGIN_NAME\" or (.name | test(\"^$PLUGIN_NAME@\"))" ./.claude-plugin/plugin.json >/dev/null 2>&1; then
        echo "."
        exit 0
    fi
fi

# Fallback to workspace
echo "${CLAUDE_PROJECT_DIR:-.}"
EOF

chmod +x .claude/cpr.sh
```

Now all commands can reference plugin templates using:
```bash
"$(.claude/cpr.sh uipath-coded-agents)/templates/*"
```

This resolver will work whether the plugin is:
- Running from the workspace directory
- Installed to `~/.claude/plugins/cache/`
- Or any other location

The environment is now ready for commands to access plugin files!
