# Auto-Start Dungeon Selector Design

## Scope

Add configurable dungeon and difficulty selection to `holygrail/script-v6-full-run-dg.lua`. Selection affects only dungeon creation after a successful lobby auto-sell. Preserve normal replay, backpack detection, auto-sell, portal handling, and solo party behavior.

## Navigation

- Add `Dungeon` as first Utility sub-tab.
- Utility sub-tabs become `Dungeon`, `Grocery`, `Season`, and `Auto Sell`.
- Rename visible `AutoSell` tab text to `Auto Sell`; runtime identifiers may remain unchanged.

## Dungeon Controls

- Show one dungeon selector and one difficulty selector.
- Show read-only status rows: Party Size `SOLO 1/1` and Trigger `AFTER AUTO-SELL`.
- Do not add a `START NOW` button.
- Changing selectors performs no server request.

## Dungeon Catalog

- Enumerate worlds through `ReplicatedStorage.Configs.World.ResWorld.__index`.
- Resolve each config entry from `ResWorld[WorldId]`.
- Exclude entries whose mode is `Lobby`.
- Sort by configured `Sort`, then world ID.
- Display translated game names using `TranslationUtil` and world config name key.
- Show every dungeon. Mark locked entries `LOCKED` and prevent selecting them.
- Determine lock state through `WorldUtil:IsUnlockWorld(LocalPlayer, WorldId, 1)`.

## Difficulty Catalog

- Build difficulty choices for selected dungeon using `WorldUtil` data.
- Resolve each internal difficulty level through `WorldUtil:GetWorldDiffInfo(WorldId, DiffLevel)`.
- Include normal and Hell difficulty levels supported by selected dungeon.
- Resolve visible names through `RarityTiers:GetDifficultyName(DiffInfo.Difficulty)`.
- For Hell entries, display `Hell (<difficulty name>)`.
- Hide internal numeric difficulty levels completely from visible labels.
- Show every discovered difficulty. Mark locked entries `LOCKED` and prevent selecting them.

## Selection Behavior

- Selecting a different unlocked dungeon automatically selects its highest unlocked difficulty.
- User may then select any other unlocked difficulty for that dungeon.
- Locked dungeon and difficulty rows are informational only.
- Current selection summary uses translated dungeon and difficulty names.

## Persistence

- Add `AutoStartWorldId` and `AutoStartDifficulty` to existing JSON config.
- Save after a valid dungeon or difficulty selection.
- Validate saved values against current game config on load.
- Default missing values to existing targets: `World3` and internal difficulty `10`.
- If saved dungeon is missing or locked, select first unlocked non-lobby dungeon.
- If saved difficulty is missing or locked for selected dungeon, select its highest unlocked difficulty.

## Runtime Integration

- Replace fixed auto-start target locals with validated saved values.
- Use selected internal values in existing calls:

```lua
WorldRemoteEvent:FireServer("SelectWorld", AutoStartWorldId, AutoStartDifficulty)
GameMatchRE:FireServer("CreatRoom", AutoStartWorldId, AutoStartDifficulty, 1)
```

- Trigger remains `QueueAutoStartSoloDungeon()` after auto-sell confirms backpack usage is below maximum.
- Auto-start still requires Auto Farm, Auto Replay, lobby state, no sell pending state, and existing cooldowns.
- Failed preconditions retain existing pending retry behavior.
- Normal victory with available backpack space still clicks `Play Again` and does not use selected auto-start target.

## Implementation Shape

- Keep active runtime in `holygrail/script-v6-full-run-dg.lua`.
- Reuse existing panel, tab, dropdown, config, translation, and save helpers where possible.
- Add no external dependency and no new server remote.
- Cache local catalogs; rebuilding UI must not increase remote traffic.

## Non-Goals

- No manual instant queue.
- No configurable party size; party remains `1/1`.
- No changes to auto-sell criteria or timing.
- No changes to replay decisions.
- No automatic selection of locked content.
