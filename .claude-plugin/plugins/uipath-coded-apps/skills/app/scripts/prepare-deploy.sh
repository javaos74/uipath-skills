#!/usr/bin/env bash
# prepare-deploy.sh — Creates deployment config files in the dist/ directory
# Usage: bash scripts/prepare-deploy.sh <project-id> [dist-dir]
#
# Arguments:
#   project-id  The project ID from `uipath register app`
#   dist-dir    Build output directory (default: dist)
#
# Creates operate.json, entry-points.json, and bindings.json in the dist directory.
# These files are required by `uipath pack` and `uipath push`.
#
# Example:
#   npm run build
#   bash scripts/prepare-deploy.sh my-project-id
#   uipath pack dist

set -euo pipefail

PROJECT_ID="${1:?Usage: prepare-deploy.sh <project-id> [dist-dir]}"
DIST_DIR="${2:-dist}"
UNIQUE_ID=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "$(date +%s)-$(od -An -N4 -tx1 /dev/urandom | tr -d ' ')")

if [ ! -d "$DIST_DIR" ]; then
  echo "ERROR: Build directory '$DIST_DIR' does not exist. Run 'npm run build' first."
  exit 1
fi

echo "==> Creating deployment config files in $DIST_DIR/"

cat > "$DIST_DIR/operate.json" << EOF
{
  "\$schema": "https://cloud.uipath.com/draft/2024-12/operate",
  "projectId": "${PROJECT_ID}",
  "main": "index.html",
  "contentType": "webapp",
  "targetFramework": "Portable",
  "runtimeOptions": {
    "requiresUserInteraction": false,
    "isAttended": false
  },
  "designOptions": {
    "projectProfile": "Development",
    "outputType": "webapp"
  }
}
EOF
echo "  Created operate.json (projectId: $PROJECT_ID)"

cat > "$DIST_DIR/entry-points.json" << EOF
{
  "\$schema": "https://cloud.uipath.com/draft/2024-12/entry-point",
  "\$id": "entry-points-doc-001",
  "entryPoints": [
    {
      "filePath": "index.html",
      "uniqueId": "${UNIQUE_ID}",
      "type": "api",
      "input": {},
      "output": {}
    }
  ]
}
EOF
echo "  Created entry-points.json (uniqueId: $UNIQUE_ID)"

cat > "$DIST_DIR/bindings.json" << 'EOF'
{
  "version": "1.0",
  "resources": []
}
EOF
echo "  Created bindings.json"

echo ""
echo "==> Deployment configs ready in $DIST_DIR/"
echo ""
echo "Next steps:"
echo "  uipath pack $DIST_DIR"
echo "  uipath publish <path-to-nupkg>"
echo "  uipath deploy"
echo ""
echo "Or use push for atomic sync:"
echo "  uipath push $PROJECT_ID"
