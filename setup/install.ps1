# Vision Electronic Indexing Setup (PowerShell)
Write-Host "=== Vision Electronic Indexing Setup ===" -ForegroundColor Cyan
Write-Host ""

$VEI_DIR = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

# 1. Python dependencies
Write-Host "[1/3] Installing Python dependencies..."
python -m pip install -r (Join-Path $VEI_DIR "requirements.txt") --quiet
Write-Host "  Done."

# 2. Environment file
$ENV_FILE = Join-Path $VEI_DIR ".env"
if (-not (Test-Path $ENV_FILE)) {
    Write-Host "[2/3] Creating .env file from .env.example..."
    Copy-Item (Join-Path $VEI_DIR ".env.example") $ENV_FILE
    Write-Host "  Edit $ENV_FILE with your Cloudflare Workers AI credentials."
} else {
    Write-Host "[2/3] .env file already exists."
}

# 3. MCP config
Write-Host "[3/3] To configure your agent, copy the appropriate config from configs/:"
Write-Host ""
Write-Host "  OpenCode:  copy configs\opencode.json.example <project>\.opencode\opencode.json"
Write-Host "  Claude:    copy configs\claude.json.example <project>\.claude\settings.json"
Write-Host "  Codex CLI: copy configs\codex.json.example <project>\.codex\settings.json"
Write-Host "  Cursor:    copy configs\cursor.json.example <project>\.cursor\mcp.json"
Write-Host ""
Write-Host "Then edit the file to set the path to vision_inventory_mcp.py and your credentials."
Write-Host ""
Write-Host "=== Setup complete ===" -ForegroundColor Cyan
