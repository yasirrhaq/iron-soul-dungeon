This is when i click manually give up button (i can't find it in dex maybe you can show me where?)
# Calling code
local Event = game:GetService("ReplicatedStorage").Remotes.GamePlayerRE
Event:FireServer(
    "ExitSettlement"
)

This is after i click giv eup button
# Calling Code 2
local Event = game:GetService("ReplicatedStorage").Framework.Features.TaskSystem.TaskRE
Event:FireServer(
    "UpdateTaskProgress",
    "OpenGUIWindow",
    "ScreenSettlement",
    nil
)

After this 2nd calling code we got return to lobby / play again button

## Confirmed Flow

- DEX path for the real death-screen button is `Players.LocalPlayer.PlayerGui.BattleHUD.PlayerRevive.ReviveFrame.Revive.ExitBtn`.
- `StarterGui.BattleHUD.PlayerRevive.LocalPlayerRevive` shows the revive UI when `LocalPlayer:GetAttribute("RemainLife") <= 0`.
- The original `ExitBtn.MouseButton1Click` handler either enables spectator mode or calls `GamePlayerRE:FireServer("ExitSettlement")`.
- Automation should activate the real `ExitBtn` first so the game's own handler runs, then use direct `ExitSettlement` only as a retry fallback.
- Do not gate death scanning behind Auto Farm or `IsInLobby()`: enemy cleanup can remove `WorldEnemys` at death and make the old lobby heuristic return true before Give Up runs.
- `GamePlayerRE:FireServer("ExitSettlement")` moves the dead run into `ScreenSettlement`; it does not return directly to lobby.
- `TaskRE("UpdateTaskProgress", "OpenGUIWindow", "ScreenSettlement", nil)` is client task telemetry after the screen opens and should not be fired by automation.
- Automation should wait for `ResultGui.ScreenSettlement.BtnGroup.ReturnToLobbyBtn`, persist restart intent, then click Return to Lobby.
- Auto Replay alone does not normally queue from lobby. A persisted death-restart flag is required to queue the saved solo dungeon after AutoExec reloads the script.
