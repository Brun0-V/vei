# Vision Electronic Indexing (VEI)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Agent-assisted electronics/PCB photo indexing that works with **any MCP-capable coding agent harness** — OpenCode, Claude Code, Codex CLI, Cursor, and more. Also available as a [Pi](https://pi.dev) package.

Processes images with Cloudflare Workers AI, extracts visible IC/package markings, prepares parts for datasheet lookup, and produces an enriched inventory CSV.

```
photos/                          output/
  image_001.jpeg    ----->         raw/                  # one JSON result per image
  image_002.jpeg     vision        parts_to_lookup.json   # parts needing datasheet lookup
  image_003.jpeg                   datasheet_cache.json   # agent/user-filled enrichment
                                   inventory.csv          # deduplicated final BOM
                                   inventory_evidence.csv # per-image evidence rows
```

The vision step does **not** perform datasheet lookup or invent part details. Datasheet enrichment is handled by your agent with web-search capability.

## Install

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/Brun0-V/vei/main/scripts/quick-install.sh -o /tmp/vei-install.sh && bash /tmp/vei-install.sh
```

This installs to `~/.vei/`, sets up a Python venv, prompts for Cloudflare credentials, and optionally installs the agent skill. **Requires an MCP-capable agent** (OpenCode, Claude Code, Codex CLI, Cursor, etc.).

For Pi users: `pi install npm:vision-electronic-indexing-pi` uses the [original Pi package](https://pi.dev/packages/vision-electronic-indexing-pi).

Or clone manually:

```bash
git clone https://github.com/Brun0-V/vei.git
cd vision-electronic-indexing
python3 -m pip install -r requirements.txt
cp .env.example .env  # then edit with your credentials
```

## Quick Start

### 1. Install Python dependencies

```bash
python3 -m pip install -r requirements.txt
# Optional for iPhone HEIC photos:
# python3 -m pip install pillow-heif
```

### 2. Configure Cloudflare credentials

Copy `.env.example` to `.env` and add your [Cloudflare Workers AI](https://developers.cloudflare.com/workers-ai/) credentials:

```bash
cp .env.example .env
# Edit .env:
#   CLOUDFLARE_ACCOUNT_ID=your_account_id
#   CLOUDFLARE_AUTH_TOKEN=your_workers_ai_token
```

Find these at **https://dash.cloudflare.com/** → **AI** → **Workers AI** → **Use REST API** (Account ID and API Token are shown there).

The MCP server also accepts these as environment variables in your agent's MCP config.

### 3. Configure your agent

The core is a standard [MCP](https://modelcontextprotocol.io) stdio server (`vision_inventory_mcp.py`) that exposes three tools:
- `process_image` — analyze a single image
- `process_image_folder` — batch-analyze a folder
- `save_inventory` — save results as JSON or CSV

Pick your harness below:

<details>
<summary><b>OpenCode</b></summary>

Add to your project's `.opencode/opencode.json`:

```json
{
  "mcpServers": {
    "vision-inventory": {
      "command": "python3",
      "args": ["/path/to/VEI/vision_inventory_mcp.py"],
      "env": {
        "CLOUDFLARE_ACCOUNT_ID": "your_account_id",
        "CLOUDFLARE_AUTH_TOKEN": "your_token"
      }
    }
  }
}
```

Then load the skill from `skills/vision-inventory-workflow/SKILL.md` — place it in `.opencode/skills/` or `~/.config/opencode/skills/`.
</details>

<details>
<summary><b>Claude Code</b></summary>

Add to `~/.claude/settings.json` or `.claude/settings.json`:

```json
{
  "mcpServers": {
    "vision-inventory": {
      "command": "python3",
      "args": ["/path/to/VEI/vision_inventory_mcp.py"],
      "env": {
        "CLOUDFLARE_ACCOUNT_ID": "your_account_id",
        "CLOUDFLARE_AUTH_TOKEN": "your_token"
      }
    }
  }
}
```

Place the skill in `.claude/skills/vision-inventory-workflow/SKILL.md`.
</details>

<details>
<summary><b>Codex CLI</b></summary>

Add to `~/.codex/settings.json` or `.codex/settings.json`:

```json
{
  "mcpServers": {
    "vision-inventory": {
      "command": "python3",
      "args": ["/path/to/VEI/vision_inventory_mcp.py"],
      "env": {
        "CLOUDFLARE_ACCOUNT_ID": "your_account_id",
        "CLOUDFLARE_AUTH_TOKEN": "your_token"
      }
    }
  }
}
```

Place the skill in `.agents/skills/vision-inventory-workflow/SKILL.md`.
</details>

<details>
<summary><b>Cursor</b></summary>

Add to `.cursor/mcp.json` or configure through Cursor's MCP settings UI:

```json
{
  "mcpServers": {
    "vision-inventory": {
      "command": "python3",
      "args": ["/path/to/VEI/vision_inventory_mcp.py"],
      "env": {
        "CLOUDFLARE_ACCOUNT_ID": "your_account_id",
        "CLOUDFLARE_AUTH_TOKEN": "your_token"
      }
    }
  }
}
```
</details>

<details>
<summary><b>Any MCP-compatible client</b></summary>

```bash
python3 /path/to/VEI/vision_inventory_mcp.py
```

Configure as a stdio MCP server in your client's MCP settings with the same shape.
</details>

## Workflow

### Manual (no agent needed)

```bash
# Process images to raw JSON + parts_to_lookup.json
python3 scripts/inventory_folder_to_csv.py ./photos ./output

# Fill datasheet_cache.json manually or with an agent
# (edit ./output/datasheet_cache.json using ./output/datasheet_cache.template.json as template)

# Regenerate CSV without reprocessing images
python3 scripts/inventory_folder_to_csv.py ./photos ./output --skip-vision
```

### Agent-assisted (OpenCode, Claude Code, Codex CLI, etc.)

1. Load the `vision-inventory-workflow` skill (the agent will see it in available skills).
2. Say: "Run the Vision Electronic Indexing workflow on ./photos, output to ./output"
3. The agent will:
   - Run the deterministic vision pipeline via the MCP server
   - Read `parts_to_lookup.json`
   - Web-search each part for datasheets
   - Fill `datasheet_cache.json`
   - Regenerate the CSV
   - Summarize the BOM with uncertainties

## Output Files

| File | Description |
|---|---|
| `output/raw/*.json` | One raw vision result per image, for auditability |
| `output/parts_to_lookup.json` | Parts needing datasheet enrichment |
| `output/datasheet_cache.template.json` | Template to fill for enrichment |
| `output/datasheet_cache.json` | Agent/user-filled enrichment cache |
| `output/inventory.csv` | Deduplicated final BOM |
| `output/inventory_evidence.csv` | Per-image, per-candidate evidence rows |

## Credits

Forked from [Pichi-Cell/vision-electronic-indexing](https://github.com/Pichi-Cell/vision-electronic-indexing) — ported from Pi agent to a harness-agnostic format with MCP configs and Agent Skills for OpenCode, Claude Code, Codex CLI, and Cursor.

## License

MIT
