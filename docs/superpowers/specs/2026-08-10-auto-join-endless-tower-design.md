# Auto Join Endless Tower Design

## Goal

Automatically create an Endless Tower room from the lobby with saved starting-round and player-count controls.

## Selection

- Store `0` as `Highest Unlocked`; custom starting points are `1, 6, 11, ... 196`.
- Read seasonal `MaxRound` through `WorldUtil:GetWorldRecords(LocalPlayer, "Endless1", 1, "MaxRound", SeasonUtil:GetCurrentSeason())`.
- Compute highest starting point as `floor(MaxRound / 5) * 5 + 1`, clamped to `1..196`.
- Allow player counts `1..4`, defaulting to solo.

## Lobby Flow

- Run only while enabled, in lobby, outside rejoin recovery, and outside auto-sell work.
- Require a shared eight-second lobby/character readiness grace before any normal or Endless room creation.
- Scan only Endless MatchRoom slots `Room9` and `Room10`, requiring `PlayersCount == 0` plus empty room state.
- Touch the selected room portal and wait for visible `MainGui.ScreenMatch_Endless` before creating the room.
- Fire `GameMatchRE:FireServer("CreatRoom", "Endless1", 1, playerCount, startingRound)` at most every ten seconds.
- Stop retrying after `LocalPlayer:GetAttribute("EnterRoomId")` reports a server-assigned room.
- Endless Tower takes priority over normal dungeon auto-start.
- Portal touch selects the physical Endless room context because the remote payload does not include a slot index.
- In the tower, detect the visible `Equip Extra Weapon` title and activate the `Start` button within its modal with bounded retries.

## UI

- Add Utility → Tower.
- Show Auto Join toggle, starting-round dropdown, player-count dropdown, highest round, resolved next start, and runtime status.
- Keep locked checkpoints visible but non-selectable.
