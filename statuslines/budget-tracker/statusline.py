#!/usr/bin/env python3
# budget-tracker statusline — financial dashboard for Claude Code sessions
# Shows: budget-icon  model  session-cost  $/hr  context%  git-branch
# Requires: python3, git (optional)

import sys
import json
import subprocess

def get_git_branch(cwd):
    if not cwd:
        return ""
    try:
        result = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            timeout=2
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return ""

def format_cost(value):
    if value >= 1.0:
        return f"${value:.2f}"
    elif value >= 0.01:
        return f"${value:.3f}"
    else:
        return f"${value:.4f}"

def main():
    try:
        raw = sys.stdin.read()
        data = json.loads(raw)
    except Exception:
        sys.stdout.write("budget-tracker: parse error")
        return

    # ── Parse fields ────────────────────────────────────────────────
    try:
        model = data.get("model", {}).get("display_name", "Claude")
        model = model.replace("Claude ", "")
    except Exception:
        model = "Claude"

    try:
        used_pct = int(round(float(data.get("context_window", {}).get("used_percentage", 0))))
    except Exception:
        used_pct = 0

    try:
        cost = float(data.get("cost", {}).get("total_cost_usd", 0))
    except Exception:
        cost = 0.0

    try:
        duration_ms = float(data.get("cost", {}).get("total_duration_ms", 0))
    except Exception:
        duration_ms = 0.0

    cwd = data.get("cwd", "")

    # ── Derived metrics ─────────────────────────────────────────────
    duration_s = duration_ms / 1000.0
    duration_h = duration_s / 3600.0

    cost_per_hour = None
    daily_estimate = None

    if duration_s >= 60:
        if duration_h > 0:
            cost_per_hour = cost / duration_h
        if duration_s > 0:
            daily_estimate = cost * (86400.0 / duration_s)

    # ── Budget warning level ─────────────────────────────────────────
    # Thresholds based on hourly spend rate
    if cost_per_hour is not None:
        if cost_per_hour >= 5.0:
            icon = "\U0001f6a8"   # 🚨 very high
        elif cost_per_hour >= 1.0:
            icon = "\U0001f4b8"   # 💸 high
        else:
            icon = "\U0001f4b0"   # 💰 normal
    else:
        icon = "\U0001f4b0"       # 💰 default (session too short to judge)

    # ── Git branch ───────────────────────────────────────────────────
    git_branch = get_git_branch(cwd)

    # ── ANSI colors ──────────────────────────────────────────────────
    BOLD    = "\033[1m"
    DIM     = "\033[2m"
    GREEN   = "\033[32m"
    YELLOW  = "\033[33m"
    RED     = "\033[31m"
    CYAN    = "\033[36m"
    MAGENTA = "\033[35m"
    RST     = "\033[0m"

    # ── Context color ────────────────────────────────────────────────
    if used_pct >= 90:
        ctx_color = f"\033[1;31m"
    elif used_pct >= 70:
        ctx_color = YELLOW
    else:
        ctx_color = GREEN

    # ── Format cost fields ───────────────────────────────────────────
    cost_fmt = format_cost(cost)

    # ── Assemble output ──────────────────────────────────────────────
    parts = [
        f"{icon} {BOLD}{model}{RST}",
        f"{MAGENTA}{cost_fmt}{RST}",
    ]

    if cost_per_hour is not None:
        hr_fmt = format_cost(cost_per_hour)
        parts.append(f"{DIM}~{hr_fmt}/hr{RST}")

    parts.append(f"{ctx_color}{used_pct}%{RST}")

    if git_branch:
        parts.append(f"{CYAN}{git_branch}{RST}")

    output = "  ".join(parts)
    sys.stdout.write(output)

if __name__ == "__main__":
    main()
