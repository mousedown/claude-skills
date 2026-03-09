#!/usr/bin/env node
// Claude Code Statusline — Token Focus Edition
// Makes actual token counts the primary focus, not just percentages.
// Shows token numbers when derivable; falls back gracefully to percentages.

const { execSync } = require('child_process');

const RESET  = '\x1b[0m';
const BOLD   = '\x1b[1m';
const DIM    = '\x1b[2m';
const GREEN  = '\x1b[32m';
const YELLOW = '\x1b[33m';
const RED    = '\x1b[31m';
const CYAN   = '\x1b[36m';
const WHITE  = '\x1b[37m';

// Format a raw token count as a compact string: 42000 → "42k", 1200000 → "1.2M"
function fmtTokens(n) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000)     return `${Math.round(n / 1_000)}k`;
  return String(n);
}

// Format duration in milliseconds to "15m32s" / "1h2m" / "45s"
function fmtDuration(ms) {
  const s = Math.floor(ms / 1000);
  if (s >= 3600) return `${Math.floor(s / 3600)}h${Math.floor((s % 3600) / 60)}m`;
  if (s >= 60)   return `${Math.floor(s / 60)}m${s % 60}s`;
  return `${s}s`;
}

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);

    // ── Model ────────────────────────────────────────────────────────────
    const modelRaw = data.model?.display_name || data.model?.name || 'Claude';
    // Strip leading "claude-" prefix and trailing version numbers for brevity
    const modelShort = modelRaw
      .replace(/^claude[- ]/i, '')
      .replace(/[- ]\d[\d.-]*$/, '')
      .replace(/\b(\w)/g, c => c.toUpperCase()); // Title-case each word
    const modelPart = `${CYAN}${modelShort || modelRaw}${RESET}`;

    // ── Context window — prefer real token counts, fall back to % ─────────
    const ctxWin = data.context_window || {};
    const usedPct      = Math.round(ctxWin.used_percentage      ?? 0);
    const remainingPct = Math.round(ctxWin.remaining_percentage ?? (100 - usedPct));

    // Check for explicit token count fields (various possible names)
    const tokensUsed  = ctxWin.context_tokens_used
                     ?? ctxWin.tokens_used
                     ?? ctxWin.used_tokens
                     ?? null;
    const tokensTotal = ctxWin.context_window_size
                     ?? ctxWin.total_tokens
                     ?? ctxWin.window_size
                     ?? null;

    // If we have the used count but not total, try to derive total from %
    let derivedTotal = tokensTotal;
    if (tokensUsed !== null && derivedTotal === null && usedPct > 0) {
      derivedTotal = Math.round((tokensUsed / usedPct) * 100);
    }

    // Choose context color based on percentage used
    let ctxColor;
    if (usedPct >= 85)     ctxColor = RED;
    else if (usedPct >= 65) ctxColor = YELLOW;
    else                    ctxColor = GREEN;

    let ctxPart;
    if (tokensUsed !== null && derivedTotal !== null) {
      // Show real token counts: "83k/200k ctx  42%"
      ctxPart = `${ctxColor}${fmtTokens(tokensUsed)}/${fmtTokens(derivedTotal)} ctx${RESET}  ${ctxColor}${usedPct}%${RESET}`;
    } else if (tokensUsed !== null) {
      // Have used count but no total
      ctxPart = `${ctxColor}${fmtTokens(tokensUsed)} tokens  ${usedPct}%${RESET}`;
    } else {
      // Percentage only
      ctxPart = `${ctxColor}${usedPct}% ctx${RESET}`;
    }

    // ── Lines added / removed ─────────────────────────────────────────────
    const linesAdd = parseInt(data.cost?.total_lines_added   ?? 0, 10);
    const linesDel = parseInt(data.cost?.total_lines_removed ?? 0, 10);
    let linesPart = '';
    if (linesAdd > 0 || linesDel > 0) {
      linesPart = `${GREEN}+${linesAdd}${RESET} ${RED}-${linesDel}${RESET}`;
    }

    // ── Cost — 4 decimal places for precision ─────────────────────────────
    const cost = parseFloat(data.cost?.total_cost_usd ?? 0);
    const costPart = `${WHITE}\$${cost.toFixed(4)}${RESET}`;

    // ── Duration ──────────────────────────────────────────────────────────
    const durMs = parseInt(data.cost?.total_duration_ms ?? 0, 10);
    const durPart = `${DIM}${fmtDuration(durMs)}${RESET}`;

    // ── Git branch ────────────────────────────────────────────────────────
    let gitPart = '';
    const cwd = data.cwd || '';
    if (cwd) {
      try {
        const branch = execSync(`git -C "${cwd}" rev-parse --abbrev-ref HEAD`, {
          stdio: ['ignore', 'pipe', 'ignore'],
          timeout: 2000,
        }).toString().trim();
        if (branch) {
          gitPart = `${DIM} ${branch}${RESET}`;
        }
      } catch (_) { /* not a git repo or git unavailable */ }
    }

    // ── Assemble — information-dense but readable ─────────────────────────
    const parts = [modelPart, ctxPart];
    if (linesPart) parts.push(linesPart);
    parts.push(costPart, durPart);
    if (gitPart)   parts.push(gitPart);

    process.stdout.write(parts.join('  '));
  } catch (_) {
    // Silent fail — never break the statusline
  }
});
