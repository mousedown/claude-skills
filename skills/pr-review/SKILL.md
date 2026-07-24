---
name: pr-review
description: |
  Multi-agent PR review that replicates Claude Code's managed Code Review pipeline locally. Fans out parallel specialist subagents (correctness, security, regressions, conventions), adversarially verifies every candidate finding against actual code behaviour to filter false positives, then reports deduplicated findings ranked 🔴 Important / 🟡 Nit / 🟣 Pre-existing. Use when the user says "pr review", "review this PR", "review PR #123", "multi-agent review", "deep review", or "/pr-review". Accepts a PR number, branch name, ref range (main...feature), or file path; with no target it reviews the current branch's commits ahead of upstream plus uncommitted changes. Flags: --comment posts findings as inline PR comments, --fix applies Important fixes to the working tree.
---

# PR Review

Run a fleet of specialised review agents over a diff, verify their findings adversarially, and report only what survives — modelled on [Claude Code's Code Review](https://code.claude.com/docs/en/code-review) pipeline:

```
resolve target → parallel finders → verify candidates → dedupe + rank → report (→ comment / fix)
```

Findings never approve or block anything. The output is a ranked report; acting on it is the author's call.

## Step 1: Resolve the review target

Parse the argument after the skill name:

| Argument | Scope |
|---|---|
| _(none)_ | Commits ahead of upstream (`git log @{upstream}..HEAD`) plus staged and unstaged changes. If no upstream, diff against the default branch. |
| PR number (e.g. `123`, `#123`, PR URL) | `gh pr diff <n>` — also fetch `gh pr view <n> --json title,body,commits` for intent |
| Branch name | `git diff <default-branch>...<branch>` |
| Ref range (e.g. `main...feature`) | `git diff <range>` |
| File path | Review that file in full |

Strip `--comment` and `--fix` flags before parsing the target. `--comment` requires a PR target — if there is none, say so and continue as a plain review.

Then gather context to hand to every agent:

- The diff itself, plus the list of changed files
- PR title/body or recent commit messages (author intent)
- The repository's `CLAUDE.md` files (project conventions)
- `REVIEW.md` at the repo root, if present — its contents are **highest-priority review instructions**: paste them verbatim at the top of every agent prompt in Steps 2 and 3, above the default guidance

If the diff is empty, report "nothing to review" and stop.

## Step 2: Launch the finder fleet

Dispatch all finders **in a single message** so they run in parallel. Each agent hunts a different class of issue in the same diff. Use these agent types, falling back to `general-purpose` with the same prompt if a named agent is not installed:

| Finder | Agent type | Hunts for |
|---|---|---|
| Correctness | `code-reviewer` | Logic errors, broken edge cases, race conditions, null/undefined access, incorrect async usage, missing error handling |
| Security | `nadia-security-auditor` | Injection, authn/authz gaps, tenant isolation, secrets or PII exposure, unsafe input handling |
| Regressions | `general-purpose` | Behaviour changes that break existing callers: search the codebase for call sites of changed functions/APIs and check each still holds; breaking contract changes; subtle semantic drift |
| Conventions | `general-purpose` | Newly introduced violations of `CLAUDE.md` rules, and the reverse — code changes that make a `CLAUDE.md` or doc statement outdated (flag the doc drift too) |

Every finder prompt must include: the REVIEW.md block (if any), the diff, the intent context, an instruction to read surrounding code in the repo rather than judge the diff in isolation, and this required return format:

```
FINDING
file: <path>:<line>
severity: important | nit | pre-existing
title: <one line>
detail: <what is wrong and why it matters>
evidence: <file:line citations from the actual code that support the claim>
suggested_fix: <specific change, or "none">
```

Finder ground rules (include in each prompt):

- Focus on correctness — bugs that would break behaviour in production, not formatting, naming, or style preferences
- `pre-existing` means a real bug touched by or adjacent to the diff but not introduced by it
- Behaviour claims need a `file:line` citation in real code, not an inference from a name
- Return `NO FINDINGS` when there is nothing worth reporting — do not manufacture findings
- `CLAUDE.md` violations are `nit` severity unless REVIEW.md says otherwise

## Step 3: Verify candidates

Collect all candidate findings. If there are none, skip to Step 4.

Dispatch a verification agent — `ada-devils-advocate` (fall back to `general-purpose`) — with the full candidate list, the diff, and the REVIEW.md block. Its job is to **refute** each finding:

- Read the actual code at each cited location; confirm the claimed behaviour is real and reachable
- Check the "bug" isn't already handled by a guard, caller contract, test, or framework behaviour elsewhere
- Check duplicates: findings from different finders describing the same root cause
- Verdict per finding: `CONFIRMED` (with one-line proof), `REJECTED` (with the reason), or `DUPLICATE-OF <n>`
- When genuinely uncertain, reject — a missed nit costs less than a false positive that burns the author's time

If there are more than ~15 candidates, split them across parallel verification agents in one message.

Only `CONFIRMED` findings survive. Merge duplicates, keeping the clearest write-up and the union of evidence.

## Step 4: Report

Rank survivors: Important first, then Nit, then Pre-existing. Open with a one-line tally, then a summary table, then details:

```markdown
## PR Review: <target>

**2 important, 1 nit, 1 pre-existing** — reviewed <n> files, <m> candidate findings, <k> rejected in verification.

| Severity | File:Line | Issue |
|---|---|---|
| 🔴 Important | `src/auth/session.ts:142` | Token refresh races with logout, leaving stale sessions active |
| 🟡 Nit | `src/auth/session.ts:88` | `parseExpiry` silently returns 0 on malformed input |
| 🟣 Pre-existing | `src/db/users.ts:51` | Query unscoped to tenant (predates this PR) |

### 🔴 src/auth/session.ts:142 — <title>
<detail, evidence citations, suggested fix>

<details><summary>Why this was flagged</summary>
<finder reasoning + verification proof>
</details>
```

Severity meanings (keep calibration unless REVIEW.md overrides):

| Marker | Severity | Meaning |
|---|---|---|
| 🔴 | Important | A bug that should be fixed before merging |
| 🟡 | Nit | Worth fixing, not blocking — cap at 5; summarise the rest as "plus N similar" |
| 🟣 | Pre-existing | A real bug in the codebase not introduced by this change |

If nothing survives verification, lead with **"No issues found"** and one sentence on what was checked.

## Step 5: Act on flags

**`--comment`** — post the findings to the PR:

```bash
gh pr review <n> --comment --body "<summary + severity table>"
gh api repos/{owner}/{repo}/pulls/<n>/comments \
  -f body="<finding detail>" -f commit_id="<head-sha>" -f path="<file>" -F line=<line> -f side=RIGHT
```

Inline-comment each finding on its diff line; findings on lines outside the diff go under an **Additional findings** heading in the review body instead. Never approve or request changes — comment only.

**`--fix`** — after reporting, apply the suggested fixes for 🔴 Important findings to the working tree (Nits and Pre-existing only when the fix is trivial and local). List exactly what was changed. Do not commit.

## Guardrails

- Do not flag style, formatting, import order, or anything a linter/CI already enforces
- Do not suggest rewrites of working code or speculative refactors
- Skip generated files, lockfiles, and vendored dependencies unless REVIEW.md says otherwise
- On a re-review of the same PR, suppress new nits — report Important findings only
