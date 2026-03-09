#!/usr/bin/env node
// Claude Code Statusline — Split View
//
// Layout: [git + context ──────────────── cost | model | time]
//
// The left side shows git status and context window usage.
// The right side shows cost, model, and session duration — right-aligned.
// Content fills the full terminal width for a "status bar" feel.
//
// Install:
//   cp statusline.js ~/.claude/statusline.js
//   chmod +x ~/.claude/statusline.js
// Add to ~/.claude/settings.json:
//   "statusLine": { "type": "command", "command": "node ~/.claude/statusline.js" }
//
// Requirements: Node.js, git (optional)

'use strict';

const { execSync } = require('child_process');

// ANSI helpers
const R  = '\x1b[0m';
const B  = '\x1b[1m';
const D  = '\x1b[2m';
const G  = '\x1b[32m';
const Y  = '\x1b[33m';
const RE = '\x1b[31m';
const C  = '\x1b[36m';
const M  = '\x1b[35m';
const GR = '\x1b[90m';
const W  = '\x1b[97m';

// Strip ANSI escape codes to get visible (printable) length
function visLen(s) {
  return s.replace(/\x1b\[[0-9;]*m/g, '').replace(/[^\x20-\x7E\u2000-\uFFFF]/g, '  ').length;
}

// Build a progress bar (e.g. ▓▓▓░░░░░░░)
function bar(pct, width = 10) {
  const n = Math.min(Math.max(Math.round(pct * width / 100), 0), width);
  return '▓'.repeat(n) + '░'.repeat(width - n);
}

// Format duration from milliseconds
function fmtDur(ms) {
  const s = Math.floor(ms / 1000);
  if (s >= 3600) return `${Math.floor(s / 3600)}h${Math.floor((s % 3600) / 60)}m`;
  if (s >= 60)   return `${Math.floor(s / 60)}m${s % 60}s`;
  return `${s}s`;
}

// git wrapper — returns '' on any error
function git(cwd, args) {
  try {
    return execSync(`git -C "${cwd}" ${args}`, {
      stdio: ['ignore', 'pipe', 'ignore'],
      timeout: 2000,
    }).toString().trim();
  } catch (_) { return ''; }
}

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', c => { raw += c; });
process.stdin.on('end', () => {
  try {
    const d = JSON.parse(raw);

    // ── Parsed fields ──────────────────────────────────────────────
    const modelFull = d.model?.display_name || 'Claude';
    const model     = modelFull
      .replace(/^claude[- ]/i, '')
      .replace(/[- ]\d[\d.]*$/, '') || modelFull;
    const usedPct = Math.round(d.context_window?.used_percentage ?? 0);
    const cost    = parseFloat(d.cost?.total_cost_usd    ?? 0);
    const durMs   = parseInt(d.cost?.total_duration_ms  ?? 0, 10);
    const cwd     = d.cwd || '';

    // ── Context color ──────────────────────────────────────────────
    const ctxColor = usedPct >= 85 ? RE : usedPct >= 65 ? Y : G;

    // ── LEFT SIDE: git status + context ───────────────────────────
    let leftParts = [];

    if (cwd) {
      const branch = git(cwd, 'rev-parse --abbrev-ref HEAD');
      if (branch) {
        let gitStr = `${C}⎇ ${branch}${R}`;
        const status = git(cwd, 'status --porcelain');
        if (status) {
          const staged    = (status.match(/^[MADRC]/mg)  || []).length;
          const modified  = (status.match(/^.[MD]/mg)    || []).length;
          const untracked = (status.match(/^\?\?/mg)     || []).length;
          const ahead  = parseInt(git(cwd, 'rev-list --count @{u}..HEAD 2>/dev/null') || '0', 10);
          const behind = parseInt(git(cwd, 'rev-list --count HEAD..@{u} 2>/dev/null') || '0', 10);
          if (staged)    gitStr += ` ${G}✚${staged}${R}`;
          if (modified)  gitStr += ` ${Y}✎${modified}${R}`;
          if (untracked) gitStr += ` ${GR}?${untracked}${R}`;
          if (ahead)     gitStr += ` ${C}↑${ahead}${R}`;
          if (behind)    gitStr += ` ${RE}↓${behind}${R}`;
        }
        leftParts.push(gitStr);
      }
    }

    // Context bar + percentage
    const ctxPart = `${ctxColor}${bar(usedPct)} ${usedPct}%${R}`;
    leftParts.push(ctxPart);

    // Lines changed
    const linesAdd = parseInt(d.cost?.total_lines_added   ?? 0, 10);
    const linesDel = parseInt(d.cost?.total_lines_removed ?? 0, 10);
    if (linesAdd > 0 || linesDel > 0) {
      leftParts.push(`${G}+${linesAdd}${R} ${RE}-${linesDel}${R}`);
    }

    const left = leftParts.join(`  ${D}│${R}  `);

    // ── RIGHT SIDE: duration | cost | model ───────────────────────
    const rightParts = [
      `${D}${fmtDur(durMs)}${R}`,
      `${M}\$${cost.toFixed(3)}${R}`,
      `${B}${C}${model}${R}`,
    ];
    const right = rightParts.join(`  ${D}│${R}  `);

    // ── Compute gap to fill terminal width ────────────────────────
    const termWidth = process.stdout.columns || 120;
    const leftLen   = visLen(left);
    const rightLen  = visLen(right);
    const gap       = Math.max(2, termWidth - leftLen - rightLen - 2);

    process.stdout.write(left + ' '.repeat(gap) + right);

  } catch (_) {
    // Silent fail — never break Claude Code
  }
});
