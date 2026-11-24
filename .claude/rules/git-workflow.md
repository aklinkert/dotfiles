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
- The rules above (default and allowlist) cover PRs opened by our shared git identity, the PRs agents open. They do not cover Renovate PRs.

## Renovate PRs (author `app/renovate`)

Decided by Alex on 2026-11-23. Applies on every host and in every org, allowlisted or not. "The sweep" means any org-level bot that merges Renovate PRs, where one exists.

- **Renovate or a Renovate merge sweep merges first.** Leave a PR alone while one of them will merge it: Renovate automerge is on and the PR is green, or the sweep's only refusals are temporary (`too_new`, fanout soak, `blocked_by_policy`, a pending merge state).
- **We merge only as fallback**, in two cases:
  1. a major version bump, or
  2. the sweep refuses the PR permanently and Renovate's automerge will not merge it either (automerge off, or on but stuck).
- Fallback merges follow the renovate-review skill: a `MERGE` verdict from step 3 (green, confined, no breaking change that touches the repo), approve, then merge pinned to the reviewed head SHA.
- Terraform PRs need a "No changes" plan for the reviewed head, or the change in the plan must be the intended one.
- Give Renovate and the sweep their chance first: no fallback merge of a PR younger than the sweep's 24h PR-age floor.
- Never merge with failing required checks, and never use `--admin` or another bypass. A red PR gets a fix, not a merge.
- Onboarding ("Configure Renovate") PRs stay with the repo owner. The sweep's onboarding opt-in gate exists for the owner's consent.
