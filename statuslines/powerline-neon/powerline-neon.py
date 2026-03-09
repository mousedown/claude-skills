#!/usr/bin/env python3
"""
Powerline Neon — Claude Code statusline
Cyberpunk/retro neon aesthetic: vivid backgrounds, dark text, thin powerline arrows
Aesthetic: hot pink → electric cyan → neon lime → dark segment train

Requires: Python 3 (stdlib only)
Requires Nerd Fonts for powerline arrows

Install:
  cp powerline-neon.py ~/.claude/statusline.py
  chmod +x ~/.claude/statusline.py
Add to ~/.claude/settings.json:
  "statusLine": { "type": "command", "command": "~/.claude/statusline.py" }
"""

import sys
import json
import os
import subprocess

# ── ANSI helpers ───────────────────────────────────────────────────────────────
def fg(n): return f'\033[38;5;{n}m'
def bg(n): return f'\033[48;5;{n}m'
RST = '\033[0m'
BOLD = '\033[1m'
DIM = '\033[2m'

# Powerline characters (Nerd Fonts required)
PL_R    = '\ue0b0'   # ► filled right arrow
PL_THIN = '\ue0b1'   # thin right arrow  (decorative divider within segment)
PL_L    = '\ue0b2'   # ◄ filled left arrow

def trans(from_bg, to_bg):
    """Arrow transition from one segment to the next."""
    return f'{fg(from_bg)}{bg(to_bg)}{PL_R}'

def end_seg(last_bg):
    """Final arrow back to transparent terminal bg."""
    return f'{RST}{fg(last_bg)}{PL_R}{RST}'

# ── Parse input ────────────────────────────────────────────────────────────────
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

model      = data.get('model', {}).get('display_name', 'Claude')
model      = model.replace('Claude ', '')  # shorten
ctx_used   = int(data.get('context_window', {}).get('used_percentage', 0))
cost       = data.get('cost', {}).get('total_cost_usd', 0)
dur_ms     = data.get('cost', {}).get('total_duration_ms', 0)
lines_add  = data.get('cost', {}).get('total_lines_added', 0)
lines_del  = data.get('cost', {}).get('total_lines_removed', 0)
cwd        = data.get('cwd', '')

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
            status = subprocess.check_output(
                ['git', '-C', cwd, 'status', '--porcelain'],
                stderr=subprocess.DEVNULL, text=True
            )
            git_staged = sum(1 for l in status.splitlines() if l[:1] in 'MADRC')
            git_mod    = sum(1 for l in status.splitlines() if l[1:2] in 'MD')
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

# ── Context bar (6 blocks) ─────────────────────────────────────────────────────
filled = min(6, ctx_used * 6 // 100)
ctx_bar = '█' * filled + '░' * (6 - filled)

# ── Neon color palette ─────────────────────────────────────────────────────────
# Hot pink → Electric cyan → Neon lime → Deep violet
C_PINK    = 200   # hot pink background
C_CYAN    = 51    # electric cyan background
C_LIME    = 46    # neon lime background
C_VIOLET  = 57    # deep violet background
C_AMBER   = 214   # amber/orange background
C_BLACK   = 16    # near-black text on bright bg

# Context color (bg changes by usage level)
if ctx_used >= 90:
    C_CTX_BG = 196  # bright red
    C_CTX_FG = 16
elif ctx_used >= 70:
    C_CTX_BG = C_AMBER
    C_CTX_FG = 16
else:
    C_CTX_BG = C_CYAN
    C_CTX_FG = 16

# ── Build output ───────────────────────────────────────────────────────────────
out = []

# Segment 1: Model (hot pink bg, black text)
out.append(f'{bg(C_PINK)}{fg(C_BLACK)}{BOLD} ✦ {model} ')

# Segment 2: Context (color-coded bg)
out.append(trans(C_PINK, C_CTX_BG))
out.append(f'{fg(C_CTX_FG)} {ctx_bar} {ctx_used}% ')

# Segment 3: Cost (lime bg, black text)
out.append(trans(C_CTX_BG, C_LIME))
out.append(f'{fg(C_BLACK)}{BOLD} {cost_str} ')

# Segment 4: Git (violet bg) — only if in a repo
if git_branch:
    out.append(trans(C_LIME, C_VIOLET))
    out.append(f'{fg(255)}  {git_branch}')
    if git_staged > 0:
        out.append(f' {fg(C_LIME)}+{git_staged}{fg(255)}')
    if git_mod > 0:
        out.append(f' {fg(C_AMBER)}~{git_mod}{fg(255)}')
    out.append(' ')
    last_bg = C_VIOLET
else:
    last_bg = C_LIME

# Segment 5: Duration (small, dark trailer)
C_DARK = 236
out.append(trans(last_bg, C_DARK))
out.append(f'{fg(244)} {dur_str}')
if lines_add > 0 or lines_del > 0:
    out.append(f' {PL_THIN}{fg(34)} +{lines_add}{fg(244)} {PL_THIN}{fg(160)} -{lines_del}{fg(244)}')
out.append(' ')
out.append(end_seg(C_DARK))

print(''.join(out))
