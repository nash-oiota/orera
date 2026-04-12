# Technical Environment: kiro-team

## Language

- **Bash** (primary implementation language)
- No Python dependency for MVP — shell scripts only
- macOS / Linux compatible

## Tools and Dependencies

| Tool | Version | Purpose |
|---|---|---|
| tmux | any recent | Session management |
| kiro-cli | latest | AI agent runtime |
| bash | 3.2+ | Script execution |

## Project Structure

```
kiro-team/
├── scripts/
│   ├── start.sh        # Launch all tmux sessions
│   ├── stop.sh         # Kill all sessions
│   └── status.sh       # Show session status
├── .kiro/
│   └── agents/
│       ├── pdm.json        # PdM agent definition
│       └── *.json          # Specialist agent definitions (configurable)
├── tasks/              # PdM writes task files here
├── results/            # Specialists write results here
└── README.md
```

## Architecture

- Each agent = one tmux session with kiro-cli running persistently
- Team composition = `.kiro/agents/*.json` files (add file → add team member)
- PdM delegates via `tmux send-keys -t <session> "<message>" Enter`
- Specialists write results to `results/<agent-name>.md`
- PdM polls `results/` to detect completion and report back to user
- PdM agent has `execute_bash` permission to run tmux commands autonomously

## Agent Configuration

Agents are defined as kiro-cli agent JSON files in `.kiro/agents/`. Each file must include:
- `name`: used as tmux session name
- `prompt`: role-specific system prompt
- `tools`: must include `execute_bash` for PdM, `fs_write` for specialists
- `allowedTools`: pre-approved tools to avoid permission prompts

## Do NOT Use

| Prohibited | Reason | Use Instead |
|---|---|---|
| Python for MVP | Adds dependency overhead | Bash |
| tmux named pipes | Complexity not needed for MVP | tmux send-keys |
| External message queues (Redis etc.) | Overkill for local personal tool | File-based communication |

## Security

- Local only, no network exposure
- No secrets or API keys in scripts or agent configs
- kiro-cli handles its own authentication

## Example Code Patterns

### start.sh pattern
```bash
#!/bin/bash
PROJECT="kiro-team"

# Create PdM session
tmux new-session -d -s "${PROJECT}:pdm" -x 220 -y 50
tmux send-keys -t "${PROJECT}:pdm" "kiro-cli chat --agent pdm" Enter

# Create specialist sessions from .kiro/agents/*.json (excluding pdm)
for agent_file in .kiro/agents/*.json; do
  name=$(basename "$agent_file" .json)
  [[ "$name" == "pdm" ]] && continue
  tmux new-window -t "${PROJECT}" -n "$name"
  tmux send-keys -t "${PROJECT}:${name}" "kiro-cli chat --agent ${name}" Enter
done

mkdir -p tasks results
tmux attach -t "${PROJECT}:pdm"
```

### PdM delegation pattern (executed by PdM via execute_bash)
```bash
# PdM sends task to specialist
tmux send-keys -t "kiro-team:frontend" "Please implement: <task description>" Enter
```

### Specialist result reporting pattern
```bash
# Specialist writes result to file
echo "<result>" > results/frontend.md
```
