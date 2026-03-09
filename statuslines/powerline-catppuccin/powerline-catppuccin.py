#!/usr/bin/env python3
"""
Powerline Catppuccin — Claude Code statusline
Catppuccin Mocha pastel dark palette with floating diamond pill segments
Aesthetic: soft pastel dark, gentle lavender/blue/peach accents, cozy and elegant

Requires: Python 3 (stdlib only), git
Requires Nerd Fonts for diamond pill separators

Install:
  cp powerline-catppuccin.py ~/.claude/statusline.py
  chmod +x ~/.claude/statusline.py
Add to ~/.claude/settings.json:
  "statusLine": { "type": "command", "command": "~/.claude/statusline.py" }
"""

import sys
import json
import subprocess
import os

# ── ANSI helpers ───────────────────────────────────────────────────────────────
def fg(n): return f'\033[38;5;{n}m'
def bg(n): return f'\033[48;5;{n}m'
RST  = '\033[0m'
BOLD = '\033[1m'
DIM  = '\033[2m'

# Diamond pill separators (Nerd Fonts)
DIAMOND_L = '\ue0b6'  # left rounded cap  ⬡
DIAMOND_R = '\ue0b4'  # right rounded cap ⬡

def pill(bg_c, fg_c, text, icon=''):
    """Render a floating rounded pill segment."""
    content = f'{icon} {text}' if icon else text
    return (
        f'{RST}{fg(bg_c)}{DIAMOND_L}'
        f'{bg(bg_c)}{fg(fg_c)}{BOLD} {content} '
        f'{RST}{fg(bg_c)}{DIAMOND_R}{RST}'
    )

def thin_pill(bg_c, fg_c, text):
    """Pill without bold — for secondary info."""
    return (
        f'{RST}{fg(bg_c)}{DIAMOND_L}'
        f'{bg(bg_c)}{fg(fg_c)} {text} '
        f'{RST}{fg(bg_c)}{DIAMOND_R}{RST}'
    )

# ── Catppuccin Mocha palette (256-color approximations) ───────────────────────
# Base/surface shades
M_BASE   = 235   # very dark bg
M_SURF0  = 236   # surface 0
M_SURF1  = 237   # surface 1
M_SURF2  = 238   # surface 2
M_MANTLE = 234   # slightly lighter than base

# Text
M_TEXT    = 188  # main text
M_SUBTEXT = 144  # secondary text
M_OVERLAY = 102  # overlay / muted

# Accent colors (Mocha)
M_MAUVE   = 183  # lavender/mauve — primary accent
M_BLUE    = 111  # soft blue
M_SAPPH   = 110  # sapphire
M_SKY     = 116  # sky blue
M_TEAL    = 115  # teal
M_GREEN   = 114  # sage green (rosewater-adjacent)
M_YELLOW  = 221  # warm yellow
M_PEACH   = 216  # peachy orange
M_MAROON  = 210  # muted red/maroon
M_RED     = 210  # red (same approximation)
M_ROSEWATER = 217  # pale pink/rosewater
M_LAVEN   = 147  # lavender

# ── Parse input ────────────────────────────────────────────────────────────────
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

model     = data.get('model', {}).get('display_name', 'Claude')
model     = model.replace('Claude ', '')
ctx_used  = int(data.get('context_window', {}).get('used_percentage', 0))
cost      = data.get('cost', {}).get('total_cost_usd', 0)
dur_ms    = data.get('cost', {}).get('total_duration_ms', 0)
lines_add = data.get('cost', {}).get('total_lines_added', 0)
lines_del = data.get('cost', {}).get('total_lines_removed', 0)
cwd       = data.get('cwd', '')

# ── Git ────────────────────────────────────────────────────────────────────────
git_branch = ''
git_staged = 0
git_mod    = 0
if cwd:
    try:
        branch = subprocess.check_output(
            ['git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD'],
            stderr=subprocess.DEVNULL, text=True
        ).strip()
        if branch:
            git_branch = branch
            status_out = subprocess.check_output(
                ['git', '-C', cwd, 'status', '--porcelain'],
                stderr=subprocess.DEVNULL, text=True
            )
            git_staged = sum(1 for l in status_out.splitlines() if l[:1] in 'MADRC')
            git_mod    = sum(1 for l in status_out.splitlines() if l[1:2] in 'MD')
    except Exception:
        pass

# ── Duration ───────────────────────────────────────────────────────────────────
dur_s = dur_ms // 1000
if dur_s >= 3600:
    dur_str = f"{dur_s // 3600}h{(dur_s % 3600) // 60}m"
elif dur_s >= 60:
    dur_str = f"{dur_s // 60}m{dur_s % 60}s"
else:
    dur_str = f"{dur_s}s"

cost_str = f"${cost:.3f}"

# ── Context bar (8 segments) ───────────────────────────────────────────────────
filled  = min(8, ctx_used * 8 // 100)
ctx_bar = '█' * filled + '░' * (8 - filled)

# Context pill color: semantic aurora-like progression
if ctx_used >= 90:
    ctx_bg = M_MAROON; ctx_fg = M_BASE
elif ctx_used >= 70:
    ctx_bg = M_PEACH;  ctx_fg = M_BASE
else:
    ctx_bg = M_TEAL;   ctx_fg = M_BASE

# ── Auth / plan ────────────────────────────────────────────────────────────────
# Try to get plan from cached auth data
auth_cache = os.path.expanduser('~/.claude/auth_cache.json')
plan_badge = ''
try:
    with open(auth_cache) as f:
        auth = json.load(f)
    plan = auth.get('subscriptionType', '').lower()
    if plan == 'max':
        plan_badge = f' {fg(M_MAUVE)}◆ MAX{fg(M_BASE)}'
    elif plan == 'pro':
        plan_badge = f' {fg(M_BLUE)}◆ PRO{fg(M_BASE)}'
except Exception:
    pass

# ── Assemble pills ─────────────────────────────────────────────────────────────
parts = []

# Pill 1: Model + plan badge (mauve/lavender)
model_text = model
parts.append(pill(M_MAUVE, M_BASE, model_text, '✦'))

# Pill 2: Context (teal/peach/maroon by load)
parts.append(pill(ctx_bg, ctx_fg, f'{ctx_bar} {ctx_used}%'))

# Pill 3: Cost (peach/rosewater)
parts.append(pill(M_ROSEWATER, M_BASE, cost_str, '◈'))

# Pill 4: Git (sky blue, only when in repo)
if git_branch:
    git_text = git_branch
    if git_staged > 0 or git_mod > 0:
        git_text += f' +{git_staged}' if git_staged else ''
        git_text += f' ~{git_mod}'   if git_mod    else ''
    parts.append(pill(M_SKY, M_BASE, git_text, ''))

# Pill 5: Duration (surface-2, muted)
dur_text = dur_str
if lines_add > 0 or lines_del > 0:
    dur_text += f'  +{lines_add}/-{lines_del}'
parts.append(thin_pill(M_SURF2, M_SUBTEXT, dur_text))

# Space-separate all pills
print('  '.join(parts))
