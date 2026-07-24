---
name: update-pr-description
description: |
  Analyse all changes on the current branch compared to the PR's base branch and update the GitHub PR title and body. Preserves user-added content (images, screenshots, HTML). Use when the user says "update pr", "update the pr", "sync pr description", or "/update-pr-description".
allowed-tools:
    - Bash(git *)
    - Bash(gh *)
    - Read
---

# Update PR

Analyse the current branch's unique changes, generate a comprehensive PR description, and update the GitHub PR — preserving any manually-added content in the existing body.

## Workflow

### 1. Find the PR and its base branch

Find the PR for the current branch and extract the base branch — do NOT assume `main` or `master`.

```bash
gh pr view --json number,title,body,url,baseRefName,headRefName
```

If no PR exists, stop and tell the user.

### 2. Fetch the base branch

Fetch the PR's base branch from origin — never rely on the local copy.

```bash
git fetch origin <baseRefName>
```

### 3. Find the merge base

Identify the common ancestor between the branch and the base. This is the point where the branch diverged — it ignores any commits added to the base branch after the branch was created or last merged.

```bash
git merge-base origin/<baseRefName> HEAD
```

This returns a single commit SHA — the last shared commit. All diffs and logs should be computed relative to this SHA, not relative to the remote branch tip.

### 4. Gather branch changes

Use the merge-base SHA from step 3 for all comparisons:

```bash
# Store the merge base
MERGE_BASE=$(git merge-base origin/<baseRefName> HEAD)

# Commits unique to this branch (excluding merges)
git log ${MERGE_BASE}..HEAD --oneline --no-merges

# Diff stat — what this branch introduces
git diff ${MERGE_BASE}..HEAD --stat

# Full diff for analysis
git diff ${MERGE_BASE}..HEAD
```

**Why merge-base, not three-dot diff?** The three-dot diff (`A...B`) computes the merge-base internally, but can produce confusing results when the base branch has been merged into the feature branch (a common pattern). By computing the merge-base explicitly, we get a clear picture: "everything on this branch since it forked from base" — which is exactly what the PR will show on GitHub.

### 5. Preserve existing user content

Before generating new content, scan the existing PR body for content that was added manually and must be preserved:

- **Images and screenshots**: `<img ...>`, `![...](...)`, GitHub asset URLs (`https://github.com/user-attachments/assets/...`)
- **HTML blocks**: `<details>`, `<video>`, `<picture>`, or other raw HTML the user embedded
- **User-added sections**: Any section not matching the template structure (e.g. a "Screenshots" or "Demo" section added by the user)
- **Issue-tracker banners or callouts**: e.g. "Closes #123", warning banners, reviewer callouts

Collect these into a `preserved_content` list. They will be re-inserted into the new body in step 7.

### 6. Analyse changes and draft PR content

Group changes by area/concern. For each group, summarise:
- **What** changed (files, resources, functions)
- **Why** it changed (intent behind the commit)

Draft:
- **Title**: Short (under 70 chars), describes the overall change. Follow conventional commit format if the repo uses it (`feat:`, `fix:`, `chore:`, etc.)
- **Body**: Use the template below, then **re-insert preserved content** from step 5:
  - Images/screenshots: place in a `## Screenshots` section above the test plan
  - HTML blocks: place in the section they originally appeared in, or in a `## Media` section
  - Issue-tracker banners: place at the very top of the body
  - Other user sections: preserve in their original position relative to Summary/Test plan

### 7. Detect linked issue keys

Look for issue keys in the branch name, existing PR title/body, and commit messages. Detect both:
- **GitHub references**: `#123`, `Closes #123`, `Fixes #123`
- **Jira-style keys**: `[A-Z]+-\d+` (e.g. `PROJ-456`, `ABC-789`)

If found, mention them in the PR body under a `## Related` section — but do NOT attempt to auto-update external trackers. Surface the references for the user to review.

### 8. Update the PR immediately

Do NOT ask for confirmation before editing the GitHub PR — update the PR straight away.

```bash
gh pr edit {number} --title "{title}" --body "$(cat <<'EOF'
{body with preserved content re-inserted}
EOF
)"
```

## PR Body Template

```markdown
## Summary
{1-5 bullet points covering the high-level changes}

{For each logical group of changes, add a subsection:}

### {Group name}
- {detail}
- {detail}

## Test plan
- [ ] {verification step}
- [ ] {verification step}

## Related
{Linked issue keys, if any — e.g. "Closes #123" or "PROJ-456"}
```

## Error Handling

- **No PR found**: Tell the user no PR exists for this branch and stop
- **Fetch fails**: Retry the fetch once; if it still fails, report a clear error (including the failing command and stderr)
- **No merge base found**: The branch has no common ancestor with the base — this is unusual. Report the error
- **No commits since merge base**: Tell the user the branch has no unique changes
- **gh command fails**: Report the error clearly

## Notes

- **Never discard existing content** — images, screenshots, HTML blocks, and user-added sections in the PR body must survive updates. The body is an upsert, not a replace.
- Always determine the base branch from the PR metadata — never hardcode `main` or `master`
- Always fetch the base branch from origin before computing the merge-base
- Use explicit `git merge-base` rather than three-dot diff to handle branches that have merged the base into themselves
- The diff can be large — focus on understanding intent from commit messages and key file changes rather than reading every line
- If the diff is too large to read at once, read it in chunks or focus on the stat + commit messages
- Do NOT add Claude/AI attribution footers — the user's preference is for commits and PRs to appear as authored by them
