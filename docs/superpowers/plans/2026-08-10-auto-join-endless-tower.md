# Auto Join Endless Tower Implementation Plan

## Task 1: Regression Check

- Add a focused check for config persistence, checkpoint normalization, seasonal unlocks, empty-room gating, remote payload, priority, and UI controls.
- Run it before implementation and confirm RED.

## Task 2: Runtime

- Add saved toggle, starting-round mode, and player count.
- Resolve `Highest Unlocked` from seasonal `MaxRound` and cap starting points at 196.
- Wait for an empty MatchRoom, then create `Endless1` with bounded retries.
- Share an eight-second lobby readiness gate with normal dungeon restart and stop Endless retries after `EnterRoomId` assignment.
- Block normal dungeon auto-start while Endless Auto Join is enabled.
- Detect the post-teleport `Equip Extra Weapon` modal and click `Start` before farming.

## Task 3: UI And Verification

- Add Utility → Tower controls and status.
- Update feature documentation.
- Run focused checks, all V6 checks, Luau compilation, Lua parsing, and `git diff --check`.
