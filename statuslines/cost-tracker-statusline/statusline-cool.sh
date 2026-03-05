#!/bin/zsh
# Theme: Cool Tones — blues, purples, gold accents
INPUT=$(cat)

# Context window
USED=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')

# Auth identity (cached, refreshes every hour)
AUTH_CACHE="$HOME/.claude/auth_cache.json"
AUTH_MAX_AGE=3600
AUTH_EMAIL=""
AUTH_PLAN=""

refresh_auth() {
  local result
  result=$(unset CLAUDECODE && claude auth status 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$result" ]; then
    echo "$result" | jq --arg ts "$(date +%s)" '. + {cached_at: ($ts | tonumber)}' > "$AUTH_CACHE" 2>/dev/null
  fi
}

if [ -f "$AUTH_CACHE" ]; then
  CACHED_AT=$(jq -r '.cached_at // 0' "$AUTH_CACHE" 2>/dev/null)
  NOW=$(date +%s)
  if [ $(( NOW - CACHED_AT )) -ge $AUTH_MAX_AGE ]; then
    refresh_auth
  fi
else
  refresh_auth
fi

if [ -f "$AUTH_CACHE" ]; then
  AUTH_EMAIL=$(jq -r '.email // ""' "$AUTH_CACHE" 2>/dev/null)
  AUTH_PLAN=$(jq -r '.subscriptionType // ""' "$AUTH_CACHE" 2>/dev/null)
fi

# --- THEME: Cool Tones ---
# 256-color codes: 69=cornflower blue, 220=gold, 183=lavender, 73=teal, 105=slate purple
USER_INFO=""
if [ -n "$AUTH_EMAIL" ]; then
  SHORT_USER=$(echo "$AUTH_EMAIL" | cut -d@ -f1)
  PLAN_BADGE=""
  case "$AUTH_PLAN" in
    max) PLAN_BADGE="\033[38;5;220mMAX\033[0m" ;;
    pro) PLAN_BADGE="\033[38;5;69mPRO\033[0m" ;;
    *) PLAN_BADGE="\033[38;5;105m$(echo "$AUTH_PLAN" | tr '[:lower:]' '[:upper:]')\033[0m" ;;
  esac
  USER_INFO="\033[1;34m${SHORT_USER}\033[0m ${PLAN_BADGE}"
fi

# Session cost tracking
CURRENT_SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
CURRENT_SESSION_COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')

STATE_FILE="$HOME/.claude/cost_state.json"

if [ -f "$STATE_FILE" ]; then
  PREV_TOTAL=$(jq -r '.previous_total // 0' "$STATE_FILE")
  LAST_SESSION_ID=$(jq -r '.last_session_id // ""' "$STATE_FILE")
  LAST_SESSION_COST=$(jq -r '.last_session_cost // 0' "$STATE_FILE")
else
  PREV_TOTAL=0
  LAST_SESSION_ID=""
  LAST_SESSION_COST=0
fi

if [ -n "$CURRENT_SESSION_ID" ] && [ "$CURRENT_SESSION_ID" != "$LAST_SESSION_ID" ]; then
  PREV_TOTAL=$(echo "$PREV_TOTAL + $LAST_SESSION_COST" | bc)
  LAST_SESSION_ID="$CURRENT_SESSION_ID"
fi

jq -n \
  --argjson pt "$PREV_TOTAL" \
  --arg sid "$LAST_SESSION_ID" \
  --argjson lsc "$CURRENT_SESSION_COST" \
  '{previous_total: $pt, last_session_id: $sid, last_session_cost: $lsc}' \
  > "$STATE_FILE"

TOTAL_COST=$(echo "$PREV_TOTAL + $CURRENT_SESSION_COST" | bc)
TOTAL_COST_FMT=$(printf "%.3f" "$TOTAL_COST")
SESSION_COST_FMT=$(printf "%.3f" "$CURRENT_SESSION_COST")

# Duration
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')
DURATION_S=$(echo "$DURATION_MS / 1000" | bc)
if [ "$DURATION_S" -ge 3600 ]; then
  DURATION_DISPLAY="$((DURATION_S / 3600))h$((DURATION_S % 3600 / 60))m"
elif [ "$DURATION_S" -ge 60 ]; then
  DURATION_DISPLAY="$((DURATION_S / 60))m$((DURATION_S % 60))s"
else
  DURATION_DISPLAY="${DURATION_S}s"
fi

# Git info
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
GIT_INFO=""
if [ -n "$CWD" ]; then
  GIT_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$GIT_BRANCH" ]; then
    GIT_STATUS=$(git -C "$CWD" status --porcelain 2>/dev/null)
    STAGED=$(echo "$GIT_STATUS" | grep -c "^[MADRC]" 2>/dev/null || echo 0)
    MODIFIED=$(echo "$GIT_STATUS" | grep -c "^.[MD]" 2>/dev/null || echo 0)
    GIT_INFO="\033[38;5;73m ${GIT_BRANCH}\033[0m"
    if [ "$STAGED" -gt 0 ]; then GIT_INFO="${GIT_INFO} \033[38;5;114m+${STAGED}\033[0m"; fi
    if [ "$MODIFIED" -gt 0 ]; then GIT_INFO="${GIT_INFO} \033[38;5;220m~${MODIFIED}\033[0m"; fi
  fi
fi

# Progress bar — uses block chars with cool-tone coloring
FILLED=$(echo "$USED / 10" | bc)
BAR=""
for i in $(seq 1 10); do
  if [ "$i" -le "$FILLED" ]; then BAR="${BAR}█"; else BAR="${BAR}░"; fi
done

# Lines changed
LINES_ADD=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
LINES_INFO=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_INFO=" \033[38;5;114m+${LINES_ADD}\033[0m \033[38;5;174m-${LINES_DEL}\033[0m"
fi

# Context warning
EXCEEDS_200K=$(echo "$INPUT" | jq -r '.exceeds_200k_tokens // false')
CTX_WARN=""
if [ "$EXCEEDS_200K" = "true" ]; then
  CTX_WARN=" \033[38;5;196m⚠ 200k+\033[0m"
fi

# Context color — blue gradient to warm warnings
if [ "$USED" -ge 90 ]; then CTX_COLOR="\033[38;5;196m"
elif [ "$USED" -ge 70 ]; then CTX_COLOR="\033[38;5;220m"
else CTX_COLOR="\033[38;5;69m"
fi

RST="\033[0m"

echo -e "${USER_INFO}  ${CTX_COLOR}${MODEL} ${BAR} ${USED}%${RST}${CTX_WARN}  \033[38;5;183m\$${SESSION_COST_FMT}${RST} \033[38;5;105m(\$${TOTAL_COST_FMT})${RST}  \033[38;5;105m${DURATION_DISPLAY}${RST}${LINES_INFO} ${GIT_INFO}"
