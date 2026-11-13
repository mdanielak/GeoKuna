# GeoKuna Agent Environment Implementation Plan

> **For agentic workers:** Use Superpowers planning for substantive changes and the role-specific skills listed in AGENTS.md. This task prepares project instructions/configuration; it does not implement application features.

**Goal:** Set up a small, verifiable agent workflow for an offline Android geography app.

**Architecture:** Sol coordinates Luna and Terra; Astra handles exceptional decisions. Project-scoped configuration points the official Dart MCP at the existing SDK. Educational decisions live in a local skill; UI conventions stay in AGENTS.md.

**Tech Stack:** Existing Codex, Superpowers 7.0.1, Dart & Flutter plugin 1.0.7, Flutter 3.50.0 / Dart 3.14, UI/UX Pro Max, Linux/KVM.

**Spec:** User's agent-environment request; requirements recorded in AGENTS.md and docs/AGENT_ENVIRONMENT.md.

## Global constraints

- No global configuration changes, package installation, application refactor or automatic Git commits.
- Limit routine parallel work to two workers with disjoint file ownership.
- Default visual/runtime target: Flutter Web in Chrome. Never install or launch an Android emulator; physical Android checks are deferred.
- Keep learning effectiveness ahead of animation and gamification.

## Review focus

1. Model inheritance must not silently run Luna/Terra tasks on Sol.
2. A plugin listed as enabled is not proof that its MCP tools are connected.
3. Browser checks satisfy current visual milestones but do not prove Android-native storage, gestures or performance.
4. Skill instructions must not replace approved requirements or force web dependencies into Flutter.
5. Existing knowledge provenance and user progress must remain intact.

## Task 1 — Project instructions and environment

- [x] Inspect installed skills, tool catalog, model catalog, Linux/Flutter/Android readiness.
- [x] Replace AGENTS.md with roles, skill triggers, quality gates and proportionate visual checks.
- [x] Add project .codex/config.toml and luna/terra/astra role files.
- [x] Verify effective MCP configuration using `codex mcp list --json`; no duplicate server.
- [x] Document readiness, actual tool limitations, and how to activate the setup.

## Task 2 — Learning design skill

- [x] Add `.agents/skills/geokuna-learning-design/SKILL.md` and UI metadata.
- [x] Validate skill structure and activation boundaries using the existing skill-creator validator.
- [x] Review recognition/cued recall/recall, spelling tolerance, data provenance and FSRS separation.

## Validation

Parse all new TOML/YAML; check local references, role models and CLI loading.
Use short read-only Luna/Terra reviews if supported; do not touch application code.
Record actual results in docs/AGENT_ENVIRONMENT.md. Do not launch emulators; do not report browser checks as physical Android verification.

## Wynik

Konfiguracja i skill zwalidowane; lokalny CLI odczytuje pojedynczy Dart MCP z istniejącym SDK.
Luna i Terra wykonały niezależne krótkie przeglądy read-only bez istotnych uwag.
Nie instalowano zależności, nie zmieniano konfiguracji globalnej ani kodu aplikacji.
Flutter Web w Chrome jest domyślnym środowiskiem wizualnym. Nie instalować ani nie uruchamiać emulatora; test fizycznego Androida później, gdy potrzebny.
