#!/usr/bin/env node
// Claude Code Statusline — Neon Tokyo Edition
// Cyberpunk aesthetic: bright neon colors, diamond separators, ▮/▯ context bar

const { execSync } = require('child_process');

const RESET  = '\x1b[0m';
const CYAN   = '\x1b[96m';   // bright cyan
const MAGENTA = '\x1b[95m';  // bright magenta
const YELLOW = '\x1b[93m';   // bright yellow
const RED    = '\x1b[91m';   // bright red
const DIM    = '\x1b[2m';

const SEP = `${DIM} ◈ ${RESET}`;

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);

    // ── Model ──────────────────────────────────────────────────────────
    const modelRaw = data.model?.display_name || 'Claude';
    // Keep only the short name (e.g. "claude-sonnet-4-5" → "SONNET")
    const modelShort = modelRaw
      .replace(/^claude-?/i, '')
      .replace(/-\d[\d.-]*$/, '')
      .toUpperCase() || modelRaw.toUpperCase();
    const modelPart = `${CYAN}${modelShort}${RESET}`;

    // ── Context bar (10 segments, ▮ filled / ▯ empty) ─────────────────
    const usedPct = Math.round(data.context_window?.used_percentage ?? 0);
    const filled = Math.max(0, Math.min(10, Math.round(usedPct / 10)));
    const bar = '▮'.repeat(filled) + '▯'.repeat(10 - filled);

    let ctxColor = CYAN;
    if (usedPct >= 85) ctxColor = RED;
    else if (usedPct >= 65) ctxColor = YELLOW;

    const ctxPart = `${ctxColor}${bar} ${usedPct}%${RESET}`;

    // ── Cost (¥ symbol for aesthetic) ─────────────────────────────────
    const cost = parseFloat(data.cost?.total_cost_usd ?? 0);
    const costFmt = cost.toFixed(3);
    const costPart = `${MAGENTA}¥${costFmt}${RESET}`;

    // ── Duration ──────────────────────────────────────────────────────
    const durMs = parseInt(data.cost?.total_duration_ms ?? 0, 10);
    const durS  = Math.floor(durMs / 1000);
    let durDisplay;
    if (durS >= 3600) {
      durDisplay = `${Math.floor(durS / 3600)}h${Math.floor((durS % 3600) / 60)}m`;
    } else if (durS >= 60) {
      durDisplay = `${Math.floor(durS / 60)}m${durS % 60}s`;
    } else {
      durDisplay = `${durS}s`;
    }
    const durPart = `${DIM}${durDisplay}${RESET}`;

    // ── Lines added / removed ──────────────────────────────────────────
    const linesAdd = parseInt(data.cost?.total_lines_added   ?? 0, 10);
    const linesDel = parseInt(data.cost?.total_lines_removed ?? 0, 10);
    let linesPart = '';
    if (linesAdd > 0 || linesDel > 0) {
      linesPart = `\x1b[92m+${linesAdd}${RESET} \x1b[91m-${linesDel}${RESET}`;
    }

    // ── Git branch ─────────────────────────────────────────────────────
    let gitPart = '';
    const cwd = data.cwd || '';
    if (cwd) {
      try {
        const branch = execSync(`git -C "${cwd}" rev-parse --abbrev-ref HEAD`, {
          stdio: ['ignore', 'pipe', 'ignore'],
          timeout: 2000,
        }).toString().trim();
        if (branch) {
          gitPart = `${YELLOW}⌥ ${branch}${RESET}`;
        }
      } catch (_) { /* not a git repo or git unavailable */ }
    }

    // ── Assemble ───────────────────────────────────────────────────────
    const parts = [modelPart, ctxPart, costPart, durPart];
    if (linesPart) parts.push(linesPart);
    if (gitPart)   parts.push(gitPart);

    process.stdout.write(parts.join(SEP));
  } catch (_) {
    // Silent fail — never break the statusline
  }
});
