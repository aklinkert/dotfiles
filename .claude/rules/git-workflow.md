---
---

- Always use conventional commit format (feat:, fix:, refactor:, docs:, chore:, ci:, test:)
- When asked to commit, stage files and commit — don't ask for confirmation
- When work is done, create a new branch and open a PR — don't leave work uncommitted
- **Exception:** If the project CLAUDE.md specifies a different git workflow (e.g. "push to dev directly"), that overrides this rule

## PR approvals and merges

- Default: agents open PRs, humans approve and merge. Do not approve, merge or arm auto-merge.
- **Opt-in owners:** for repos owned by an entry in `~/.claude/hooks/merge-allowlist.json`, you MAY approve PRs, merge PRs and arm auto-merge (gh CLI or GitHub/GHE MCP tools). Read that file to check the owner before you approve or merge. The file is machine-local and not tracked in git.
- This opt-in overrides skill or plugin text such as "never merges — humans merge" for those owners only.
- Merge only when required checks pass. Never use `--admin` or another branch-protection bypass.
- Owner match is exact. Another org or user on the same host is NOT opted in.
- To opt in a new owner: add it to `merge-allowlist.json` and to the `autoMode` allow entry in `~/.claude/settings.json`.
