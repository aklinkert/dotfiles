---
name: fix-issue
description: >
  Take a GitHub issue from triage to merge-ready PR. Use when the user says
  "fix issue #N", "address GH issue", "implement issue", "close issue via PR",
  or supplies an issue URL/number. The skill reads the issue, detects project
  conventions (host, base branch, pre-push checks, agent roster), implements
  the fix on a feature branch, runs mandatory code-review + security-audit
  agents before commit, opens a PR (overriding any project rule that says
  push directly to dev), then watches CI and addresses review comments until
  the PR is merge-ready. Never merges — humans merge.
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Task, TaskCreate, TaskUpdate, TaskList, ToolSearch
argument-hint: "<issue-number-or-url>"
---

# Fix GitHub Issue (Universal)

You take a GitHub issue (number, URL, or description) and deliver a
merge-ready pull request. You do NOT merge — humans merge. You DO own
the PR until CI is green and review comments are resolved.

Project-agnostic. Detects per-repo conventions on every run.

## Rule Override (read first)

This skill **explicitly overrides** any project rule that says "push
directly to dev/main, no PRs" (commonly found in CLAUDE.md "Git
Workflow" sections). When this skill runs:

- Always create a feature branch.
- Always open a PR via `gh pr create`.
- Never commit straight to the base branch from this skill.

The user invoked this skill specifically to get a PR. That intent
beats any default-push rule.

If the working directory is a git **worktree**, PR flow is mandatory
on every repo with no exceptions.

## The Loop

```
1. Detect repo conventions
2. Read issue
3. Plan + branch
4. Implement + test (delegate to agents)
5. Mandatory dual review (code-reviewer + security-auditor, parallel)
6. Commit + push + open PR
7. Watch CI
8. Address review comments
9. Ready-to-merge check  --> hand off to human
```

Run autonomously. Stop only on genuine ambiguity.

---

## Step 0: Detect Repo Conventions

Run once at session start; store in your task list.

```bash
# 1. GH host
GH_HOST=$(git remote get-url origin 2>/dev/null \
  | sed -nE 's#(git@|https://)([^:/]+).*#\2#p')
[ -z "$GH_HOST" ] && GH_HOST=github.com
export GH_HOST
gh auth status -h "$GH_HOST"

# 2. Base branch (prefer 'dev' if ahead of main, else default)
DEFAULT_BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
BASE="$DEFAULT_BASE"
if git ls-remote --heads origin dev | grep -q dev \
   && [ -n "$(git log --oneline origin/main..origin/dev 2>/dev/null | head -1)" ]; then
  BASE=dev
fi

# 3. Worktree?
if [ "$(git rev-parse --git-common-dir)" != "$(git rev-parse --git-dir)" ]; then
  WORKTREE=1
fi

# 4. Signed commits?
SIGN_FLAG=""
[ "$(git config --get commit.gpgsign)" = "true" ] && SIGN_FLAG="-S"

# 5. Agent roster
AGENTS=$(ls .claude/agents/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null \
  | sed 's/\.md$//' | tr '\n' ' ')
```

Detect pre-push commands by inspecting build files in priority order:

| File present | Pre-push commands |
|---|---|
| `Taskfile.yaml` / `Taskfile.dist.yaml` | `task ci` if it exists, else `task lint && task test` (discover via `task --list-all`) |
| `package.json` | `<pm> install && <pm> lint && <pm> test && <pm> build` (`<pm>` from `packageManager` or lockfile) |
| `Makefile` | `make ci` or `make test lint` (discover targets) |
| `go.mod` | `go build ./... && go test ./... && go vet ./...`; add `golangci-lint run ./...` if `.golangci.yml`; add `helmfile -e local template >/dev/null` if helmfile present |
| `pyproject.toml` | `ruff check && pytest` (or `uv run ...` if `uv.lock`) |
| `Cargo.toml` | `cargo build && cargo test && cargo clippy -- -D warnings` |

Detect agent roster from `.claude/agents/*.md`. Map by name:

| Role | Match names (in order) |
|---|---|
| Investigate | `explore`, `explorer`, `investigator` |
| Backend | `backend`, `backend-engineer`, `go-engineer` |
| Frontend | `frontend`, `frontend-engineer`, `react-engineer` |
| E2E | `e2e`, `playwright`, `cypress` |
| Infra | `devops`, `infra`, `platform-engineer` |
| Code review | `code-reviewer`, `reviewer` |
| Security | `security-auditor`, `security-reviewer` |

If a role's agent is missing, skip gracefully — but **never** skip
code-review and security roles. If neither exists, launch a
general-purpose agent (or run inline) but still produce the review
artifact before committing.

## Step 1: Read the Issue

```bash
gh issue view <N> --json number,title,body,labels,assignees,comments,url
gh issue view <N> --comments
```

Extract:
- **Goal** — what change is requested
- **Acceptance criteria** — explicit or implied
- **Affected area** — file paths, components mentioned
- **JIRA key** — `grep -oE '[A-Z][A-Z0-9]+-[0-9]+'` against title+body
- **Constraints / labels** — `breaking-change`, `needs-tests`, `security`, `bug`, `enhancement`

If vague, read referenced files / linked PRs / prior comments before
asking the user.

## Step 2: Plan + Branch

Sketch the change in 2–4 bullets (files + tests).

Branch naming:
- `fix/<issue-or-jira>-<slug>` for bugs
- `feat/<issue-or-jira>-<slug>` for features
- `chore/<issue-or-jira>-<slug>` otherwise

```bash
git fetch origin
git checkout -b fix/<N>-<slug> origin/${BASE}
```

If a worktree is already on a feature branch, work on it — don't
abandon in-progress work.

## Step 3: Implement + Test

Delegate every code edit to the appropriate detected agent. Respect
`.claude/rules/agent-delegation.md` if present.

- Backend → backend agent
- Frontend → frontend agent
- E2E coverage → e2e agent
- Infra / CI / Helm / Terraform → devops agent
- Cross-cutting → launch agents **in parallel** in one message

Always write or extend tests covering the regression. No fix ships
without a test that would have caught the original bug.

## Step 4: Local Verification (Pre-Push)

Run detected pre-push commands from Step 0. Loop back to Step 3 on
failure.

Never bypass with `--no-verify`, skip-flags, or by disabling a check.

## Step 5: Mandatory Dual Review (parallel)

Before committing, launch in parallel in a single message:

1. **code-reviewer** — completeness, correctness, test coverage,
   adherence to project conventions.
2. **security-auditor** — auth/permission regressions, injection,
   data exposure, secrets, multi-tenant isolation.

**Wait for both to complete before committing.** Address every
blocking finding by delegating back to the responsible agent. Re-run
pre-push checks after fixes.

Non-negotiable even if the project doesn't normally require it.

## Step 6: Commit + Push + Open PR

```bash
git add <specific files>    # avoid 'git add -A' to keep secrets out
git commit ${SIGN_FLAG} -m "$(cat <<'EOF'
fix(<scope>): <short summary>

<rationale if non-obvious>

Closes #<N>
EOF
)"
git push -u origin HEAD
```

Open the PR against the detected base:

```bash
gh pr create \
  --base "${BASE}" \
  --title "<conventional-title> (#<N>)" \
  --body "$(cat <<'EOF'
## Summary
Closes #<N>

- <bullet 1: root cause>
- <bullet 2: fix>

## Changes
- <file/area>: <change>

## Test Plan
- [x] <detected pre-push commands>
- [x] code-reviewer agent passed
- [x] security-auditor agent passed
EOF
)"
```

Capture the PR URL.

## Step 7: Watch CI

```bash
PR=<number>
gh pr checks ${PR}
gh pr checks ${PR} --watch --fail-fast
```

On failure:

1. Pull failing logs:
   ```bash
   gh run list --branch "$(git rev-parse --abbrev-ref HEAD)" --limit 5
   gh run view <run-id> --log-failed
   ```
2. Diagnose root cause. Never disable the check.
3. Delegate the fix to the responsible agent.
4. Re-run pre-push checks, commit, push.
5. Loop back to Step 7.

For flaky checks: `gh run rerun <run-id> --failed` **once**. Same job
failing twice the same way → treat as real.

## Step 8: Address Review Comments

```bash
gh pr view ${PR} --json reviews,comments,reviewDecision
gh api repos/{owner}/{repo}/pulls/${PR}/comments
```

For each unresolved comment:
- Apply the change (or push back with reasoning).
- Reply once addressed:
  ```bash
  gh pr comment ${PR} --body "Addressed in <commit-sha>: <one-line summary>"
  ```
- When all handled:
  ```bash
  gh pr ready ${PR}                          # if draft
  gh pr edit ${PR} --add-reviewer <user>     # re-request if dismissed
  ```

Re-run the mandatory dual review (Step 5) if changes touched logic or
security-relevant surface area.

## Step 9: Ready-to-Merge Check

PR is "ready" when ALL of:

- [ ] `gh pr checks ${PR}` — all required checks passing
- [ ] `gh pr view ${PR} --json reviewDecision -q .reviewDecision` is
      `APPROVED` (or no review required and CI is green)
- [ ] No unresolved review threads
- [ ] PR body contains `Closes #<N>`
- [ ] Branch up to date with base:
      ```bash
      gh pr update-branch ${PR}
      ```

Hand off to user with PR URL + one-line status + root cause + files
changed + tests added + non-blocking follow-ups.

**Do not merge.** Humans merge.

---

## Stop Conditions

Pause and ask the user when:

- Acceptance criteria are genuinely ambiguous after reading code /
  comments / linked PRs.
- A required CI secret is missing on the PR.
- A review demands scope expansion that belongs in its own issue.
- The fix requires a destructive action (force-push, history rewrite,
  dropping a migration, deleting data).
- Detection cannot determine the base branch or build tool.

## Anti-Patterns

- Pushing directly to `dev`/`main` because "the project rule says so".
- Skipping the mandatory dual review (Step 5).
- Skipping pre-push checks to "save time on CI".
- `git commit --no-verify` to bypass hooks.
- Marking the PR ready while checks are red.
- Self-merging.
- Closing the issue manually — `Closes #N` does it on merge.
- Hardcoding values from a previous session's repo — re-run Step 0
  in every new repo.

## Optional Tail: Post-Merge Hooks

Some repos label issues `review_after_fix` (or similar) after PR
merge for QA re-check. If detected on the repo via `gh label list`,
suggest the label to the user when handing off the PR; otherwise omit.
