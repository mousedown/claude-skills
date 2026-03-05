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
```ansi
[36mjsmith[0m [34mPRO[0m [37m@Acme[0m  [32m[Opus] ▓▓▓▓░░░░░░ 42%[0m  [35m$1.247[0m [90m($185.230 total)[0m  [90m15m24s[0m [32m+186[0m [31m-43[0m  [36m feature/auth-flow[0m
```

**Cool Tones** — blues, purples, gold accents
```ansi
[1;34mjsmith[0m [38;5;69mPRO[0m [37m@Acme[0m  [38;5;69mOpus ████░░░░░░ 42%[0m  [38;5;183m$1.247[0m [38;5;105m($189.693)[0m  [38;5;105m15m24s[0m [38;5;114m+186[0m [38;5;174m-43[0m [38;5;73m feature/auth-flow[0m
```

**Minimal Mono** — muted tones, color only for alerts
```ansi
[1;37mjsmith[0m [90mPRO[0m [37m@Acme[0m [90m|[0m [90mOpus ▓▓▓▓░░░░░░ 42%[0m [90m|[0m [90m$1.247 ($189.693)[0m [90m|[0m [90m15m24s[0m [32m+186[0m [31m-43[0m [90m feature/auth-flow[0m
```

**Neon Terminal** — high contrast, retro hacker aesthetic
```ansi
[1;38;5;46mjsmith[0m [1;38;5;51mPRO[0m [37m@Acme[0m  [38;5;103mOpus ████▁▁▁▁▁▁ 42%[0m  [1;38;5;208m$1.247[0m [38;5;240m($189.693)[0m  [38;5;240m15m24s[0m [1;38;5;46m+186[0m [1;38;5;196m-43[0m [1;38;5;51m feature/auth-flow[0m
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

```ansi
[33m⬆ /gsd:update[0m │ [2mSonnet[0m │ [2mmy-app[0m [32m█████░░░░░ 53%[0m
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
