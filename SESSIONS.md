# Sessions

Log of AI-assisted working sessions on this repository, newest first. Maintained by the `sync-docs` skill (`.claude/skills/sync-docs/SKILL.md`); a Stop hook prompts for an update whenever files change after this log was last touched.

Each entry records what changed and what was decided, not how. Open questions live in the relevant spec, not here.

---

## 2026-11-17 — Repository bootstrap and Phase 0 spec

**Changed**
- Added assistant instruction files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (mirroring `.github/copilot-instructions.md`).
- Created the project skeleton: `specs/` (`constitution.md`, `000-system-setup/` … `006-platform-tools/`), `src/`, `tests/`, `.github/workflows/`, `README.md`; empty directories hold `.gitkeep`.
- Wrote the Phase 0 spec (`specs/000-system-setup/spec.md`) and acceptance criteria (`specs/000-system-setup/acceptance.md`): OS/shell detection, tool and version discovery, diagnostics, JSON report.
- Added `SESSIONS.md`, the `sync-docs` skill, and a Stop hook that prompts for doc sync.

**Decided**
- Specs are language-agnostic until `constitution.md` records an implementation language.
- Phase 0 is read-only and offline: no installs, config writes, network access, or telemetry.

**Open**
- 13 questions in `specs/000-system-setup/spec.md` §9; Q5 (implementation language) blocks `plan.md`.
- `constitution.md`, `plan.md`, `tasks.md`, and `README.md` are still title-only.
