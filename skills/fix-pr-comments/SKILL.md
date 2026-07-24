---
name: fix-pr-comments
description: |
  Review and action all comments on a GitHub PR. Investigates each issue, presents a plan, gets user approval, implements fixes, replies to comments, and resolves them. Use when the user says "action pr comments", "fix pr feedback", "address pr comments", "review pr comments", or "/fix-pr-comments".
allowed-tools:
    - Bash(gh *)
    - Bash(git *)
    - Bash(npm *)
    - Bash(pnpm *)
    - Bash(bun *)
    - Bash(yarn *)
    - Bash(cd *)
    - Read
    - Write
    - Edit
    - Glob
    - Grep
    - Agent
---

# Action PR Comments

Review all comments on a GitHub PR, investigate each issue, present a fix plan to the user for approval, implement the fixes, reply to each comment explaining what was done, and resolve the threads.

## Arguments

The user may provide:
- A PR number (e.g. `123`)
- A PR URL (e.g. `https://github.com/org/repo/pull/123`)
- Nothing — in which case, find the PR for the current branch

## Workflow

### 1. Find the PR

If the user provided a PR number or URL, use that as the selector. Otherwise, omit the selector to find the PR for the current branch:

```bash
gh pr view {selector} --json number,url,title,headRefName,baseRefName
```

If no PR exists, stop and tell the user.

### 2. Fetch all review comments

```bash
gh api repos/:owner/:repo/pulls/{number}/comments --paginate --jq '.[] | {id: .id, node_id: .node_id, path: .path, line: (.line // .original_line), author: .user.login, body: .body, in_reply_to_id: .in_reply_to_id}'
```

Also fetch review threads so you can resolve them later:

```bash
gh api graphql -f query='query { repository(owner: "{owner}", name: "{repo}") { pullRequest(number: {number}) { reviewThreads(first: 100) { nodes { id isResolved comments(first: 1) { nodes { id databaseId } } } } } } }'
```

Filter out:
- Comments that are replies to other comments (have `in_reply_to_id`) — these are conversation replies, not top-level review items
- Comments authored by the current user (already addressed)

If there are no remaining top-level comments after this filtering, tell the user and stop.

### 3. Investigate each comment

For each comment:
1. Read the file at the specified path and line to understand context
2. Determine if the comment is:
   - **Actionable**: A bug, improvement, or code change that should be implemented
   - **Informational**: A question, suggestion, or observation that needs a response but no code change
   - **Already fixed**: The issue has already been resolved in the current code
3. For actionable items, determine the specific fix needed

### 4. Present the plan

Present a numbered plan to the user in this format:

```
## PR Comment Action Plan

**PR**: #{number} - {title}
**Comments**: {count} actionable, {count} informational, {count} already fixed

### Fixes to implement

1. **{file}:{line}** — {summary of fix}
   > {abbreviated comment}

2. **{file}:{line}** — {summary of fix}
   > {abbreviated comment}

### Already resolved

3. **{file}:{line}** — {explanation of why it's already fixed}
   > {abbreviated comment}

### Informational (reply only)

4. **{file}:{line}** — {proposed reply}
   > {abbreviated comment}
```

### 5. Get user approval

Ask the user to:
- **Accept** the plan as-is
- **Reject** the plan (and explain what to change)
- **Accept with notes** (add modifications to specific items)

Wait for the user's response. Do NOT proceed without explicit approval.

### 6. Implement fixes

For each approved actionable fix:
1. Make the code change
2. Run linting on the changed file using the project's linter. Detect by:
   - Reading `package.json` for a `lint` script, then running the package-manager-appropriate command (e.g. `bun run lint`, `pnpm lint`, `npm run lint`)
   - Or, if the repo uses a specific linter directly (`eslint`, `oxlint`, `biome`, `ruff`), invoke it against the changed files
   - If unsure, ask the user which lint command to use
3. If lint fails, fix the issue before moving on

After all fixes are implemented:
1. Run the full lint check on affected directories
2. Run type checking if applicable (e.g. `bun run type-check`, `pnpm typecheck`, `tsc --noEmit`)
3. Stage and commit the changes with a descriptive message

### 7. Reply to comments and resolve

For each comment (actionable, already fixed, or informational):

**Reply** with what was done:
```bash
gh api repos/:owner/:repo/pulls/{number}/comments/{id}/replies -f body="{reply}"
```

**Resolve** the review thread (use the thread ID from the reviewThreads query in step 2, matched by the comment's databaseId):
```bash
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "{thread_id}"}) { thread { isResolved } } }'
```

Reply guidelines:
- For fixes: "Fixed — {brief description of what changed}"
- For already resolved: "Already resolved — {brief explanation}"
- For informational: A thoughtful response to the comment
- For acknowledged (won't fix now): "Acknowledged — {reason this will be addressed later}"

### 8. Push changes

```bash
git push
```

Report the final summary to the user.

## Error Handling

- **No PR found**: Tell the user and stop
- **No comments**: Tell the user the PR has no review comments
- **gh API failures**: Report the error clearly, suggest the user check their GitHub auth
- **Lint/type failures after fixes**: Report them and ask the user how to proceed
- **Comment reply fails**: Log the failure and continue with remaining comments

## Notes

- Never implement fixes without user approval
- Group related comments that affect the same file/function into a single fix when possible
- If a comment suggests an approach that conflicts with the existing codebase patterns, note this in the plan
- Prefer minimal, focused fixes — don't refactor surrounding code unless the comment specifically requests it
- If the same issue is flagged by multiple comments, deduplicate in the plan
- Always check if the issue has already been fixed before proposing a change
