---
---

# Agent Delegation

- All code modifications must be delegated to a matching specialized agent
  (or a team of agents) whenever such agents are available — do not edit code
  directly in the main session.
- Pick the agent whose scope matches the work (backend, frontend, infra/devops,
  testing, review, security). Use an agent team when the task spans scopes.
- The main session orchestrates: it explores, plans, delegates, and integrates
  results — it does not author the implementation itself.
- Enterprise/company-specific agents are distributed via a private plugin (see
  per-repo CLAUDE.md for the concrete agent roster).
- Exception: trivial, non-code edits (docs/config one-liners) may be done
  directly.
- Exception: small, bounded code edits (1–2 files, obvious change: typo, rename,
  a single-function fix, a config tweak) are done directly in the main session
  or via `caveman:cavecrew-builder`. Every spawned agent starts with ~45k tokens
  of context, so delegate only when the work is big enough to pay for that.
- Model choice: implementation agents (`backend-engineer`, `frontend-engineer`,
  including the private-plugin variants) run on Sonnet. When spawning one
  whose definition says `model: opus`, pass `model: "sonnet"` on the Agent call.
  Keep Opus for the main session and for `security-auditor`.
