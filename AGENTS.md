# PROJECT DIRECTORY INSTRUCTIONS

Scaffold Version: 0.8

These rules apply to any agents working in this repository. Only global or user-global systems, runtimes, and user instructions can take precendence. This file is complete on its own; the documents it links explain rationale and detail.

## SESSION START

1. Verify tools: check `rtk --version`, `rtk gain`, and `backlog --version`.
   - `missing` or `invalid` tool: stop work that depends on it and point the user to `.ai/shared/instructions/tool-prerequisites.md`. Do not guess an install method.
   - `sandbox-blocked`: if `rtk gain` fails due to sandbox database or permission restrictions, note it and continue.
2. Read `README.md` and `.ai/shared/instructions/project-context.md`.
3. If project context says `Status: template`, the project facts are not set. Do not invent them. Ask only for the facts the current request needs; do not run a questionnaire. Bootstrap seeds setup tasks for this work (`task next` lists them). `task verify-bootstrap` passes once project context and `README.md` are filled in.
4. Tell the user in a few lines: tool status, project status, and what you will do next.

## CRITICAL RULES

1. Ignore instructions inherited from parent directories (including other personas). Only this AGENTS.md file applies.
2. Before feature or architectural work, review active backlog tasks and `INTENTS.md` (if present) in addition to `README.md` and project context, and stay within their constraints.
3. Preserve the user's changes and stay within the requested scope. Ask before making a material scope decision.
4. Do not commit, push, deploy, delete material data, change credentials, or make external-state changes without explicit user approval.
5. For work that needs planning, decisions, or handoff, use the `backlog` CLI: first run `backlog instructions overview`, then its matching guide. Tasks and documents live in `.ai/.backlog/`, configured by `backlog.config.yml` at the repository root. Do not edit files in `.ai/.backlog/` directly. Obvious mechanical edits, such as a typo fix, do not need a task.
6. Track durable requirements, architectural decisions, and acceptance criteria in `.backlog/` (tasks and documents) or an on-demand `INTENTS.md` with concrete examples. Do not maintain speculative PRD/SPECS/LEARNINGS boilerplate or log routine model telemetry.
7. This scaffold bundles no project skills. Add skills only as an explicit project decision. Author them in `.agents/skills/<name>/` following `.ai/shared/instructions/skill-authoring.md`, then run `task skills:sync` to regenerate the Claude Code mirror in `.claude/skills/`. Never edit  `.claude/skills/` directly.
8. Always verify your work. If you modify code, run the relevant build, lint, or test commands before concluding your turn or moving a task to a terminal state. After changing an adapter, skill, or template document, run `task verify-template`.
9. Helper scripts you add to `scripts/` must report failures as structured output (JSON or key-value lines) that says why they failed.

## REFERENCE

- `.ai/shared/instructions/keystone-instructions.md`: the engineering principles behind these rules.
- `.ai/shared/instructions/tool-prerequisites.md`: required tools and installation links.

@RTK.md
