# PR Watch: every open PR is watched until it merges

Applies to all work, in every repo and on every host, whether the main session
or a subagent opened the PR. Decided by Alex on 2026-11-18.

## 1. Every new PR gets a watcher

- Add each PR that the session or a subagent opens to a watch list, by its full
  URL. Keep that list in the session scratchpad or the sweep state file.
- Keep a background watcher running for the whole session: a Monitor, or a
  background poll loop that re-invokes the session. It polls every PR on the
  list for `state`, `mergeable`, `mergeStateStatus`, `headRefOid` and
  `statusCheckRollup`.
- When a PR turns red (a failing check, not an expected or documented red),
  becomes `CONFLICTING`/`DIRTY`, or gets new review comments, spawn a subagent
  to fix it. Follow the repo's fix-pr skill if it has one, otherwise
  the private plugin's fix-pr skill.
- One fixer per PR at a time. Do not start a second one while the first is
  still running.
- Keep the PR on the list until it is merged or closed.

## 2. Every merge triggers a conflict sweep

- When any PR merges (one of ours, or one a human merged), re-check every other
  open PR in the same repo, plus every PR on the watch list.
- Spawn a subagent for each PR that is now `CONFLICTING`/`DIRTY`, or `BEHIND`
  while the merge is blocked by a required up-to-date check. A plain `BEHIND`
  with a mergeable PR needs no update. The subagent resolves it against the new
  base and gets CI green again.
- Tell fixers that are already running on that repo that the base branch moved.

## 3. Pushing to a watched PR

Every push restarts CI, dismisses stale approvals and stops auto-merge. So:

- Update from base only on a conflict or a blocking `BEHIND` (see §2). Rebase
  plus `--force-with-lease` by default; merge the base in when the repo needs
  confirmation for a force-push or the branch carries other people's commits.
- Push nothing while the head commit is approved, unless the user asks or a
  required check is red. Reply on the threads instead and report.
- Batch fixes into one push. Small review requests get a code change; design
  comments get a reply only.
- Push with `git push origin HEAD`, never `-u`: changing the upstream can end
  a running `/ship` or `/steward` watch.
- Never edit PR title, labels or `Closes #N` lines while fixing.

## 4. GitHub Enterprise and the built-in watch

- `gh` cannot read the host from a remote like
  `timetoact@timetoact.ghe.com:org/repo.git` (non-`git@` user or SSH alias).
  Set `GH_HOST` for every `gh` call (shell state does not persist between
  calls), or put `{"env": {"GH_HOST": "<host>"}}` in the repo's
  `.claude/settings.json`.
- Built-in `/ship` (commit, push, review, watch) and `/steward` (watch only)
  can only be started by the user. Never call them; suggest `/steward` in the
  final report instead. On GHE `/ship` opens no PR: open it with `gh pr create`
  first.
- One watcher per PR. When the user runs `/steward` or `/ship` on a PR, the
  session's own poll loop and fixers leave that PR alone.
- A repo's `.claude/skills/steward/SKILL.md` holds its house rules for the
  watch; fixers read it too. `clp-checkin-app` (task `watch`) sets it up.

## 5. Limits that still apply

- Agents never merge, approve or arm auto-merge. Humans merge (exception: the
  owners in `~/.claude/hooks/merge-allowlist.json`, see `git-workflow.md`).
- No terraform plan or apply, no cluster writes and no publish runs, unless the
  repo explicitly allows them for agents.
- Report every PR by its full URL.

## 6. When the watch ends

The watch ends when every PR on the list is merged or closed. The session
reports the end state with full URLs. If only human-blocked PRs remain and
nothing changed over three polls, report that and slow the polling down rather
than stopping it.
