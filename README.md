# Claude Skills

A collection of statuslines, slash commands, sub-agents and other useful skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

---

## Statuslines

### Cost Tracker Statusline

A rich statusline with cumulative cost tracking, git info, context usage, and 4 swappable themes.

**Features:**
- User identity with org name and subscription badge
- Context window progress bar with color-coded warnings
- Session cost + cumulative cost tracking across sessions
- Session duration
- Lines added/removed
- Git branch with staged/modified file counts
- 200k+ token warning

**Requirements:** `jq`, `bc`, `git`

#### Themes

**Default** — clean, familiar colors
```
chrisanthony team @tribes.agency  [Opus] ▓▓▓▓░░░░░░ 42%  $1.247 ($8.530 total)  15m24s +186 -43   feature/my-branch
```

**Cool Tones** — blues, purples, gold accents
```
chrisanthony TEAM @tribes.agency  Opus ████░░░░░░ 42%  $1.247 ($8.530)  15m24s +186 -43  feature/my-branch
```

**Minimal Mono** — muted tones, color only for alerts
```
chrisanthony TEAM @tribes.agency | Opus ▓▓▓▓░░░░░░ 42% | $1.247 ($8.530) | 15m24s +186 -43  feature/my-branch
```

**Neon Terminal** — high contrast, retro hacker aesthetic
```
chrisanthony TEAM @tribes.agency  Opus ████▁▁▁▁▁▁ 42%  $1.247 ($8.530)  15m24s +186 -43  feature/my-branch
```

#### Install

1. Clone this repo:
   ```sh
   git clone https://github.com/mousedown/claude-skills.git
   cd claude-skills
   ```

2. Run the theme switcher (picks a theme and installs the core):
   ```sh
   ./statuslines/cost-tracker-statusline/switch-theme.sh default
   ```
   Options: `default`, `cool`, `minimal`, `neon`

3. Add to your Claude Code settings (`~/.claude/settings.json`):
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline.sh"
     }
   }
   ```

4. Restart Claude Code or start a new session.

#### Switch Themes

```sh
./statuslines/cost-tracker-statusline/switch-theme.sh neon
```

---

### GSD Statusline

A focused statusline for the [GSD workflow](https://github.com/get-shit-done-ai/gsd-claude-code). Shows the current task, working directory, and context usage scaled to the 80% limit Claude Code enforces.

**Features:**
- Model name display
- Current GSD task (from todos)
- Working directory name
- Context window usage bar (scaled to 80% limit)
- Color-coded: green → yellow → orange → red/blinking
- GSD update notification

```
⬆ /gsd:update │ Sonnet │ my-app █████░░░░░ 53%
```

#### Install

1. Copy the script:
   ```sh
   cp statuslines/gsd-statusline/gsd-statusline.js ~/.claude/hooks/gsd-statusline.js
   ```

2. Add to your Claude Code settings (`~/.claude/settings.json`):
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "node \"~/.claude/hooks/gsd-statusline.js\""
     }
   }
   ```

3. Restart Claude Code or start a new session.

**Requirements:** Node.js
