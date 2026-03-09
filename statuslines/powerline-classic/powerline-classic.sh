#!/bin/zsh
# Powerline Classic — Claude Code statusline
# Agnoster-style solid segments with powerline arrow separators
# Aesthetic: dark charcoal blocks flowing left-to-right
#
# Requires: jq, bc, git
# Requires Nerd Fonts for powerline arrows ()
#
# Install:
#   cp powerline-classic.sh ~/.claude/statusline.sh
#   chmod +x ~/.claude/statusline.sh
# Add to ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }

INPUT=$(cat)

# Powerline characters (Nerd Fonts Private Use Area)
PL_R=$'\ue0b0'    # ► filled right arrow
PL_THIN=$'\ue0b1' # ⟩ thin right arrow

RST=$'\033[0m'

# 256-color helpers
_fg() { printf '\033[38;5;%sm' "$1"; }
_bg() { printf '\033[48;5;%sm' "$1"; }
_bold=$'\033[1m'

# Draw segment transition: arrow in (old_bg → new_bg)
_trans() { printf '%s%s%s' "$(_fg $1)" "$(_bg $2)" "$PL_R"; }
# End last segment: arrow onto transparent bg
_end() { printf '%s%s%s%s' "${RST}" "$(_fg $1)" "$PL_R" "$RST"; }

# ── Parse input ────────────────────────────────────────────────────────────────
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
USED=${USED%%.*}      # truncate to integer
USED=${USED:-0}

MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"' 2>/dev/null)
# Shorten: "Claude 3.5 Sonnet" → "3.5 Sonnet"
MODEL=${MODEL#Claude }

SESSION_COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null)
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0' 2>/dev/null)
LINES_DEL=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)

# ── Duration ───────────────────────────────────────────────────────────────────
DURATION_S=$(( DURATION_MS / 1000 ))
if (( DURATION_S >= 3600 )); then
  DUR="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif (( DURATION_S >= 60 )); then
  DUR="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DUR="${DURATION_S}s"
fi

# ── Cost ───────────────────────────────────────────────────────────────────────
COST_FMT=$(printf "%.3f" "${SESSION_COST:-0}")

# ── Git ────────────────────────────────────────────────────────────────────────
GIT_BRANCH="" STAGED=0 MODIFIED=0
if [[ -n "$CWD" ]]; then
  GIT_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$GIT_BRANCH" ]]; then
    GIT_STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null)
    STAGED=$(echo "$GIT_STATUS" | grep -c "^[MADRC]" 2>/dev/null || echo 0)
    MODIFIED=$(echo "$GIT_STATUS" | grep -c "^.[MD]" 2>/dev/null || echo 0)
  fi
fi

# ── Context bar (8 blocks) ─────────────────────────────────────────────────────
FILLED=$(( USED / 13 ))   # 0–8 blocks for 0–100%
(( FILLED > 8 )) && FILLED=8
CTX_BAR=""
for i in 1 2 3 4 5 6 7 8; do
  if (( i <= FILLED )); then CTX_BAR="${CTX_BAR}█"; else CTX_BAR="${CTX_BAR}░"; fi
done

# ── Color palette ──────────────────────────────────────────────────────────────
# Segment 1 — Model: dark charcoal bg, light text
C_MOD_BG=237; C_MOD_FG=253

# Segment 2 — Git: slightly lighter, gold text
C_GIT_BG=240; C_GIT_FG=214

# Segment 3 — Context: color-coded by usage
if (( USED >= 90 )); then
  C_CTX_BG=88; C_CTX_FG=196   # red
elif (( USED >= 70 )); then
  C_CTX_BG=130; C_CTX_FG=220  # orange
else
  C_CTX_BG=22; C_CTX_FG=82    # green
fi

# Segment 4 — Cost+time: darkest bg
C_COST_BG=235; C_COST_FG=154

# ── Assemble segments ──────────────────────────────────────────────────────────
printf '%s%s%s%s' \
  "$(_bg $C_MOD_BG)" "$(_fg $C_MOD_FG)" "$_bold" " ◆ ${MODEL} "

# Model → Git (or Model → Context)
if [[ -n "$GIT_BRANCH" ]]; then
  printf '%s' "$(_trans $C_MOD_BG $C_GIT_BG)"
  printf '%s' "$(_fg $C_GIT_FG)  ${GIT_BRANCH}"
  (( STAGED > 0 )) && printf '%s' " $(_fg 82)+${STAGED}$(_fg $C_GIT_FG)"
  (( MODIFIED > 0 )) && printf '%s' " $(_fg 220)~${MODIFIED}$(_fg $C_GIT_FG)"
  printf '%s' " $(_trans $C_GIT_BG $C_CTX_BG)"
else
  printf '%s' "$(_trans $C_MOD_BG $C_CTX_BG)"
fi

# Context segment
printf '%s' "$(_fg $C_CTX_FG) ${CTX_BAR} ${USED}%% $(_trans $C_CTX_BG $C_COST_BG)"

# Cost + duration segment
printf '%s' "$(_fg $C_COST_FG) \$${COST_FMT}"
printf '%s' " $(_fg 242)${DUR}"

# Lines changed (inline, no extra segment)
if (( LINES_ADD > 0 || LINES_DEL > 0 )); then
  printf '%s' " $(_fg 240)[$(_fg 34)+${LINES_ADD}$(_fg 240)/$(_fg 160)-${LINES_DEL}$(_fg 240)]"
fi
printf '%s' " "

# Closing arrow
printf '%s\n' "$(_end $C_COST_BG)"
