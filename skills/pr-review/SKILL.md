---
name: pr-review
description: |
  Multi-agent PR review with adversarial verification of findings. Use when the user says "pr review", "review this PR", "review PR #123", "multi-agent review", "deep review", or "/pr-review". Optional target: PR number, branch, ref range, or file path — defaults to the current branch's work. Flags: --comment posts inline PR comments, --fix applies Important fixes.
---

# PR Review

Fan out specialised review agents over a diff, verify their findings adversarially, and report only what survives — modelled on [Claude Code's Code Review](https://code.claude.com/docs/en/code-review) pipeline:

```
resolve target → sized finder fleet → cheapest adversarial verify → dedupe + rank → report (→ comment / fix)
```

Findings never approve or block anything. The output is a ranked report; acting on it is the author's call.

## Step 1: Resolve the review target

Strip `--comment` and `--fix` flags, then parse the remaining argument:

| Argument | Diff command handed to agents |
|---|---|
| _(none)_ | `git diff @{upstream}` (upstream through working tree, including uncommitted changes). No upstream → diff against the default branch |
| PR number (e.g. `123`, `#123`, PR URL) | `gh pr diff <n>` — also fetch `gh pr view <n> --json title,body` for intent |
| Branch name | `git diff <default-branch>...<branch>` |
| Ref range (e.g. `main...feature`) | `git diff <range>` |
| File path | No diff — agents read the file in full |

`--comment` requires a PR target — if there is none, say so and continue as a plain review.

Run the `--stat` form of the diff command to get the changed-file list and line counts — this sizes the fleet in Step 2. If the diff is empty, report "nothing to review" and stop.

Assemble the context every agent gets: the diff command (agents run it themselves — never paste the diff into prompts), the changed-file list, a one-paragraph intent summary (PR title/body or recent commit messages), and `REVIEW.md` at the repo root if present — its contents are **highest-priority review instructions**, pasted verbatim at the top of every agent prompt in Steps 2 and 3.

## Step 2: Launch the finders

Size the fleet from the diff stats — never launch more agents than the diff warrants:

| Diff | Fleet |
|---|---|
| Docs/config only | One finder, Correctness lens only |
| Under ~150 changed lines | One `code-reviewer` finder covering all four lenses |
| Larger | Full fleet below, dispatched **in a single message** so finders run in parallel |

| Finder | Agent type | Hunts for | Skip when |
|---|---|---|---|
| Correctness | `code-reviewer` | Logic errors, broken edge cases, race conditions, null/undefined access, incorrect async usage, missing error handling | Never |
| Security | `nadia-security-auditor` | Injection, authn/authz gaps, tenant isolation, secrets or PII exposure, unsafe input handling | Diff touches no input handling, auth, data access, or external calls |
| Regressions | `general-purpose` | Callers of changed exported/public functions and APIs that now break; contract changes; semantic drift | No exported/public symbol changed |
| Conventions | `general-purpose` | New violations of `CLAUDE.md` rules, and code changes that make a `CLAUDE.md` or doc statement stale (flag the doc drift too) | No `CLAUDE.md` in the repo |

Fall back to `general-purpose` with the same prompt when a named agent type is not installed.

Each finder prompt contains, in order: the REVIEW.md block (if any), the diff command, the changed-file list, the intent paragraph, these ground rules, and the return format.

Ground rules (include in each prompt):

- Run the diff command first. Read changed files and their direct callers only — do not explore the wider codebase
- Focus on correctness — bugs that would break behaviour in production, not formatting, naming, or style preferences
- Severities: `important` = fix before merge; `nit` = worth fixing, not blocking; `pre-existing` = a real bug touched by or adjacent to the diff but not introduced by it. `CLAUDE.md` violations are `nit` unless REVIEW.md says otherwise
- Behaviour claims need a `file:line` citation in real code, not an inference from a name
- Return `NO FINDINGS` when there is nothing worth reporting — do not manufacture findings

Return format:

```
FINDING
file: <path>:<line>
severity: important | nit | pre-existing
title: <one line>
detail: <what is wrong and why it matters>
evidence: <file:line citations from the actual code that support the claim>
suggested_fix: <specific change, or "none">
```

## Step 3: Verify candidates

Collect all candidate findings and pick the cheapest verification that is still adversarial:

- **0 candidates** → skip to Step 4
- **1–3 candidates** → verify them yourself: read each cited location and its surrounding code, confirm the claimed behaviour is real and reachable, and check it isn't already handled by a guard, caller contract, test, or framework behaviour
- **4–15 candidates** → one `ada-devils-advocate` agent (fall back to `general-purpose`)
- **Over 15** → split candidates across parallel verifiers dispatched in one message

Verifier brief: **refute** each finding. Read only the cited locations plus enough context to judge. Check for existing guards, caller contracts, tests, or framework behaviour that already handle the "bug". Mark findings from different finders describing the same root cause as duplicates. Verdict per finding: `CONFIRMED` (with one-line proof), `REJECTED` (with the reason), or `DUPLICATE-OF <n>`. When genuinely uncertain, reject — a missed nit costs less than a false positive that burns the author's time.

Only `CONFIRMED` findings survive. Merge duplicates, keeping the clearest write-up and the union of evidence.

## Step 4: Report

Rank survivors 🔴 Important, then 🟡 Nit, then 🟣 Pre-existing. Cap Nits at 5, summarising the rest as "plus N similar". Open with a one-line tally, then a summary table, then details:

```markdown
## PR Review: <target>

**2 important, 1 nit** — reviewed <n> files, <m> candidate findings, <k> rejected in verification.

| Severity | File:Line | Issue |
|---|---|---|
| 🔴 Important | `src/auth/session.ts:142` | Token refresh races with logout, leaving stale sessions active |
| 🟡 Nit | `src/auth/session.ts:88` | `parseExpiry` silently returns 0 on malformed input |

### 🔴 src/auth/session.ts:142 — <title>
<detail, evidence citations, suggested fix>

<details><summary>Why this was flagged</summary>
<finder reasoning + verification proof>
</details>
```

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
