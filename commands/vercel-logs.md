# Vercel Logs to GitHub Issues

Read Vercel deployment logs for a project and create GitHub issues for any errors found.

## Usage

```bash
/vercel-logs [project-name] [--since=1h] [--repo=owner/repo]
```

## Arguments

- `project-name` (optional): Name of the Vercel project. If not provided, will auto-detect from current directory
- `--since` (optional): Time range to check (e.g., 30m, 1h, 2h, 6h, 1d). Default: 1h
- `--repo` (optional): GitHub repository in format owner/repo. Will auto-detect from package.json if not provided

## Examples

```bash
# Auto-detect project and check last hour
/vercel-logs

# Check specific project for last 2 hours
/vercel-logs my-nextjs-app --since=2h

# Custom repo and time range
/vercel-logs my-app --since=30m --repo=myorg/myrepo
```

## Environment Variables Required

- `VERCEL_TOKEN`: Your Vercel API token
- `GITHUB_TOKEN`: Your GitHub personal access token
- `GITHUB_REPO` (optional): Default GitHub repository

## Script

```javascript
#!/usr/bin/env node
require("./vercel-logs.js");
```
