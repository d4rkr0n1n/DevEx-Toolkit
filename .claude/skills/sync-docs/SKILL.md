---
name: sync-docs
description: Update SESSIONS.md and keep the repository's Markdown docs (CLAUDE.md, AGENTS.md, GEMINI.md, .github/copilot-instructions.md, README.md) consistent with the current state of the repo. Use at the end of a working session, when the docs-sync Stop hook asks for it, or when the user says "sync docs" / "update session log".
---

# Sync docs

Bring the repository's living Markdown docs in line with what changed. Edit only the files listed below; never touch spec content (`specs/**`) from this skill — specs change only by explicit request.

## 1. Find what changed

Run `git status --porcelain -uall` and `git diff --stat`. Read any changed file you don't already have in context. Ignore `.gitkeep` files and changes made only to the docs this skill maintains.

## 2. Update `SESSIONS.md`

- Entries are newest first, headed `## YYYY-MM-DD — <short title>` with today's date.
- If today's entry already exists and covers this session's work, extend it instead of adding a new one.
- Sections: **Changed** (files/areas and what they now contain), **Decided** (choices made, with the decision not the debate), **Open** (unresolved items that block or shape next steps). Omit an empty section.
- Record outcomes, not process. Point to files instead of copying their content.

## 3. Sync assistant instruction files

`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, and `.github/copilot-instructions.md` carry the same guidance; only each file's title and one-line intro differ. If this session changed anything they describe — repository layout, commands (build/lint/test/single test), architecture, conventions, the spec workflow — update all four identically. If nothing they describe changed, leave them alone.

Keep them free of content that is discoverable from the tree or generic advice; follow the existing tone and density.

## 4. README.md

Update `README.md` only when user-facing facts changed (what the project is, how to install or run it, where specs live). Don't invent features that aren't specified or built.

## 5. Report

Finish with one or two lines naming which docs were updated, or say none needed changes.
