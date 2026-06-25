#!/usr/bin/env bash
set -euo pipefail

VEI_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "=== Vision Electronic Indexing Setup ==="
echo ""

# 1. Python dependencies
echo "[1/3] Installing Python dependencies..."
python3 -m pip install -r "$VEI_DIR/requirements.txt" --quiet
echo "  Done."

# 2. Environment file
ENV_FILE="$VEI_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "[2/3] Creating .env file from .env.example..."
    cp "$VEI_DIR/.env.example" "$ENV_FILE"
    echo "  Edit $ENV_FILE with your Cloudflare Workers AI credentials."
else
    echo "[2/3] .env file already exists."
fi

# 3. MCP config
echo "[3/3] To configure your agent, copy the appropriate config from configs/:"
echo ""
echo "  OpenCode:  cp configs/opencode.json.example <project>/.opencode/opencode.json"
echo "  Claude:    cp configs/claude.json.example <project>/.claude/settings.json"
echo "  Codex CLI: cp configs/codex.json.example <project>/.codex/settings.json"
echo "  Cursor:    cp configs/cursor.json.example <project>/.cursor/mcp.json"
echo ""
echo "Then edit the file to set the path to vision_inventory_mcp.py and your credentials."
echo ""
echo "=== Setup complete ==="
