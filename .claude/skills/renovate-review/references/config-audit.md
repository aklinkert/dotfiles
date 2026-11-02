# Renovate config audit

Judge the config by what it produced: the PR stream, the review results of this run and the repo's merge policy. A rule earns a finding only when the data shows its cost or a risk.

## 1. Gather

```sh
bash scripts/config-stats.sh <owner/repo>
```

It prints the config file, PR volume (30/90 days), time to merge, closed-unmerged count, most frequent deps, the Dependency Dashboard, merge settings and branch protection. Resolve every preset in `extends`: a `local>` or `github>` preset is a file in another repo (`gh api repos/<o>/<r>/contents/<path>`); read it, because the effective config is the merge of all of them. Check the configured Renovate is current: `npx --yes renovate-config-validator --strict <file>` (or the version the repo pins) flags migrated options.

## 2. Check each area

For each area: what the data shows, the target, the fix.

### Baseline

- Target: `extends` includes `config:best-practices` (or `config:recommended` plus explicit digest pinning). It brings `group:monorepos`, `group:recommended`, `:configMigration`, digest pins for actions and Docker images.
- `:dependencyDashboard` on: one place to see pending, rate-limited and errored updates. A dashboard listing config errors or "abandoned" deps is a finding of its own.
- Deprecated option names (`stabilityDays`, `regexManagers`, `matchPaths`, `matchPackagePatterns`, `baseBranches` misuse): migrate.

### Grouping

Noise signal: more than ~5 PRs per week per repo, the same dep in the top-10 list every week, or several PRs touching one manifest at once (each merge rebases the rest and re-runs CI).

- Group non-major updates per ecosystem or layer (`matchManagers` / `matchFileNames` + `groupName`), e.g. "GitHub Actions", "Go modules", "Helm charts", "Terraform providers". `group:allNonMajor` only for small repos with fast, trustworthy CI.
- Keep separate: majors (`separateMajorMinor`, default on), anything the repo's merge policy treats as disruptive (CNI, ingress, database operators, cluster version), and anything with a companion pin (below). A group automerges only when every member may, so one manual-merge member blocks the whole group: keep automerge-eligible and manual-merge deps in different groups.
- Monorepo families (k8s.io/*, @aws-sdk/*, opentelemetry) grouped; `group:monorepos` covers the known ones, add `matchPackageNames` groups for the rest.

### Frequency

- `schedule` set (e.g. `schedule:weekly` or `["before 6am on monday"]`) with `timezone`. Without one, Renovate opens PRs on every run.
- Schedule placed before the team's working week and away from deploy windows the repo documents (scheduled applies, maintenance jobs).
- `lockFileMaintenance` enabled where lockfiles exist, on its own (monthly or weekly) schedule.
- `vulnerabilityAlerts` / `osvVulnerabilityAlerts` on: security fixes bypass the schedule and need a label (`security`).
- `prConcurrentLimit` / `prHourlyLimit` sized to review capacity: open PRs older than 30 days or a dashboard full of rate-limited items means the limit or the grouping is wrong.

### Safety

- `minimumReleaseAge` (e.g. `"3 days"` for automerged, `"7 days"` for infra) with `internalChecksFilter: "strict"`, so a pulled release never lands. Datasources without timestamps need `minimumReleaseAgeBehaviour` decided explicitly.
- Automerge only minor/patch/digest/pin of deps whose CI actually exercises them; majors never. `platformAutomerge: true` needs required status checks in branch protection, else it merges untested. Merge time far above the schedule interval for automerge-eligible PRs means automerge is not firing (missing required check, review rule, `automergeSchedule`).
- Paths whose merge deploys to production get a label (e.g. `manual-merge`) and `automerge: false` via `matchFileNames`.
- Every pinned version Renovate cannot see (versions in scripts, workflow `run:` blocks, Dockerfile `ARG`s, Makefiles) has a `customManagers` regex entry with a `# renovate:` comment, so nothing drifts silently.

### Companion pins

A version next to a hand-maintained checksum (`sha256=`, `--hash=`, checksum file) is bumped by Renovate alone and the PR goes red on the checksum. Fix options, best first:

1. Let the install script fetch the release's own checksum file for the pinned version and verify against it, keeping only the version as the pin (weaker trust: same origin) or pin the checksum file's digest.
2. Self-hosted Renovate: `postUpgradeTasks` that recomputes the hash (needs `allowedCommands`; the hosted Mend app does not run them).
3. Otherwise: a `packageRules` entry for those deps with `automerge: false`, a label and `prBodyNotes` naming the file and the command that produces the new hash.

### Rebase churn

- `rebaseWhen: "conflicted"` when branch protection does not require up-to-date branches (classic `strict: false`, no ruleset requiring it): fewer CI re-runs after each merge. Keep `"behind-base-branch"` / `"auto"` when it does.
- `branchConcurrentLimit` and grouping reduce churn more than any rebase setting.

### Hygiene

- `labels` (e.g. `dependencies`) and `semanticCommits` matching the repo's commit convention.
- `ignorePaths` for fixtures, examples and vendored code; `ignoreDeps` entries carry a comment saying why.
- Closed-unmerged PRs above ~20 % of created: find the deps and either fix what blocks them or ignore them deliberately (`enabled: false` with a reason, or `allowedVersions`).

## 3. Report

Per finding: area, evidence (numbers from `config-stats.sh` or a PR URL from this run), impact, fix. Then one proposed config diff covering all fixes, validated with `renovate-config-validator --strict`. Order: safety first, then noise (grouping, frequency), then hygiene. When the user asks to apply it, open a PR on a new branch with the diff and the evidence in the body.
