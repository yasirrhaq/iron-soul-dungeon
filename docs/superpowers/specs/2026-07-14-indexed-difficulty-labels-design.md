# Indexed Difficulty Labels Design

## Scope

Make Dungeon difficulty choices easier to identify by showing their internal index in the V6 UI and by probing standard levels `1` through `10` directly. This design supersedes the earlier requirement to hide numeric difficulty levels.

## Display

- Prefix every visible difficulty label with its internal level.
- Use format `[<level>] <game difficulty name>`.
- Use the same format in dropdown rows and the currently selected value.
- Keep locked suffix behavior unchanged.

Examples:

```text
[1] Easy
[5] Nightmare
[9] Hell (Expert)
[10] Hell (Nightmare)  LOCKED
```

## Discovery

- Call `WorldUtil:GetWorldDiffInfo(WorldId, DiffLevel)` for each standard level from `1` through `10`.
- Include an entry only when the call succeeds and returns valid difficulty information plus a valid game difficulty name.
- Continue reading `WorldUtil:GetWorldStyleList(WorldId, "Hell")` for nonstandard/additional mapped levels.
- Deduplicate entries by internal level.
- Sort entries by internal level ascending.
- Do not fabricate an entry when the game returns no valid definition.

## Selection And Runtime

- Keep lock detection through `WorldUtil:IsUnlockWorld(LocalPlayer, WorldId, DiffLevel)`.
- Locked entries remain visible and nonselectable.
- Keep highest-unlocked fallback based on the numeric internal level.
- Keep saved `AutoStartDifficulty` and remote arguments unchanged.
- Add no remote and change no auto-start, auto-sell, replay, lobby, portal, or party behavior.

## UI Behavior

- Dropdown remains scrollable because ten rows exceed its visible height.
- Index prefix makes off-screen ordering clear and distinguishes normal from Hell levels.
- Existing dropdown peer-close and tab-reset behavior remains unchanged.

## Validation

- Extend `tools/checks/check-v6-menu.ps1` to assert direct `1..10` probing and indexed label construction.
- Run actual Luau compilation, `luaparse`, all PowerShell checks, `git diff --check`, and verify V5 unchanged.

## Documentation

- Update `docs/features.md` to describe indexed difficulty labels.
- Treat this design as the override for numeric-label visibility in `2026-07-14-dungeon-selector-design.md`.

## Non-Goals

- No hardcoded translated difficulty names.
- No fabricated unsupported levels.
- No larger dropdown or removal of scrolling.
- No configurable label format.
