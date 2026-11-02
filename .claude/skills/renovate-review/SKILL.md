---
name: renovate-review
description: Review open Renovate PRs in any GitHub org or repo, say which can be merged without issues, and on request comment, approve and merge them; also audits the repo's Renovate config (grouping, schedule, update frequency, automerge). Use for "check the renovate PRs", "can these dependency PRs be merged", "merge the renovate PRs", "review/optimize the renovate config", or /renovate-review.
---

# Renovate review

Review every open Renovate PR in scope, give each a **verdict**, act only as far as the user asked, then audit the Renovate config that produced them.

Scripts live in `~/.claude/skills/renovate-review/scripts/`; `scripts/x.sh` below means that path. Call each as a plain `bash <script> <args>`. Work from their output; do not re-query GitHub per field. Set `GH_HOST=<host>` for GitHub Enterprise; github.com needs nothing. `$SCRATCH` is the session scratchpad directory.

## Modes

Read the mode from the user's words:

- **review** (default): report only. Nothing is written to GitHub.
- **comment**: post the analysis on every PR in scope.
- **approve**: approve every `MERGE` verdict.
- **merge**: merge every `MERGE` verdict. "Merge them" implies approve.

A mode applies to this request only. A later request that names fewer modes gets fewer.

## Verdicts

- `MERGE`: safe now. Green, confined, no breaking change that touches this repo.
- `MANUAL (<check>)`: green, but a named human check must run first (a plan, a dry run, a canary).
- `BLOCKED (<reason>)`: cannot merge as is: red check, conflict, draft, foreign commit, breaking change.
- `SKIP (<reason>)`: someone else merges it: Renovate automerge enabled and green, or already merged/closed.

Doubt is `MANUAL`, never `MERGE`.

## 1. Learn the repo's merge policy

Read the repo's `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` and the workflows that run on push to the default branch. Record:

- what a merge triggers (deploy, `terraform apply`, provisioning against production);
- labels that forbid automation (`manual-merge`, `do-not-merge`, `hold`) and what they require;
- pins that need a hand-bumped checksum or lock next to the version (`sha256`, `--hash=`, `.terraform.lock.hcl`);
- updates the repo says must be done out of band (cluster upgrades, CNI changes, schema migrations).

Done when every one of these four is answered "none" or named with its file.

## 2. List and bucket

```sh
bash scripts/list-prs.sh <owner | owner/repo | pr-url> ... > "$SCRATCH/prs.jsonl"
```

An unknown `owner/repo` yields zero lines, not an error: confirm the name before reporting "no PRs". For each PR, first match wins:

1. Draft, conflict (`mergeable == CONFLICTING`), hold label, `changes requested`, `foreignCommitAuthors` non-empty, `filesTruncated` or `commitsTruncated` → `BLOCKED`.
2. `checks.failing` non-empty → `BLOCKED`. Run `bash scripts/failed-logs.sh <url>` and name the root cause, not the job (e.g. "sha256 not bumped with version", "asdf 0.16 removed asdf.sh").
3. `checks.pending` non-empty → note "checks running"; decide after `wait-checks.sh` (step 5).
4. `automerge == true` and green → `SKIP (Renovate automerges)`.
5. Everything else → review (step 3).

## 3. Review each candidate

Run `bash scripts/pr-diff.sh <url>` and read the release notes in the PR body. For every dependency name manager, from → to, update type. The diff is authoritative over the title.

- **Confinement**: every changed file belongs to the dependency's manager (manifest, lockfile, workflow, Dockerfile, version-pin script). An unrelated file → `BLOCKED (unconfined <file>)`.
- **Companion pins**: a version bumped beside an unchanged checksum, hash lock or provider lock → `BLOCKED (<file>: hash not bumped)`, even while CI is still pending.
- **Update type**: the diff decides. A tag that changes distro, libc or runtime major is a major. Several minors at once (e.g. 2.19 → 2.21) gets the same scrutiny as a major.
- **Breaking changes**: for each one in the release notes, grep the repo at the PR head for the affected API, flag, config key or path. Usage that no green CI job exercises → `BLOCKED` or `MANUAL`, naming `file:line`.
- **Blast radius**: from step 1. A merge that applies to production and restarts or reconciles something cluster-wide (CNI, ingress, provisioning tool minor) is `MERGE` only when its apply is routine; otherwise `MANUAL (<dry run / plan to run>)`. Updates the repo says need out-of-band steps are `MANUAL` by definition.
- **Tool and action majors** that hold credentials (deploy, release, auth): the changelog shows no change to inputs, permissions or token handling, else `MANUAL`.

Done when every candidate has a verdict and a one-line reason that names a file, check or release-note item.

## 4. Report

One table, every PR in scope, full URLs (`https://<host>/<owner>/<repo>/pull/<n>`, never `#n`):

| PR | Update | Verdict | Reason / next step |
|---|---|---|---|

Then: fixes for `BLOCKED` PRs (the exact file and value to change), the checks for `MANUAL` PRs, and a merge order (low blast radius first; each disruptive one alone). In **review** mode stop here, after running step 6.

## 5. Comment, approve, merge

Renovate rebases its open branches after every merge to the base branch, and other people merge too. Re-read before every write.

1. **Merge** mode: `bash scripts/wait-checks.sh <url> ...` for the `MERGE` PRs whose checks were pending or whose head moved. A PR whose head moved since step 3 goes back through step 3 (`pr-diff.sh`) before it is approved.
2. **Approve** (approve/merge mode, `MERGE` verdicts only): `gh pr review <url> --approve --body "<one-line reason, head sha8>"`. Never approve a PR you pushed to.
3. **Merge** (merge mode): one PR at a time, in the step 4 order:

   ```sh
   bash scripts/merge.sh <url> <reviewed-head-sha>
   ```

   It refuses a moved head, a non-clean state and non-green checks. On `NOT MERGED`, wait for checks (`wait-checks.sh`), re-review if the head moved, retry. When merging triggers a deploy, confirm the deploy run for the previous merge started (`gh run list -R <repo> --branch <default> --limit 3`) before the next merge, and merge each disruptive update alone after the previous deploy finished.
4. **Comment** (comment mode): post after the outcome is known, so the comment states what happened:

   ```sh
   gh pr comment <url> --body-file "$SCRATCH/comment-<n>.md"
   ```

   Body: verdict, update (from → to, manager, type), evidence (checks at head sha8, failing step and root cause), next step or fix. A PR merged by someone else mid-run gets "safe; already merged before this review" if it was safe.

Guardrails: merge only what the user asked to merge, pinned to the reviewed head with `--match-head-commit` (inside `merge.sh`). Leave Renovate branches, PR bodies, auto-merge settings and other people's reviews as they are: for a `BLOCKED` PR, report the fix (or open a separate PR to the base branch when the user asks).

## 6. Audit the Renovate config

Run once per repo in scope (per org: on the repos that had PRs), in every mode. Follow [`references/config-audit.md`](references/config-audit.md). Report findings with a proposed config diff; change the config only when the user asks, through a PR.

## Shell notes

Some sessions refuse compound shell lines that mention `gh` inside loops or `$(...)`. Keep each call a plain `bash <script> <args>` or a single `gh` command; put loops into a script in the scratchpad.
