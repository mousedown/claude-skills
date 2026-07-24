---
name: autofix-pr
description: Automatically review PR comments, evaluate each issue, fix critical/high severity issues that are valid, and reply to all comments. Use when the user says "autofix pr", "fix pr issues", "review and fix pr", or provides a PR URL and asks to address the feedback. Also use when a PR has bot review comments (e.g. PullBot, CodeRabbit) that need triage.
---

# Autofix PR

Evaluate all comments on a PR. For each issue: read the code, form an independent opinion, fix if valid and high severity, reply if disagreed. One commit for all fixes, one reply per comment.

## Workflow

### 1. Fetch PR comments

```
gh api repos/{owner}/{repo}/pulls/{number}/comments   # inline review comments
gh pr view {number} --json comments                    # general PR comments
```

### 2. Classify each comment

**By source:**
- **Human** — from a team member (check `author.login` against known bot accounts)
- **Bot** — from `github-actions`, review bots (PullBot, CodeRabbit, etc.)

**By severity** (for bot comments, parse the badge/label):
- `critical` / `high` / `warning` — evaluate and fix if agreed
- `info` / `minor` / `suggestion` — note but do not fix unless trivial

**Human comments** — always evaluate seriously regardless of phrasing. Humans don't use severity badges.

### 3. Evaluate each issue independently

For every comment that requests a change:

1. Read the referenced file and surrounding context
2. Form your own opinion — do you agree the issue is real?
3. Check if the suggested fix is correct (bot suggestions are often wrong or over-engineered)

Classify your assessment:
- **Agree + will fix** — the issue is real and the fix is straightforward
- **Agree + won't fix** — the issue is real but the fix is out of scope, would cause regressions, or is not worth the complexity
- **Disagree** — the issue is not real, is already handled, or the reviewer misread the code
- **Already handled** — the issue was valid but is addressed elsewhere (e.g. middleware strips the header)

### 4. Fix agreed critical/high issues

For each "agree + will fix":
1. Make the code change
2. Run type-check and lint to verify
3. Stage the changed files

After all fixes are applied:
- Run the full verification suite (lint, type-check, build, tests)
- Create ONE commit with a message summarizing all fixes:
  ```
  fix: address PR review — <brief summary of changes>
  ```
- Push to the PR branch

### 5. Reply to each comment

Use `gh api` to reply to each comment:

```bash
# For inline review comments (have a thread)
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -f body="<reply>"

# For general PR comments
gh api repos/{owner}/{repo}/issues/{number}/comments \
  -f body="<reply>"
```

**Reply format by assessment:**

**Agree + fixed:**
> Fixed in <commit-sha>. <one-line description of what changed>.

**Agree + won't fix:**
> Agree this is valid. Not fixing in this PR because <reason>. Tracked for follow-up.

**Disagree:**
> This is already handled — <explanation with file:line reference>. <why the concern doesn't apply>.

**Info/minor acknowledged:**
> Noted. <brief response if warranted, or skip reply for purely informational comments>.

Keep replies short and direct. No "great catch" filler. Reference specific code locations.

### 6. Summary

After all replies, print a summary table:

```
| # | Source | Severity | Issue | Verdict | Action |
|---|--------|----------|-------|---------|--------|
| 1 | Bot    | Critical | ...   | Agreed  | Fixed  |
| 2 | Bot    | Warning  | ...   | Disagree| Replied|
| 3 | Human  | —        | ...   | Agreed  | Fixed  |
```

## Rules

- Never fix something you disagree with just because a bot flagged it
- Never dismiss a human comment without careful evaluation
- Read the actual code before forming an opinion — do not trust the comment's description of what the code does
- One commit for all fixes, not one per issue
- Run verification before pushing (lint, type-check, build)
- Do not reply to bot boilerplate (signatures, headers, "powered by" footers)
- If a bot review has both a summary comment and inline comments, only reply to inline comments — the summary is informational
