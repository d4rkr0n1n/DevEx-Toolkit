# AGENTS.md

This file provides guidance to AI coding agents (such as OpenAI Codex) when working with code in this repository.

## Repository state

This repository is an initial scaffold. The only project files are `LICENSE` (Unlicense / public domain) and the AI-assistant instruction files. There is no source code, dependency manifest, build configuration, test suite, lint configuration, or README yet.

## Commands

No build, lint, or test commands exist yet. Do not invent commands or assume a language, framework, package manager, or runtime. When tooling is added, record the canonical setup, build, lint, and test commands here, including how to run a single test.

## Architecture and conventions

There is no architecture or code convention to preserve yet. Keep early additions focused on establishing project structure and tooling, and update this file as those choices become concrete. Preserve the public-domain terms in `LICENSE`.

## Keeping assistant instructions in sync

`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, and `.github/copilot-instructions.md` carry the same guidance for different tools. When changing one, apply the same change to the others.
