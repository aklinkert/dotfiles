---
name: weekly-recap
description: Summarize what the user did across ALL CCS profiles for a week (or any date range) into a readable recap. Use for "weekly recap", "what did I do this week", "recap my week across profiles", "end of week summary", or /weekly-recap. Scans ~/.ccs/instances/*/history.jsonl across every CCS profile — distinct from the built-in recap skill, which only covers one profile's session transcripts.
---

# Weekly Recap (cross-CCS-profile)

Build a readable recap of the user's Claude Code work across **all CCS profiles**
(`~/.ccs/instances/*`), grouped by project and theme.

## Why this exists

The user runs multiple CCS profiles (e.g. `cpl-alex`, `cpl-coder`). Each profile
keeps its own `history.jsonl` of submitted prompts. The built-in `recap` skill
only sees the current profile's transcripts. This skill aggregates every profile.

## Steps

1. Run the digest script. It reads every profile's `history.jsonl`, filters to the
   range, and prints a compact structured digest (totals, by-day, per-project task
   intents). The raw history stays out of context — only the digest comes back.

   ```bash
   python3 ~/.claude/skills/weekly-recap/recap.py "$ARGS"
   ```

   `$ARGS` from the user's invocation (default empty = current week):
   - *(empty)* or `week` → current week, Monday 00:00 → now
   - `last-week` → previous Mon–Sun
   - `today` / `yesterday`
   - `2026-06-08` → single day
   - `2026-06-08 2026-06-12` → explicit inclusive range

   Prefer running it through the context-mode sandbox (`ctx_execute` shell) if the
   output is large, so raw prompt text is processed out-of-context.

2. Synthesize the digest into a **high-level, business-impact** recap. This is an
   executive summary, not an activity log.
   - **Header**: 1–2 sentences framing the week's overall focus + a light volume
     stat (sessions, profiles). No prompt counts as the headline.
   - **Sections grouped by repo / related-repo group** (4–7): one section per repo
     or cluster of related repos (e.g. all `clp-internal-shared/*` together as
     "Shared infrastructure"). Give each section a plain-language group title plus
     the repo names it covers, then a bolded *outcome/business-value* line and 1–3
     sentences on what got better for the org/customer and why it matters (reduced
     maintenance drag, lower risk, faster delivery, customer trust, less tech
     debt/lock-in). Value framing stays — the grouping axis is repos, the content
     is impact.
   - **Explicitly do NOT** name individual PRs, issue numbers, run IDs, branches,
     commits, or single bugs. Abstract up: "stabilized a live product" not
     "fixed PR #509". Roll repos into capabilities (e.g. all `clp-internal-shared/*`
     → "standardized org-wide CI/CD").
   - Distinguish internal-platform vs customer-facing vs personal-tooling value.
   - Lead with the biggest investment. Keep it skimmable for a non-engineer reader.

3. Do **not** dump the raw digest at the user. The digest is your input; the recap
   is the output. The per-session intents are evidence for inferring value — not
   line items to reproduce.

## Notes

- Slash commands (`/model`, `/plugins`) and bangs (`!git ...`) appear as prompts —
  treat them as weak signal; lean on natural-language intents for themes.
- Session intent = first prompt of each session. A project with many sessions but
  repetitive intents is usually one sustained effort, not many.
- If a profile has no `history.jsonl` it is skipped automatically.
- Honors the user's caveman mode etc. for the final prose — match their active style.
