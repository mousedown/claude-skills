# Claude Skills

A collection of statuslines, slash commands, sub-agents and other useful skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

---

## Statuslines

26 self-contained statuslines for every taste — minimalist to powerline, plain text to emoji, financial to git-focused.

**Quick install pattern** — copy a statusline file and register it in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

## Visual Gallery

<table>
<tr>
<td align="center" width="33%">

### [minimal](#minimal-statusline)
*Monochrome, dim separators*
<a href="#minimal-statusline"><img src="assets/screenshots/minimal-statusline.svg" alt="minimal statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [compact](#compact-statusline)
*Three fields, zero noise*
<a href="#compact-statusline"><img src="assets/screenshots/compact-statusline.svg" alt="compact statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [plain](#plain-statusline)
*Zero ANSI, pipe-friendly*
<a href="#plain-statusline"><img src="assets/screenshots/plain-statusline.svg" alt="plain statusline preview" width="100%"></a>

</td>
</tr>
<tr>
<td align="center" width="33%">

### [emoji](#emoji-statusline)
*Emoji icon per field*
<a href="#emoji-statusline"><img src="assets/screenshots/emoji-statusline.svg" alt="emoji statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [zen](#zen-statusline)
*Nature emoji, water bar*
<a href="#zen-statusline"><img src="assets/screenshots/zen-statusline.svg" alt="zen statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [neon-tokyo](#neon-tokyo)
*Cyberpunk, diamond separators*
<a href="#neon-tokyo"><img src="assets/screenshots/neon-tokyo.svg" alt="neon-tokyo statusline preview" width="100%"></a>

</td>
</tr>
<tr>
<td align="center" width="33%">

### [retro-terminal](#retro-terminal)
*80s BBS bracket notation*
<a href="#retro-terminal"><img src="assets/screenshots/retro-terminal.svg" alt="retro-terminal statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [hacker-matrix](#hacker-matrix)
*Phosphor-green, :: separators*
<a href="#hacker-matrix"><img src="assets/screenshots/hacker-matrix.svg" alt="hacker-matrix statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [scoreboard](#scoreboard)
*Sports scoreboard, heart bar*
<a href="#scoreboard"><img src="assets/screenshots/scoreboard.svg" alt="scoreboard statusline preview" width="100%"></a>

</td>
</tr>
<tr>
<td align="center" width="33%">

### [time-machine](#time-machine)
*Wall-clock + per-minute rates*
<a href="#time-machine"><img src="assets/screenshots/time-machine.svg" alt="time-machine statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [budget-tracker](#budget-tracker)
*Financial dashboard, burn rate*
<a href="#budget-tracker"><img src="assets/screenshots/budget-tracker.svg" alt="budget-tracker statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [git-dashboard](#git-dashboard)
*Git status front and center*
<a href="#git-dashboard"><img src="assets/screenshots/git-dashboard.svg" alt="git-dashboard statusline preview" width="100%"></a>

</td>
</tr>
<tr>
<td align="center" width="33%">

### [tokens-focus](#tokens-focus)
*Raw token counts primary*
<a href="#tokens-focus"><img src="assets/screenshots/tokens-focus.svg" alt="tokens-focus statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [powerline-arrows](#powerline-arrows)
*Starship-style ❯ separators*
<a href="#powerline-arrows"><img src="assets/screenshots/powerline-arrows.svg" alt="powerline-arrows statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [powerline-classic](#powerline-classic)
*Agnoster segment train*
<a href="#powerline-classic"><img src="assets/screenshots/powerline-classic.svg" alt="powerline-classic statusline preview" width="100%"></a>

</td>
</tr>
<tr>
<td align="center" width="33%">

### [powerline-neon](#powerline-neon)
*Neon cyberpunk segments*
<a href="#powerline-neon"><img src="assets/screenshots/powerline-neon.svg" alt="powerline-neon statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [powerline-gruvbox](#powerline-gruvbox)
*Warm earth-tone floating pills*
<a href="#powerline-gruvbox"><img src="assets/screenshots/powerline-gruvbox.svg" alt="powerline-gruvbox statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [powerline-nord](#powerline-nord)
*Arctic palette, two-line layout*
<a href="#powerline-nord"><img src="assets/screenshots/powerline-nord.svg" alt="powerline-nord statusline preview" width="100%"></a>

</td>
</tr>
<tr>
<td align="center" width="33%">

### [powerline-catppuccin](#powerline-catppuccin)
*Soft-pastel diamond pills*
<a href="#powerline-catppuccin"><img src="assets/screenshots/powerline-catppuccin.svg" alt="powerline-catppuccin statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [cost-tracker](#cost-tracker-statusline)
*Full dashboard, 4 themes*
<a href="#cost-tracker-statusline"><img src="assets/screenshots/cost-tracker-statusline.svg" alt="cost-tracker statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [gsd](#gsd-statusline)
*GSD workflow integration*
<a href="#gsd-statusline"><img src="assets/screenshots/gsd-statusline.svg" alt="gsd statusline preview" width="100%"></a>

</td>
</tr>
<tr>
<td align="center" width="33%">

### [centered](#centered)
*All content centered*
<a href="#centered"><img src="assets/screenshots/centered.svg" alt="centered statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [lcars](#lcars)
*Star Trek LCARS panels*
<a href="#lcars"><img src="assets/screenshots/lcars.svg" alt="lcars statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [solarized](#solarized)
*Solarized Dark, ▸ bullets*
<a href="#solarized"><img src="assets/screenshots/solarized.svg" alt="solarized statusline preview" width="100%"></a>

</td>
</tr>
<tr>
<td align="center" width="33%">

### [split-view](#split-view)
*Left git — right cost/time*
<a href="#split-view"><img src="assets/screenshots/split-view.svg" alt="split-view statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">

### [two-line](#two-line)
*Two-row layout, git below*
<a href="#two-line"><img src="assets/screenshots/two-line.svg" alt="two-line statusline preview" width="100%"></a>

</td>
<td align="center" width="33%">
</td>
</tr>
</table>

---

## Quick Reference

| Name | Language | Style | Key data |
|------|----------|-------|----------|
| [minimal](#minimal-statusline) | bash | Dim text, separators only | model · ctx% · cost · time · branch |
| [compact](#compact-statusline) | bash | Ultra-compact, 3 fields | ctx% · cost · branch |
| [plain](#plain-statusline) | bash | Zero ANSI, pipe-friendly | model \| ctx% \| cost \| time \| branch |
| [emoji](#emoji-statusline) | bash | Emoji icons per field | 🤖 model 📊 bar 💵 cost ⏱ time ✏️ lines 🌿 branch |
| [zen](#zen-statusline) | bash | Nature emoji, soft tones | mood · model · water-bar · cost · time · branch |
| [neon-tokyo](#neon-tokyo) | node | Cyberpunk, bright neon | SONNET ◈ ▮ bar ◈ ¥cost ◈ time ◈ lines ◈ branch |
| [retro-terminal](#retro-terminal) | bash | Phosphor-green bracket notation | > [MODEL] [CTX:bar] [$cost] [time] |
| [time-machine](#time-machine) | bash | Wall-clock + per-minute rates | ◷ HH:MM · model · bar · $/min · ln/min · branch |
| [hacker-matrix](#hacker-matrix) | bash | Phosphor-green monochrome | // claude.model :: [ctx] :: cost[] :: t[] |
| [scoreboard](#scoreboard) | bash | Sports scoreboard aesthetic | TEAM ❤❤❤ CTX: COST: TIME: LINES: |
| [powerline-arrows](#powerline-arrows) | bash | Starship-style ❯ separators | model ❯ bar ❯ $cost ❯ time ❯ lines ❯ branch |
| [budget-tracker](#budget-tracker) | python | Financial dashboard | 💰 model · cost · $/hr · ctx% · branch |
| [git-dashboard](#git-dashboard) | bash | Git info front-and-center | branch ✚staged ✎modified ?untracked ↑↓ \| model ctx% cost |
| [tokens-focus](#tokens-focus) | node | Actual token counts | model · 83k/200k ctx · % · lines · cost · time · branch |
| [powerline-classic](#powerline-classic) | zsh | Agnoster segment train (Nerd Fonts) | ◆ model ► git ► ctx-bar ► cost/time |
| [powerline-neon](#powerline-neon) | python | Neon segment train (Nerd Fonts) | pink model ► cyan ctx ► lime cost ► violet git |
| [powerline-gruvbox](#powerline-gruvbox) | zsh | Gruvbox floating pills (Nerd Fonts) | ◈model · git · ctx-bar · cost · time |
| [powerline-nord](#powerline-nord) | node | Nord two-line layout (Nerd Fonts) | line1: model/ctx/cost · line2: git/time/lines |
| [powerline-catppuccin](#powerline-catppuccin) | python | Catppuccin Mocha pills (Nerd Fonts) | ✦model · teal-bar · ◈cost · git · time |
| [cost-tracker](#cost-tracker-statusline) | zsh | Full dashboard, 4 themes | user · plan · org · model · bar · cost · total · time · lines · branch |
| [gsd](#gsd-statusline) | node | GSD workflow integration | update-notice · model · dir · ctx-bar |
| [centered](#centered) | bash | Centered in terminal width | ··· ◆ model · bar · cost · time · branch ··· |
| [lcars](#lcars) | bash | Star Trek LCARS panels | ▐ UNIT ▌ bar │ COST │ TIME │ branch |
| [solarized](#solarized) | bash | Solarized Dark palette | model ▸ bar ▸ cost ▸ time ▸ lines ▸ branch |
| [split-view](#split-view) | node | Left git/ctx — right cost/model/time | branch ✚ bar ────── cost │ model │ time |
| [two-line](#two-line) | bash | Two-row layout | line1: model/bar/cost/time · line2: git/lines |

---

### minimal-statusline

Monochrome with dim separators. Color only for context alerts.

![preview](assets/screenshots/minimal-statusline.svg)

```
Sonnet 4.5 │ 42% │ $0.324 │ 8m12s │ feature/auth-flow
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/minimal-statusline/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### compact-statusline

Ultra-compact — only 3 fields. For developers who find statuslines distracting.

![preview](assets/screenshots/compact-statusline.svg)

```
42% · $0.32 · feature/auth-flow
```

**Requirements:** `jq`, `git`

**Install:**
```sh
cp statuslines/compact-statusline/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### plain-statusline

Zero ANSI codes. Pipe-friendly, works in log files and non-color terminals.

![preview](assets/screenshots/plain-statusline.svg)

```
Sonnet 4.5 | 42% | $0.324 | 8m12s | feature/auth-flow
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/plain-statusline/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### emoji-statusline

Fun, expressive emoji dashboard. Each field has its own emoji icon.

![preview](assets/screenshots/emoji-statusline.svg)

```
🤖 Sonnet 4.5  📗 ████░░░░░░ 42%  💵 $0.324  ⏱ 8m12s  ✏️ +186 -43  🌿 feature/auth-flow
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/emoji-statusline/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### zen-statusline

Nature/zen theme. Context shown as a water-level bar using `〰` and `·` characters.

![preview](assets/screenshots/zen-statusline.svg)

```
🌿  Claude Sonnet 4.5  〰〰〰〰······  42%  🌰 $0.324  ⏳ 8m  🌊 feature/auth-flow
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/zen-statusline/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### neon-tokyo

Cyberpunk aesthetic. Bright neon with `◈` diamond separators and `▮▯` block bar. Cost shown as `¥` for aesthetic.

![preview](assets/screenshots/neon-tokyo.svg)

```
SONNET ◈ ▮▮▮▮▯▯▯▯▯▯ 42% ◈ ¥0.324 ◈ 8m12s ◈ +186 -43 ◈ ⌥ feature/auth-flow
```

**Requirements:** Node.js, `git`

**Install:**
```sh
cp statuslines/neon-tokyo/statusline.js ~/.claude/statusline.js
chmod +x ~/.claude/statusline.js
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/statusline.js"
  }
}
```

---

### retro-terminal

80s BBS/DOS aesthetic. Everything in `[BRACKETS]`, phosphor-green, uppercase identifiers.

![preview](assets/screenshots/retro-terminal.svg)

```
> [CLAUDE SONNET 4.5] [CTX:████░░░░░░ 42%] [$0.324] [8m12s] [FEATURE/AUTH-FLOW]
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/retro-terminal/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### time-machine

Timestamp-centric. Shows wall-clock time and computed per-minute rates — ideal for long sessions.

![preview](assets/screenshots/time-machine.svg)

```
◷ 14:23  Sonnet 4.5  ▓▓▓▓░░░░░░ 42%  8m12s  $0.040/min  +23 ln/min  feature/auth-flow
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/time-machine/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### hacker-matrix

Classic phosphor-green terminal. `::` separators, bracket notation, monochrome throughout.

![preview](assets/screenshots/hacker-matrix.svg)

```
// claude.sonnet :: [ctx:42%] :: cost[$0.3240] :: t[8m12s] :: +186/-43 :: ref[feature/auth-flow]
```

**Requirements:** `bash`, `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/hacker-matrix/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### scoreboard

Sports scoreboard aesthetic. Context remaining shown as hearts, lines as a score.

![preview](assets/screenshots/scoreboard.svg)

```
SONNET  ❤❤❤❤❤❤♡♡♡♡  CTX: 42%  COST: $0.324  TIME: 8m12s  LINES: 229  FIELD: feature/auth-flow
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/scoreboard/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### powerline-arrows

Starship/Powerline-inspired with `❯` prompt-style separators. Shows staged/modified git dots.

![preview](assets/screenshots/powerline-arrows.svg)

```
Sonnet 4.5 ❯ ━━━━──────  42% ❯ $0.324 ❯ 8m12s ❯ +186 -43 ❯  feature/auth-flow ●3
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/powerline-arrows/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### budget-tracker

Financial dashboard. Shows hourly burn rate and switches icon as spend rate increases.

![preview](assets/screenshots/budget-tracker.svg)

```
💰 Sonnet 4.5  $0.324  ~$2.371/hr  42%  feature/auth-flow
```

**Requirements:** Python 3, `git`

**Install:**
```sh
cp statuslines/budget-tracker/statusline.py ~/.claude/statusline.py
chmod +x ~/.claude/statusline.py
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/statusline.py"
  }
}
```

---

### git-dashboard

Git info front and center. Shows staged, modified, untracked counts plus ahead/behind. Session data moves to secondary.

![preview](assets/screenshots/git-dashboard.svg)

```
 feature/auth-flow  ✚3  ✎2  ?1  ↑2  │  Sonnet 4.5  42%  $0.324
```

**Requirements:** `jq`, `git`

**Install:**
```sh
cp statuslines/git-dashboard/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### tokens-focus

Makes actual token counts the primary focus. Shows `83k/200k ctx` when derivable, falls back to percentages.

![preview](assets/screenshots/tokens-focus.svg)

```
Sonnet-4.5  83k/200k ctx  42%  +186 -43  $0.3240  8m12s   feature/auth-flow
```

**Requirements:** Node.js, `git`

**Install:**
```sh
cp statuslines/tokens-focus/statusline.js ~/.claude/statusline.js
chmod +x ~/.claude/statusline.js
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/statusline.js"
  }
}
```

---

### powerline-classic

Agnoster-style solid segment train with filled powerline arrows `►`. Requires [Nerd Fonts](https://www.nerdfonts.com/).

![preview](assets/screenshots/powerline-classic.svg)

```
 ◆ Sonnet 4.5 ►  feature/auth-flow ► ████░░░░ 42% ► $0.324  8m12s ►
```

**Requirements:** `jq`, `bc`, `git`

**Font dependency:** Requires a [Nerd Font](https://www.nerdfonts.com/font-downloads) in your terminal emulator (recommended: `JetBrainsMono Nerd Font` or `MesloLGS NF`). Without one, powerline arrows will display as broken characters.

**Install:**
```sh
cp statuslines/powerline-classic/powerline-classic.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### powerline-neon

Neon cyberpunk segment train. Hot pink → electric cyan → neon lime → deep violet segments. Requires [Nerd Fonts](https://www.nerdfonts.com/).

![preview](assets/screenshots/powerline-neon.svg)

```
 ✦ Sonnet 4.5 ► ████ 42% ► $0.324 ►  feature/auth-flow +3 ► 8m12s +186 -43 ►
```

**Requirements:** Python 3, `git`

**Font dependency:** Requires a [Nerd Font](https://www.nerdfonts.com/font-downloads) in your terminal emulator (recommended: `JetBrainsMono Nerd Font` or `MesloLGS NF`). Without one, powerline arrows will display as broken characters.

**Install:**
```sh
cp statuslines/powerline-neon/powerline-neon.py ~/.claude/statusline.py
chmod +x ~/.claude/statusline.py
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/statusline.py"
  }
}
```

---

### powerline-gruvbox

Warm earth-tone floating pills. Retro-cozy Gruvbox dark palette. Requires [Nerd Fonts](https://www.nerdfonts.com/).

![preview](assets/screenshots/powerline-gruvbox.svg)

```
❨ ◈ Sonnet 4.5 ❩  ❨  feature/auth-flow ❩  ❨ ▓▓▓▓░░░░ 42% ❩  ❨ $0.324 ❩  ❨ 8m12s ❩
```

**Requirements:** `jq`, `bc`, `git`

**Font dependency:** Requires a [Nerd Font](https://www.nerdfonts.com/font-downloads) in your terminal emulator (recommended: `JetBrainsMono Nerd Font` or `MesloLGS NF`). Without one, powerline arrows will display as broken characters.

**Install:**
```sh
cp statuslines/powerline-gruvbox/powerline-gruvbox.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### powerline-nord

Arctic Nord palette in a two-line layout. Line 1: model/context/cost. Line 2: git/duration/lines. Requires [Nerd Fonts](https://www.nerdfonts.com/).

![preview](assets/screenshots/powerline-nord.svg)

```
 ❄ Sonnet 4.5 ► ▓▓▓▓░░░░░░ 42% ► $0.324 ►
  feature/auth-flow +3 ► 8m12s ► +186 -43 ►
```

**Requirements:** Node.js, `git`

**Font dependency:** Requires a [Nerd Font](https://www.nerdfonts.com/font-downloads) in your terminal emulator (recommended: `JetBrainsMono Nerd Font` or `MesloLGS NF`). Without one, powerline arrows will display as broken characters.

**Install:**
```sh
cp statuslines/powerline-nord/powerline-nord.js ~/.claude/statusline.js
chmod +x ~/.claude/statusline.js
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/statusline.js"
  }
}
```

---

### powerline-catppuccin

Catppuccin Mocha soft-pastel floating diamond pills. Reads `~/.claude/auth_cache.json` for plan badge. Requires [Nerd Fonts](https://www.nerdfonts.com/).

![preview](assets/screenshots/powerline-catppuccin.svg)

```
❨ ✦ Sonnet 4.5 ❩  ❨ ████░░░░ 42% ❩  ❨ ◈ $0.324 ❩  ❨  feature/auth-flow ❩  ❨ 8m12s ❩
```

**Requirements:** Python 3, `git`

**Font dependency:** Requires a [Nerd Font](https://www.nerdfonts.com/font-downloads) in your terminal emulator (recommended: `JetBrainsMono Nerd Font` or `MesloLGS NF`). Without one, powerline arrows will display as broken characters.

**Install:**
```sh
cp statuslines/powerline-catppuccin/powerline-catppuccin.py ~/.claude/statusline.py
chmod +x ~/.claude/statusline.py
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/statusline.py"
  }
}
```

---

### cost-tracker-statusline

Full-featured dashboard with cumulative cost tracking across sessions and 4 swappable themes.

![preview](assets/screenshots/cost-tracker-statusline.svg)

```
 jsmith PRO @Acme  [Opus] ▓▓▓▓░░░░░░ 42%  $1.247 ($8.530 total)  15m24s +186 -43   feature/auth-flow
```

**Features:**
- User identity with org name and subscription badge
- Context window progress bar
- Session cost + cumulative cost tracking across sessions
- Session duration, lines added/removed
- Git branch with staged/modified file counts

**Requirements:** `jq`, `bc`, `git`

#### Themes: `default` · `cool` · `minimal` · `neon`

**Install:**
```sh
# Clone the repo
git clone https://github.com/mousedown/claude-skills.git && cd claude-skills

# Run the theme switcher (installs and activates a theme)
./statuslines/cost-tracker-statusline/switch-theme.sh default
```

Then add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

**Switch themes later:**
```sh
./statuslines/cost-tracker-statusline/switch-theme.sh neon
```

---

### gsd-statusline

Focused statusline for the [GSD workflow](https://github.com/get-shit-done-ai/gsd-claude-code). Context bar scaled to the 80% limit Claude Code enforces.

![preview](assets/screenshots/gsd-statusline.svg)

```
 ⬆ /gsd:update │ Sonnet │ my-app █████░░░░░ 53%
```

**Features:**
- Model name display
- Current GSD task from todos
- Working directory name
- Context usage bar scaled to 80% limit
- GSD update notification

**Requirements:** Node.js

**Install:**
```sh
mkdir -p ~/.claude/hooks
cp statuslines/gsd-statusline/gsd-statusline.js ~/.claude/hooks/gsd-statusline.js
chmod +x ~/.claude/hooks/gsd-statusline.js
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/hooks/gsd-statusline.js"
  }
}
```

---

### centered

All content centered within the terminal width. Equal padding on both sides. Looks great on wide terminals.

![preview](assets/screenshots/centered.svg)

```
·············  ◆ Sonnet 4.5  ▓▓▓▓░░░░░░ 42%  $0.324  8m12s  ⎇ feature/auth-flow  ·············
```

**Requirements:** `jq`, `bc`, `tput`, `git`

**Install:**
```sh
cp statuslines/centered/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### lcars

Star Trek LCARS interface aesthetic. Orange bracket panels for identity, `▪▫` block bar, uppercase field labels.

![preview](assets/screenshots/lcars.svg)

```
▐ SONNET ▌  ▪▪▪▪▫▫▫▫▫▫ 42%  │ COST: $0.324 │ TIME: 8M12S │ +186/-43 │ FEATURE/AUTH-FLOW
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/lcars/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### solarized

Classic Solarized Dark palette. Uses `▸` bullet separators unique to this statusline.

![preview](assets/screenshots/solarized.svg)

```
Sonnet 4.5 ▸ ████░░░░░░ 42% ▸ $0.324 ▸ 8m12s ▸ +186 -43 ▸ feature/auth-flow
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/solarized/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

### split-view

Fills the terminal width. Git status and context on the left; cost, model, and time right-aligned.

![preview](assets/screenshots/split-view.svg)

```
 feature/auth-flow  ✚3  ████░░░░░░ 42%  ──────────────────  $0.324 │ Sonnet 4.5 │ 8m12s
```

**Requirements:** Node.js, `git`

**Install:**
```sh
cp statuslines/split-view/statusline.js ~/.claude/statusline.js
chmod +x ~/.claude/statusline.js
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/statusline.js"
  }
}
```

---

### two-line

Two-row layout. Session vitals on line 1; git state and line changes on line 2.

![preview](assets/screenshots/two-line.svg)

```
  ◆ Sonnet 4.5  ▓▓▓▓░░░░░░ 42%  $0.324  8m12s
  ⎇ feature/auth-flow  ✚2  ✎1  ↑1   |   +186 -43
```

**Requirements:** `jq`, `bc`, `git`

**Install:**
```sh
cp statuslines/two-line/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Add to `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

---

## Choosing a Statusline

| If you want… | Use |
|---|---|
| Least distraction | [compact](#compact-statusline) or [plain](#plain-statusline) |
| Clean but informative | [minimal](#minimal-statusline) |
| Actual token numbers | [tokens-focus](#tokens-focus) |
| Track spending closely | [budget-tracker](#budget-tracker) or [cost-tracker](#cost-tracker-statusline) |
| Git status at a glance | [git-dashboard](#git-dashboard) or [split-view](#split-view) |
| Fun / expressive | [emoji](#emoji-statusline) or [zen](#zen-statusline) |
| Retro / hacker feel | [hacker-matrix](#hacker-matrix) or [retro-terminal](#retro-terminal) |
| Sci-fi / themed | [lcars](#lcars) or [neon-tokyo](#neon-tokyo) |
| Neon / cyberpunk | [neon-tokyo](#neon-tokyo) or [powerline-neon](#powerline-neon) |
| Long session timing | [time-machine](#time-machine) |
| Wide terminal, centered | [centered](#centered) |
| Info density, no width | [two-line](#two-line) |
| Familiar color scheme | [solarized](#solarized) |
| Powerline (no Nerd Fonts) | [powerline-arrows](#powerline-arrows) |
| Powerline + Nerd Fonts | [powerline-classic](#powerline-classic), [powerline-gruvbox](#powerline-gruvbox), [powerline-nord](#powerline-nord), or [powerline-catppuccin](#powerline-catppuccin) |
| GSD workflow | [gsd](#gsd-statusline) |
