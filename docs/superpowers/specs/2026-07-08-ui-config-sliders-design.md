# UI Config Sliders Design

## Scope

Add saved `TinggiMelayang` and `BaseSpeed` controls to `scripts/base/base-script-v2.lua`.

## Behavior

- Save config to `IronSoulConfig/YasirConfig.json` using executor `writefile/readfile` when available.
- Load saved `TinggiMelayang`, `BaseSpeed`, `UndergroundMode`, `AutoReplay`, and `PerfectForge` on script start.
- Add height slider range `5..100` studs.
- Add base speed slider range `16..100`; applies to `Humanoid.WalkSpeed` only outside lobby.
- In lobby, disable farm movement/jump/platform/portal/replay and reset `WalkSpeed` to `16`.

## Non-Goals

- No manual save/load buttons.
- No radius/orbit speed sliders.
- No new dependencies.
