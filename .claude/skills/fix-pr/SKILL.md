---
name: fix-pr
description: >
  Address PR comments, rebase onto the latest base branch, fix CI failures, watch
  the PR until mergeable and green. Use when the user says "fix the PR", "address
  PR comments", "rebase and fix CI", "/fix-pr", or provides a PR number/URL and
  wants it driven to merge-ready. Resolves PR target from arg, session-linked
  file/env, or current branch. Detects base branch from the PR itself. Aggressive
  rebase + force-with-lease. Loops on CI failures up to a bounded iteration cap.
  Never merges — humans merge.
---

# fix-pr: Drive a PR to merge-ready

Take a PR, address every actionable reviewer comment, rebase onto the latest
base branch, fix CI failures, and loop until the PR is mergeable and green.
You do NOT merge — merge is always human.

## Trigger phrases

`fix the PR`, `address PR comments`, `rebase and fix CI`, `/fix-pr`, `make
the PR green`, `drive PR <n> to merge-ready`. Also when the user passes a PR
number/URL with intent to finalize.

## 1. Resolve target PR

Priority order:

1. **Argument** — number (`123`), URL (`https://github.com/o/r/pull/123`), or
   `gh pr ...` form on the invocation.
2. **Session-linked** —
   - `.claude/session-pr` file at repo root (contains PR# or URL).
   - `CLAUDE_SESSION_PR` env var.
   - If current branch matches `agent/<jira-key>` (cloud-swarm convention),
     `gh pr list --head "$(git branch --show-current)" --state open --json number --limit 1`.
3. **Current branch PR** — `gh pr view --json number,url,baseRefName,isDraft,headRefName,mergeable`.

Capture: `PR_NUM PR_URL BASE_BRANCH HEAD_BRANCH IS_DRAFT MERGEABLE`.

Stop conditions before doing any work:

- No PR found → stop, tell user how to specify (arg / file / env).
- `IS_DRAFT == true` and no `--force` flag → stop with message ("PR is draft;
  pass `--force` to fix-pr it anyway"). Resume with `--force`.

## 2. Plan with TaskCreate

Create tasks: comment-collection, comment-resolution, rebase, push, CI watch,
iteration. Update statuses as you progress.

## 3. Collect actionable feedback

Gather every item that needs a response. Use `gh api` / GraphQL where the CLI
falls short.

- **Unresolved review threads** — GraphQL `pullRequest.reviewThreads` filtered
  by `isResolved: false`. Capture `thread_id, path, line, body, diffHunk` and
  the originating review-comment id.
- **Reviews with state `CHANGES_REQUESTED`** — `gh pr view $PR_NUM --json reviews`.
- **Inline suggestion blocks** — review comments containing a
  ```` ```suggestion ```` block. Prefer applying verbatim unless the suggestion
  is wrong; if wrong, fix the underlying issue and explain in the reply.
- **Top-level @-mentions of the PR author / current `gh api user` login** —
  `gh pr view $PR_NUM --json comments`.

De-duplicate. Build a list: `{id, kind, file, line, body, author, thread_id?}`.

## 4. Address each item in code

Delegate code changes to specialized agents where available (e.g.
`backend-engineer`, `devops`, `frontend-engineer`). Group comments per file
to minimize churn.

After each fix (or batch of related fixes pushed in one commit):

- **Reply per thread** describing what changed.
  - Inline review comment → `gh api repos/:o/:r/pulls/:n/comments/:id/replies -f body=...`.
  - Issue-level comment → `gh pr comment`.
- **Resolve the thread** via GraphQL `resolveReviewThread(input: {threadId: ...})`
  once the code change is pushed.

If a comment is unclear or out-of-scope → reply with the reason, do NOT resolve,
list it under "unresolved" in the final summary.

## 5. Rebase aggressively onto base

```sh
git fetch origin "$BASE_BRANCH"
git rebase "origin/$BASE_BRANCH"
```

On conflict, resolve aggressively in favor of intent (newer logic, incoming
change semantics). Re-run tests after rebase.

Hard stop: if a conflict needs human judgment (two diverging features touching
the same lines), `git rebase --abort` and stop with a summary. That's a
human-only failure.

## 6. Pre-push checks (repo-agnostic inference)

Run the repo's pre-push gauntlet before EVERY push. Don't skip hooks
(`--no-verify`) or signing flags. Detect the gauntlet in this order — stop at
the first match:

1. **Repo CLAUDE.md** — search for a "pre-push", "before pushing", or "working
   method" section listing commands. Use those verbatim.
2. **Taskfile / Makefile target** — `task --list` / `make -qp` for targets
   named `pre-push`, `lint`, `test`, `verify`, `check`, `ci`. Prefer the most
   comprehensive umbrella target.
3. **CI workflow** — `.github/workflows/*.yml`, `.gitlab-ci.yml`,
   `.circleci/config.yml`. Pull the steps that run on PR; replicate the
   build/test/lint/typecheck commands locally.
4. **Language heuristics** as last resort:
   - Go: `go build ./... && go test ./... && go vet ./...` (+
     `golangci-lint run ./...` if `.golangci.yml` exists).
   - Node: `npm run build && npm test && npm run lint` — pick `pnpm`/`yarn`
     based on lockfile. Skip missing scripts.
   - Rust: `cargo build && cargo test && cargo clippy -- -D warnings`.
   - Python: `pytest && ruff check && mypy` if those are configured.
5. **Infrastructure parity** — if helmfile/terraform/kustomize manifests
   changed and the repo CLAUDE.md mentions them, render/validate locally too.

Cache the resolved gauntlet for the session — don't re-detect each loop.

Example (cloud-swarm, per its CLAUDE.md):

```
go build ./...
go test ./...
go vet ./...
golangci-lint run ./...
helmfile -e local template > /dev/null   # only if helmfile/ changed
```

If a command in the gauntlet fails locally, fix before pushing. Pushing a
known-failing branch wastes a CI cycle and trips the same-failure-twice guard
(§ 8).

## 7. Push (force-with-lease default)

```sh
git fetch origin "$HEAD_BRANCH"   # refresh the lease ref first
git push --force-with-lease="$HEAD_BRANCH:$(git rev-parse origin/$HEAD_BRANCH)" \
         --force-if-includes \
         origin "HEAD:$HEAD_BRANCH"
```

Defaults explained:

- `--force-with-lease=<ref>:<sha>` — explicit lease pinned to the remote SHA we
  last observed. Refuses the push if someone else pushed since our last fetch.
  Bare `--force-with-lease` (no value) is weaker because git may have refreshed
  the remote tracking ref behind the scenes; pinning the SHA closes that hole.
- `--force-if-includes` — extra guard: refuses the push unless our HEAD already
  contains the remote tip. Belt + suspenders against "force-with-lease lies".
- Never raw `--force`. Override only via the explicit `--force-push-unsafe`
  flag — and warn the user before doing so.

If the lease fails: someone pushed concurrently. Re-fetch, re-evaluate, and
stop if their commits change semantics. Don't blindly retry.

## 8. Watch CI + mergeability

Loop. Default cap: 5 iterations. Override via `--max-iters=N`.

```sh
gh pr checks "$PR_NUM" --watch --fail-fast=false
gh pr view "$PR_NUM" --json mergeable,mergeStateStatus,statusCheckRollup
```

**Success stop:** `mergeable == MERGEABLE` AND every check is
`SUCCESS`/`NEUTRAL`/`SKIPPED`.

**Human-only failure stops:**
- Required approval missing.
- Secret-scanning / DLP block.
- Same-failure-twice (see guard below).
- Base branch advanced during the run and introduces a new semantic conflict.
- External flaky service repeatedly failing the same check.

**Iteration cap stop:** max iterations reached → summary.

On a failed check: `gh run view <run-id> --log-failed`, diagnose, fix in code,
return to step 6.

### Same-failure-twice guard

After each iteration's `--log-failed`, build a stable fingerprint per failed
check and compare to the previous iteration:

```
fingerprint = sha256(
  check_name + "\n" +
  normalize(log_failed)
)
normalize(log) =
  strip ANSI codes;
  strip absolute paths up to repo root;
  strip timestamps, line numbers in stack traces, run IDs, commit SHAs;
  collapse whitespace;
  keep only failure lines (FAIL / ERROR / panic / assertion / non-zero exit).
```

Keep a per-session map `{check_name: [fp_i-1, fp_i]}`. Stop the loop with
"same-failure-twice" if any check's last two fingerprints match — the fix
didn't help and another iteration is unlikely to. Report the check name,
the matching fingerprint excerpt, and the last commit SHA.

Reset a check's fingerprint history when its check turns green — a regression
later is a fresh failure, not a repeat.

## 9. Final report

Print:

- PR URL + final state (`MERGEABLE` / blocked reason).
- Iterations used.
- Comments addressed / unresolved (reason per unresolved).
- Pushed commits (count + last SHA).
- CI status per check.
- Next action for the human (merge / approve / investigate flake).

## Rule overrides + guardrails

### Worktree handling

Detect a worktree BEFORE the first git operation:

```sh
if [ "$(git rev-parse --git-common-dir)" != "$(git rev-parse --git-dir)" ]; then
  WORKTREE=1
fi
```

If `WORKTREE=1`:

- Verify current branch ≠ `dev` and ≠ `main`. If it is, stop — operating on a
  worktree of an integration branch is wrong.
- Verify `HEAD_BRANCH` ≠ `dev`/`main`. Cross-check `PR_URL` base/head — base
  is the integration branch, head is the topic branch.
- All pushes go to `origin/$HEAD_BRANCH` only. Never `dev`/`main`, regardless
  of any global "push directly to dev" rule.
- If the rebase fast-forwards the topic branch onto `dev` such that `HEAD` now
  equals `origin/dev`, stop — that means the PR is empty and merging is the
  human's call (close PR / reopen with content).

Non-worktree mode: same rules, but skip the integration-branch-mismatch
checks since those are worktree-specific risks.

### Other guardrails

- **Push-to-dev rule:** this skill operates on an existing PR; the global "push
  to dev" default does not apply. Push to the PR's head ref only.
- **No `git reset --hard` / `git checkout .`** to clear conflicts. Resolve,
  abort, or stop.
- **No merging.** Reviewer/merge gate is human.
- **No dismissing reviews.** If a reviewer requested changes and you believe
  the request is wrong, reply with reasoning and stop.
- **No `--force-push-unsafe` without an explicit user flag.** Default to
  `--force-with-lease` (§ 7) every time.

## Flags

- `--force` — fix-pr even if PR is draft.
- `--max-iters=N` — override the 5-iteration cap.
- `--force-push-unsafe` — use raw `--force` instead of `--force-with-lease`.
