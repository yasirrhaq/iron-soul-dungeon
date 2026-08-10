# Auto Giveup Lobby Restart Design

## Goal

When Auto Giveup is enabled, a dead dungeon character exits the death screen, always returns to lobby, and starts the configured solo dungeon again when Auto Replay is enabled.

## Death Flow

- Check death before target acquisition so living enemies cannot block Give Up handling.
- Require `_G.AutoGiveup`, active dungeon state, and `LocalPlayer:GetAttribute("RemainLife") <= 0`.
- Activate exact `BattleHUD.PlayerRevive.ReviveFrame.Revive.ExitBtn` first so the original client handler performs the exit.
- If settlement does not open, fire `ReplicatedStorage.Remotes.GamePlayerRE:FireServer("ExitSettlement")` on the next bounded retry.
- Do not fire `TaskRE`; it is client task telemetry after `ScreenSettlement` opens.
- Wait for exact `ResultGui.ScreenSettlement.BtnGroup.ReturnToLobbyBtn`, persist restart intent, then click it with the existing GUI activation helper.

## Lobby Restart

- Persist `Config.DeathRestartPending` before returning to lobby because teleport/AutoExec reloads script state.
- Set pending only when Auto Farm and Auto Replay are enabled; lobby return still happens when they are disabled.
- In lobby, queue the saved solo dungeon immediately when backpack has room.
- If backpack is full and Auto Sell is enabled, wait for existing sell flow, then queue dungeon.
- Clear pending only after the create-room remote is fired successfully.

## Safety

- Send at most one Exit button activation or ExitSettlement fallback per retry interval and one lobby click per click interval.
- While death flow is active, skip target movement, portal progression, replay scanning, and attacks.
- Reset runtime request state after respawn.
