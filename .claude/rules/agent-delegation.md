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
