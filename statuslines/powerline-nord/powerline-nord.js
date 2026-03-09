#!/usr/bin/env node
/**
 * Powerline Nord — Claude Code statusline
 * Nord color palette with angled slash segments and a two-line layout
 * Aesthetic: cold arctic, clean, professional — inspired by Nord theme
 *
 * Requires: Node.js, git
 * Requires Nerd Fonts for powerline separators
 *
 * Install:
 *   cp powerline-nord.js ~/.claude/statusline.js
 *   chmod +x ~/.claude/statusline.js
 * Add to ~/.claude/settings.json:
 *   "statusLine": { "type": "command", "command": "node ~/.claude/statusline.js" }
 */

'use strict';

const { execSync } = require('child_process');

// ── ANSI helpers ───────────────────────────────────────────────────────────────
const fg  = n  => `\x1b[38;5;${n}m`;
const bg  = n  => `\x1b[48;5;${n}m`;
const RST = '\x1b[0m';
const BOLD = '\x1b[1m';
const DIM  = '\x1b[2m';

// Powerline: filled right arrow, angle-down separators
const PL_R    = '\ue0b0';  // ► filled right arrow
const PL_DOWN = '\ue0b8';  // angled down-right (lower-left filled)
const PL_UP   = '\ue0ba';  // angled up-right

function trans(fromBg, toBg) {
  return `${fg(fromBg)}${bg(toBg)}${PL_R}`;
}
function endSeg(lastBg) {
  return `${RST}${fg(lastBg)}${PL_R}${RST}`;
}

// ── Nord palette (256-color approximations) ────────────────────────────────────
const N = {
  // Polar Night (dark backgrounds)
  n0:  236,  // darkest bg
  n1:  237,  // dark bg
  n2:  238,  // medium-dark bg
  n3:  239,  // lighter bg
  // Snow Storm (light text)
  s0:  188,  // dim white
  s1:  251,  // medium white
  s2:  255,  // bright white
  // Frost (accent blues)
  f0:  110,  // muted blue-gray
  f1:  109,  // steel blue
  f2:  111,  // cornflower blue
  f3:  81,   // bright ice blue
  // Aurora (semantic colors)
  aRed:    174,  // muted rose red
  aOrange: 223,  // warm tan/orange
  aYellow: 222,  // pale gold
  aGreen:  108,  // sage green
  aPurple: 147,  // soft violet/periwinkle
};

// ── Parse input ────────────────────────────────────────────────────────────────
let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => raw += chunk);
process.stdin.on('end', () => {
  let data;
  try { data = JSON.parse(raw); } catch { process.exit(0); }

  const model    = (data.model?.display_name || 'Claude').replace('Claude ', '');
  const ctxUsed  = Math.round(data.context_window?.used_percentage || 0);
  const cost     = data.cost?.total_cost_usd || 0;
  const durMs    = data.cost?.total_duration_ms || 0;
  const linesAdd = data.cost?.total_lines_added || 0;
  const linesDel = data.cost?.total_lines_removed || 0;
  const cwd      = data.cwd || '';

  // ── Duration ─────────────────────────────────────────────────────────────────
  const durS = Math.floor(durMs / 1000);
  let durStr;
  if (durS >= 3600)      durStr = `${Math.floor(durS/3600)}h${Math.floor((durS%3600)/60)}m`;
  else if (durS >= 60)   durStr = `${Math.floor(durS/60)}m${durS%60}s`;
  else                   durStr = `${durS}s`;

  const costStr = `$${cost.toFixed(3)}`;

  // ── Git ───────────────────────────────────────────────────────────────────────
  let gitBranch = '', gitStaged = 0, gitMod = 0;
  if (cwd) {
    try {
      gitBranch = execSync(`git -C "${cwd}" rev-parse --abbrev-ref HEAD`, { stdio: ['ignore','pipe','ignore'] })
        .toString().trim();
      if (gitBranch) {
        const status = execSync(`git -C "${cwd}" status --porcelain`, { stdio: ['ignore','pipe','ignore'] })
          .toString().split('\n');
        gitStaged = status.filter(l => /^[MADRC]/.test(l)).length;
        gitMod    = status.filter(l => /^.[MD]/.test(l)).length;
      }
    } catch {}
  }

  // ── Context bar (10 blocks) ───────────────────────────────────────────────────
  const filled = Math.min(10, Math.floor(ctxUsed / 10));
  const ctxBar = '▓'.repeat(filled) + '░'.repeat(10 - filled);

  // Context color
  let ctxBg, ctxFg;
  if (ctxUsed >= 90)      { ctxBg = N.aRed;    ctxFg = N.s2; }
  else if (ctxUsed >= 70) { ctxBg = N.aOrange;  ctxFg = N.n0; }
  else                    { ctxBg = N.aGreen;   ctxFg = N.n0; }

  // ── Line 1: Model | Context | Cost ───────────────────────────────────────────
  // Segment: Model (frost blue bg)
  let line1 = '';
  line1 += `${bg(N.f1)}${fg(N.n0)}${BOLD} ❄ ${model} `;
  line1 += trans(N.f1, ctxBg);
  line1 += `${fg(ctxFg)} ${ctxBar} ${ctxUsed}% `;
  line1 += trans(ctxBg, N.n1);
  line1 += `${fg(N.aPurple)}${BOLD} ${costStr} `;
  line1 += endSeg(N.n1);

  // ── Line 2: Git | Duration | Lines ───────────────────────────────────────────
  let line2 = '';

  // Git segment (frost-2 bg)
  if (gitBranch) {
    line2 += `${bg(N.f2)}${fg(N.n0)} ${BOLD} ${gitBranch}`;
    if (gitStaged > 0) line2 += ` ${fg(N.aGreen)}+${gitStaged}${fg(N.n0)}`;
    if (gitMod    > 0) line2 += ` ${fg(N.aYellow)}~${gitMod}${fg(N.n0)}`;
    line2 += ' ';
    line2 += trans(N.f2, N.n2);
  } else {
    line2 += `${bg(N.n2)}${fg(N.s0)} `;
  }

  // Duration segment
  line2 += `${fg(N.s1)} ${durStr} `;

  // Lines changed
  if (linesAdd > 0 || linesDel > 0) {
    line2 += trans(N.n2, N.n1);
    line2 += `${fg(N.aGreen)} +${linesAdd} ${fg(N.aRed)}-${linesDel} `;
    line2 += endSeg(N.n1);
  } else {
    line2 += endSeg(N.n2);
  }

  process.stdout.write(`${line1}\n${line2}\n`);
});
