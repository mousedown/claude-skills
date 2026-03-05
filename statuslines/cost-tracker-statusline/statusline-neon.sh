#!/bin/zsh
# Theme: Neon Terminal — high contrast, retro hacker aesthetic
source "$HOME/.claude/statusline-core.sh"

# 256-color codes: 46=neon green, 208=orange, 51=electric cyan, 201=hot pink, 226=neon yellow
USER_INFO=""
if [ -n "$SHORT_USER" ]; then
  PLAN_BADGE=""
  case "$AUTH_PLAN" in
    max) PLAN_BADGE="\033[1;38;5;226mMAX\033[0m" ;;
    pro) PLAN_BADGE="\033[1;38;5;51mPRO\033[0m" ;;
    *) PLAN_BADGE="\033[1;38;5;208m$(echo "$AUTH_PLAN" | tr '[:lower:]' '[:upper:]')\033[0m" ;;
  esac
  USER_INFO="\033[1;38;5;46m${SHORT_USER}\033[0m ${PLAN_BADGE}"
  if [ -n "$AUTH_ORG" ]; then
    USER_INFO="${USER_INFO} \033[37m@${AUTH_ORG}\033[0m"
  fi
fi

# Git
GIT_INFO=""
if [ -n "$GIT_BRANCH" ]; then
  GIT_INFO="\033[1;38;5;51m ${GIT_BRANCH}\033[0m"
  if [ "$STAGED" -gt 0 ]; then GIT_INFO="${GIT_INFO} \033[1;38;5;46m+${STAGED}\033[0m"; fi
  if [ "$MODIFIED" -gt 0 ]; then GIT_INFO="${GIT_INFO} \033[1;38;5;226m~${MODIFIED}\033[0m"; fi
fi

# Progress bar — neon blocks
BAR=""
for i in $(seq 1 10); do
  if [ "$i" -le "$FILLED" ]; then BAR="${BAR}█"; else BAR="${BAR}▁"; fi
done

# Lines
LINES_INFO=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_INFO=" \033[1;38;5;46m+${LINES_ADD}\033[0m \033[1;38;5;196m-${LINES_DEL}\033[0m"
fi

# Context warning + color — neon green to hot warnings
CTX_WARN=""
if [ "$EXCEEDS_200K" = "true" ]; then CTX_WARN=" \033[5;38;5;196m⚠ 200k+\033[0m"; fi
if [ "$USED" -ge 90 ]; then CTX_COLOR="\033[1;38;5;196m"
elif [ "$USED" -ge 70 ]; then CTX_COLOR="\033[1;38;5;208m"
else CTX_COLOR="\033[38;5;103m"
fi

echo -e "${USER_INFO}  ${CTX_COLOR}${MODEL} ${BAR} ${USED}%${RST}${CTX_WARN}  \033[1;38;5;208m\$${SESSION_COST_FMT}${RST} \033[38;5;240m(\$${TOTAL_COST_FMT})${RST}  \033[38;5;240m${DURATION_DISPLAY}${RST}${LINES_INFO} ${GIT_INFO}"
