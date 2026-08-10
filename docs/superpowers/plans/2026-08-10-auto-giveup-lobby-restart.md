# Auto Giveup Lobby Restart Implementation Plan

**Goal:** Replace fragile target-dependent Give Up clicking with direct settlement exit, forced lobby return, and persisted dungeon restart.

## Task 1: Regression Check

- Create `tools/checks/check-v6-auto-giveup.ps1`.
- Assert direct `GamePlayerRE` call, death-before-target ordering, exact lobby button path, pending persistence, lobby processing, and pending clear after room creation.
- Run check and confirm RED before Lua edits.

## Task 2: Runtime Flow

- Add `DeathRestartPending` config default and normalization.
- Add global `AutoGiveupFlow` state to avoid V6 top-level local-register pressure.
- Process pending restart in lobby through existing auto-start and auto-sell flows.
- Rewrite death scan to use `RemainLife`, exact PlayerRevive `ExitBtn`, direct `ExitSettlement` fallback, exact Return to Lobby button, and bounded retries.
- Move death scan before target acquisition.
- Run death scan outside the Auto Farm and lobby-heuristic gates.

## Task 3: Documentation And Verification

- Update `docs/features.md` and `research/dump/auto-giveup.md`.
- Run focused Auto Giveup check, all V6 checks, Luau compilation, Lua parser, and `git diff --check`.
- Commit task files only.
