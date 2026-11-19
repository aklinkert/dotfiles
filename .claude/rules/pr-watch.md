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
- Spawn a subagent for each PR that is now `CONFLICTING`/`DIRTY` or `BEHIND`
  with a required up-to-date check. The subagent resolves it against the new
  base and gets CI green again.
- Tell fixers that are already running on that repo that the base branch moved.

## 3. Limits that still apply

- Agents never merge, approve or arm auto-merge. Humans merge (exception: the
  owners in `~/.claude/hooks/merge-allowlist.json`, see `git-workflow.md`).
- A force-push follows the repo's own rule. Where a repo requires human
  confirmation for a force-push, the fixer merges the base branch in instead.
- No terraform plan or apply, no cluster writes and no publish runs, unless the
  repo explicitly allows them for agents.
- Report every PR by its full URL.

## 4. When the watch ends

The watch ends when every PR on the list is merged or closed. The session
reports the end state with full URLs. If only human-blocked PRs remain and
nothing changed over three polls, report that and slow the polling down rather
than stopping it.
