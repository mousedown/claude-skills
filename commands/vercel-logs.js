#!/usr/bin/env node

/**
 * Project-level Claude Code Command: Vercel Logs to GitHub Issues
 * Location: .claude/commands/vercel-logs.js
 *
 * Usage in Claude Code: /vercel-logs [project-name] [--since=1h] [--repo=owner/repo]
 */

const { Command } = require("commander");
const axios = require("axios");
const chalk = require("chalk");
const { format } = require("date-fns");
const path = require("path");
const fs = require("fs");

class VercelLogsToGitHub {
  constructor() {
    this.vercelToken = process.env.VERCEL_TOKEN;
    this.githubToken = process.env.GITHUB_TOKEN;
    this.githubRepo = process.env.GITHUB_REPO;

    // Try to read project config
    this.projectConfig = this.loadProjectConfig();

    if (!this.vercelToken) {
      throw new Error("VERCEL_TOKEN environment variable is required");
    }
    if (!this.githubToken) {
      throw new Error("GITHUB_TOKEN environment variable is required");
    }
  }

  loadProjectConfig() {
    try {
      const configPath = path.join(process.cwd(), ".claude", "config.json");
      if (fs.existsSync(configPath)) {
        const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
        return config.vercel || {};
      }
    } catch (error) {
      console.warn(
        chalk.yellow(`Warning: Could not load project config: ${error.message}`)
      );
    }
    return {};
  }

  getDefaultProjectName() {
    // Try to get project name from various sources
    const packageJsonPath = path.join(process.cwd(), "package.json");
    const vercelJsonPath = path.join(process.cwd(), "vercel.json");

    try {
      // Check vercel.json first
      if (fs.existsSync(vercelJsonPath)) {
        const vercelConfig = JSON.parse(
          fs.readFileSync(vercelJsonPath, "utf8")
        );
        if (vercelConfig.name) {
          return vercelConfig.name;
        }
      }

      // Check package.json
      if (fs.existsSync(packageJsonPath)) {
        const packageJson = JSON.parse(
          fs.readFileSync(packageJsonPath, "utf8")
        );
        if (packageJson.name) {
          return packageJson.name;
        }
      }

      // Use project config
      if (this.projectConfig.defaultProject) {
        return this.projectConfig.defaultProject;
      }

      // Use directory name as fallback
      return path.basename(process.cwd());
    } catch (error) {
      console.warn(
        chalk.yellow(
          `Warning: Could not determine default project name: ${error.message}`
        )
      );
      return null;
    }
  }

  getDefaultRepo() {
    try {
      const packageJsonPath = path.join(process.cwd(), "package.json");
      if (fs.existsSync(packageJsonPath)) {
        const packageJson = JSON.parse(
          fs.readFileSync(packageJsonPath, "utf8")
        );
        if (packageJson.repository) {
          let repo = packageJson.repository;
          if (typeof repo === "object" && repo.url) {
            repo = repo.url;
          }
          // Extract owner/repo from GitHub URL
          const match = repo.match(
            /github\.com[\/:]([^\/]+\/[^\/]+?)(?:\.git)?$/
          );
          if (match) {
            return match[1];
          }
        }
      }

      // Check project config
      if (this.projectConfig.defaultRepo) {
        return this.projectConfig.defaultRepo;
      }

      return this.githubRepo;
    } catch (error) {
      console.warn(
        chalk.yellow(
          `Warning: Could not determine default repository: ${error.message}`
        )
      );
      return this.githubRepo;
    }
  }

  async getVercelProjects() {
    try {
      const response = await axios.get("https://api.vercel.com/v9/projects", {
        headers: {
          Authorization: `Bearer ${this.vercelToken}`,
          "Content-Type": "application/json",
        },
      });
      return response.data.projects;
    } catch (error) {
      throw new Error(`Failed to fetch Vercel projects: ${error.message}`);
    }
  }

  async getProjectDeployments(projectId, since = "1h") {
    try {
      const sinceTimestamp = this.parseTimeAgo(since);
      const response = await axios.get(
        `https://api.vercel.com/v6/deployments`,
        {
          headers: {
            Authorization: `Bearer ${this.vercelToken}`,
            "Content-Type": "application/json",
          },
          params: {
            projectId: projectId,
            since: sinceTimestamp,
            limit: 20,
          },
        }
      );
      return response.data.deployments;
    } catch (error) {
      throw new Error(`Failed to fetch deployments: ${error.message}`);
    }
  }

  async getDeploymentLogs(deploymentId) {
    try {
      const response = await axios.get(
        `https://api.vercel.com/v2/deployments/${deploymentId}/events`,
        {
          headers: {
            Authorization: `Bearer ${this.vercelToken}`,
            "Content-Type": "application/json",
          },
        }
      );
      return response.data;
    } catch (error) {
      console.warn(
        chalk.yellow(
          `Warning: Could not fetch logs for deployment ${deploymentId}: ${error.message}`
        )
      );
      return [];
    }
  }

  parseTimeAgo(timeString) {
    const now = Date.now();
    const match = timeString.match(/^(\d+)([hmd])$/);

    if (!match) {
      throw new Error("Invalid time format. Use format like: 1h, 30m, 2d");
    }

    const value = parseInt(match[1]);
    const unit = match[2];

    let milliseconds;
    switch (unit) {
      case "m":
        milliseconds = value * 60 * 1000;
        break;
      case "h":
        milliseconds = value * 60 * 60 * 1000;
        break;
      case "d":
        milliseconds = value * 24 * 60 * 60 * 1000;
        break;
      default:
        throw new Error(
          "Invalid time unit. Use m (minutes), h (hours), or d (days)"
        );
    }

    return now - milliseconds;
  }

  extractErrors(logs) {
    const errors = [];

    for (const log of logs) {
      if (
        log.type === "stderr" ||
        log.type === "error" ||
        (log.payload && log.payload.level === "error")
      ) {
        errors.push({
          timestamp: log.created,
          message:
            log.payload?.text ||
            log.payload?.message ||
            log.text ||
            "Unknown error",
          type: log.type,
          source: log.payload?.source || "deployment",
          deploymentId: log.deploymentId,
        });
      }

      if (log.payload?.text) {
        const text = log.payload.text;
        if (
          text.includes("Error:") ||
          text.includes("ERROR") ||
          text.includes("Failed to") ||
          text.includes("Cannot")
        ) {
          errors.push({
            timestamp: log.created,
            message: text,
            type: "build_error",
            source: "build",
            deploymentId: log.deploymentId,
          });
        }
      }
    }

    return errors;
  }

  async createGitHubIssue(error, projectName, deploymentId) {
    const [owner, repo] = this.githubRepo.split("/");

    const title = `[${projectName}] ${error.type.toUpperCase()}: ${error.message.substring(
      0,
      100
    )}...`;
    const body = `
## Error Details

**Project:** ${projectName}
**Deployment ID:** ${deploymentId}
**Timestamp:** ${format(new Date(error.timestamp), "yyyy-MM-dd HH:mm:ss")}
**Error Type:** ${error.type}
**Source:** ${error.source}

## Error Message

\`\`\`
${error.message}
\`\`\`

## Deployment Link
https://vercel.com/dashboard/deployments/${deploymentId}

---
*This issue was automatically created by the Vercel Logs to GitHub Issues tool.*
`;

    try {
      const response = await axios.post(
        `https://api.github.com/repos/${owner}/${repo}/issues`,
        {
          title,
          body,
          labels: ["bug", "vercel", "auto-generated"],
        },
        {
          headers: {
            Authorization: `token ${this.githubToken}`,
            "Content-Type": "application/json",
            Accept: "application/vnd.github.v3+json",
          },
        }
      );

      return response.data;
    } catch (error) {
      throw new Error(`Failed to create GitHub issue: ${error.message}`);
    }
  }

  async checkExistingIssue(errorMessage, projectName) {
    const [owner, repo] = this.githubRepo.split("/");
    const searchQuery = `repo:${owner}/${repo} is:issue is:open "${projectName}" "${errorMessage.substring(
      0,
      50
    )}"`;

    try {
      const response = await axios.get("https://api.github.com/search/issues", {
        headers: {
          Authorization: `token ${this.githubToken}`,
          Accept: "application/vnd.github.v3+json",
        },
        params: {
          q: searchQuery,
        },
      });

      return response.data.total_count > 0;
    } catch (error) {
      console.warn(
        chalk.yellow(
          `Warning: Could not check existing issues: ${error.message}`
        )
      );
      return false;
    }
  }

  async run(projectName, options) {
    try {
      // Use default project name if not provided
      if (!projectName) {
        projectName = this.getDefaultProjectName();
        if (!projectName) {
          throw new Error(
            "Project name is required. Either provide it as an argument or configure it in .claude/config.json"
          );
        }
        console.log(chalk.blue(`📁 Using project: ${projectName}`));
      }

      // Use default repo if not provided
      const targetRepo = options.repo || this.getDefaultRepo();
      if (!targetRepo) {
        throw new Error(
          "GitHub repository must be specified either via --repo flag, GITHUB_REPO environment variable, or package.json"
        );
      }
      this.githubRepo = targetRepo;

      console.log(chalk.blue(`🔍 Fetching Vercel projects...`));

      const projects = await this.getVercelProjects();
      const project = projects.find((p) => p.name === projectName);

      if (!project) {
        throw new Error(
          `Project "${projectName}" not found. Available projects: ${projects
            .map((p) => p.name)
            .join(", ")}`
        );
      }

      console.log(
        chalk.green(`✅ Found project: ${project.name} (${project.id})`)
      );

      const since = options.since || "1h";

      console.log(
        chalk.blue(`🔍 Fetching deployments from the last ${since}...`)
      );

      const deployments = await this.getProjectDeployments(project.id, since);

      if (deployments.length === 0) {
        console.log(chalk.yellow(`No deployments found in the last ${since}`));
        return;
      }

      console.log(chalk.green(`✅ Found ${deployments.length} deployments`));

      let totalErrors = 0;
      let issuesCreated = 0;

      for (const deployment of deployments) {
        console.log(
          chalk.blue(`📋 Checking logs for deployment ${deployment.uid}...`)
        );

        const logs = await this.getDeploymentLogs(deployment.uid);
        const errors = this.extractErrors(logs);

        if (errors.length > 0) {
          console.log(
            chalk.red(
              `❌ Found ${errors.length} errors in deployment ${deployment.uid}`
            )
          );
          totalErrors += errors.length;

          for (const error of errors) {
            const existingIssue = await this.checkExistingIssue(
              error.message,
              projectName
            );

            if (existingIssue) {
              console.log(
                chalk.yellow(
                  `⚠️  Similar issue already exists for: ${error.message.substring(
                    0,
                    50
                  )}...`
                )
              );
              continue;
            }

            console.log(chalk.blue(`🐛 Creating GitHub issue for error...`));
            const issue = await this.createGitHubIssue(
              error,
              projectName,
              deployment.uid
            );

            console.log(chalk.green(`✅ Created issue: ${issue.html_url}`));
            issuesCreated++;
          }
        }
      }

      console.log(chalk.green(`\n🎉 Summary:`));
      console.log(chalk.green(`   📊 Total errors found: ${totalErrors}`));
      console.log(chalk.green(`   🐛 GitHub issues created: ${issuesCreated}`));
      console.log(chalk.green(`   📂 Repository: ${targetRepo}`));
    } catch (error) {
      console.error(chalk.red(`❌ Error: ${error.message}`));
      process.exit(1);
    }
  }
}

// CLI Setup
const program = new Command();

program
  .name("vercel-logs")
  .description("Read Vercel logs and create GitHub issues for errors")
  .argument(
    "[project-name]",
    "Vercel project name (auto-detected if not provided)"
  )
  .option("--since <time>", "Time range to check (e.g., 1h, 30m, 2d)", "1h")
  .option("--repo <repository>", "GitHub repository (owner/repo)")
  .action(async (projectName, options) => {
    try {
      const tool = new VercelLogsToGitHub();
      await tool.run(projectName, options);
    } catch (error) {
      console.error(chalk.red(`❌ Error: ${error.message}`));
      process.exit(1);
    }
  });

program.parse();
