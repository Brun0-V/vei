#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-Brun0-V/vei}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.vei}"
VENV_DIR="$INSTALL_DIR/.venv"
PYTHON="${PYTHON:-python3}"

# --local flag: copy from a local repo directory instead of curling from GitHub
LOCAL_SRC=""
if [ "${1:-}" = "--local" ] || [ "${1:-}" = "-l" ]; then
  LOCAL_SRC="${2:-}"
  if [ -z "$LOCAL_SRC" ]; then
    LOCAL_SRC="$(cd "$(dirname "$0")/.." && pwd)"
  fi
  LOCAL_SRC="$(cd "$LOCAL_SRC" && pwd)"
fi

VEI_RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Vision Electronic Indexing Installer ===${NC}"
echo ""

# Detect OS
case "$(uname -s)" in
  Darwin|Linux) OS="posix" ;;
  *)            OS="posix" ;;
esac

# 1. Copy / Download
echo -e "${GREEN}[1/6]${NC} Installing to $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"/{scripts,configs,skills/vision-inventory-workflow,setup,prompts}

if [ -n "$LOCAL_SRC" ]; then
  echo -e "  Copying from ${CYAN}$LOCAL_SRC${NC} ..."
  cp "$LOCAL_SRC/vision_inventory_mcp.py" "$INSTALL_DIR/"
  cp "$LOCAL_SRC/requirements.txt" "$INSTALL_DIR/"
  cp "$LOCAL_SRC/.env.example" "$INSTALL_DIR/"
  [ -f "$LOCAL_SRC/.gitignore" ] && cp "$LOCAL_SRC/.gitignore" "$INSTALL_DIR/" || true
  [ -f "$LOCAL_SRC/LICENSE" ] && cp "$LOCAL_SRC/LICENSE" "$INSTALL_DIR/" || true
  cp "$LOCAL_SRC/scripts/inventory_folder_to_csv.py" "$INSTALL_DIR/scripts/"
  for f in "$LOCAL_SRC"/configs/*.json.example; do
    cp "$f" "$INSTALL_DIR/configs/"
  done
  cp "$LOCAL_SRC/skills/vision-inventory-workflow/SKILL.md" "$INSTALL_DIR/skills/vision-inventory-workflow/"
  cp "$LOCAL_SRC/prompts/vision-inventory-agent-bom.md" "$INSTALL_DIR/prompts/"
else
  for f in vision_inventory_mcp.py requirements.txt .env.example .gitignore LICENSE; do
    curl -fsSL "$VEI_RAW/$f" -o "$INSTALL_DIR/$f"
  done
  for f in scripts/inventory_folder_to_csv.py; do
    curl -fsSL "$VEI_RAW/$f" -o "$INSTALL_DIR/$f"
  done
  for f in configs/opencode.json.example configs/claude.json.example configs/codex.json.example configs/cursor.json.example; do
    curl -fsSL "$VEI_RAW/$f" -o "$INSTALL_DIR/$f"
  done
  curl -fsSL "$VEI_RAW/skills/vision-inventory-workflow/SKILL.md" -o "$INSTALL_DIR/skills/vision-inventory-workflow/SKILL.md"
  curl -fsSL "$VEI_RAW/prompts/vision-inventory-agent-bom.md" -o "$INSTALL_DIR/prompts/vision-inventory-agent-bom.md"
fi
echo -e "  ${GREEN}Done.${NC}"

# 2. Python venv + deps
echo ""
echo -e "${GREEN}[2/6]${NC} Creating Python virtual environment..."
"$PYTHON" -m venv "$VENV_DIR"
echo -e "  ${GREEN}Done.${NC}"

echo -e "${GREEN}[3/6]${NC} Installing Python dependencies..."
"$VENV_DIR/bin/pip" install -r "$INSTALL_DIR/requirements.txt" --quiet
echo -e "  ${GREEN}Done.${NC}"

# 3. Credentials
echo ""
echo -e "${GREEN}[4/6]${NC} Cloudflare Workers AI credentials"
ENV_FILE="$INSTALL_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
  cp "$INSTALL_DIR/.env.example" "$ENV_FILE"
  echo "  Created $ENV_FILE"
fi

echo "  Get these from https://dash.cloudflare.com/ -> AI -> Workers AI -> Use REST API"
echo "  Enter your credentials (or press enter to edit .env later):"
read -rp "  Cloudflare Account ID: " CF_ID || true
read -rp "  Cloudflare API Token: " CF_TOKEN || true

CF_ID="${CF_ID:-}"
CF_TOKEN="${CF_TOKEN:-}"
if [ -n "$CF_ID" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/your_cloudflare_account_id/$CF_ID/" "$ENV_FILE"
  else
    sed -i "s/your_cloudflare_account_id/$CF_ID/" "$ENV_FILE"
  fi
fi
if [ -n "$CF_TOKEN" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/your_cloudflare_workers_ai_token/$CF_TOKEN/" "$ENV_FILE"
  else
    sed -i "s/your_cloudflare_workers_ai_token/$CF_TOKEN/" "$ENV_FILE"
  fi
fi
echo -e "  ${GREEN}Done.${NC}"

# 4. Harness skill install
echo ""
echo -e "${GREEN}[5/6]${NC} Installing skill for your agent..."
install_skill() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  cp "$INSTALL_DIR/skills/vision-inventory-workflow/SKILL.md" "$target"
  echo -e "  Installed skill to ${CYAN}$target${NC}"
}

echo "  Which agent are you using?"
echo "    1) OpenCode"
echo "    2) Claude Code"
echo "    3) Codex CLI"
echo "    4) Pi (original) — uses the original Pi npm package"
echo "    5) All of the above"
echo "    6) Skip (I'll install manually)"
read -rp "  Choice [1-6]: " AGENT_CHOICE || true

AGENT_CHOICE="${AGENT_CHOICE:-}"
case "$AGENT_CHOICE" in
  1) install_skill "$HOME/.config/opencode/skills/vision-inventory-workflow/SKILL.md" ;;
  2) install_skill "$HOME/.claude/skills/vision-inventory-workflow/SKILL.md" ;;
  3) install_skill "$HOME/.agents/skills/vision-inventory-workflow/SKILL.md" ;;
  4)
    echo -e "  ${CYAN}Pi install:${NC} pi install npm:vision-electronic-indexing-pi"
    if command -v pi &>/dev/null; then
      pi install npm:vision-electronic-indexing-pi
    else
      echo "  'pi' command not found. Install Pi first, then run:"
      echo "  pi install npm:vision-electronic-indexing-pi"
    fi
    ;;
  5)
    install_skill "$HOME/.config/opencode/skills/vision-inventory-workflow/SKILL.md"
    install_skill "$HOME/.claude/skills/vision-inventory-workflow/SKILL.md"
    install_skill "$HOME/.agents/skills/vision-inventory-workflow/SKILL.md"
    if command -v pi &>/dev/null; then
      pi install npm:vision-electronic-indexing-pi
    fi
    ;;
  *) echo "  Skipping." ;;
esac

# 5. Summary
echo ""
echo -e "${GREEN}[6/6]${NC} Setup complete!"
echo ""
echo -e "  ${CYAN}VEI installed to:${NC}   $INSTALL_DIR"
echo -e "  ${CYAN}Run server:${NC}         $VENV_DIR/bin/python $INSTALL_DIR/vision_inventory_mcp.py"
echo -e "  ${CYAN}Activate env:${NC}       source $VENV_DIR/bin/activate"
echo -e "  ${CYAN}Edit credentials:${NC}   $ENV_FILE"
echo ""
echo "  Add the MCP server config to your agent:"
echo ""
echo "  OpenCode:  cp $INSTALL_DIR/configs/opencode.json.example <project>/.opencode/opencode.json"
echo "  Claude:    cp $INSTALL_DIR/configs/claude.json.example <project>/.claude/settings.json"
echo "  Codex CLI: cp $INSTALL_DIR/configs/codex.json.example <project>/.codex/settings.json"
echo "  Cursor:    cp $INSTALL_DIR/configs/cursor.json.example <project>/.cursor/mcp.json"
echo ""
echo "  Make sure the path to vision_inventory_mcp.py and .env are correct in the config."
echo ""
echo -e "${CYAN}=== Done ===${NC}"
