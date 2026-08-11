# Auto Hatch Pet Egg Design

## Goal

Automatically claim completed pet hatches and fill every empty hatch slot with the best available owned egg.

## Controls

- Add `Auto Hatch Egg` to Utility -> Pets.
- Default the toggle to off and persist it in `IronSoulConfig/YasirConfigV3.json`.
- Show runtime state such as `OFF`, `CLAIMING SLOT 1`, `HATCHING SLOT 2`, `HATCHING`, `NO EGGS`, or `PAUSED`.

## Egg Selection

- Read owned eggs through `PetsHatchUtil:GetOwnedEggs(LocalPlayer)`.
- Resolve each egg through `PetsHatchUtil:GetEggCfg(EggData.EggId)`.
- Sort eggs by rarity descending, configuration sort ascending, then UUID for deterministic ties.
- Use each owned egg UUID once and continue until all empty slots are filled or inventory has no eggs.

## Reconcile Flow

- Trigger reconciliation only from `PetHatch.Egg` and `PetHatch.Slots` data listeners, plus once when the toggle is enabled.
- Inspect slots `1..3` through `PetsHatchUtil:GetSlotData`.
- Claim the first completed occupied slot through `PetsHatchUtil:Claim(LocalPlayer, SlotIndex)`.
- If no claim is pending, start the highest-priority remaining egg in the first empty slot through `PetsHatchUtil:StartHatch(LocalPlayer, SlotIndex, EggUUID)`.
- Perform at most one server-changing action per reconciliation and wait for the resulting data event before the next action.
- After an action, use one bounded confirmation timeout. If hatch data did not change, retry that action once, then stop until a real data event occurs.
- Completed claims take priority over starting new eggs.

## Idle And Safety

- When no owned eggs remain, set `NO EGGS` and perform no remote calls or repeated scans until a relevant data event occurs.
- When all slots are occupied and incomplete, set `HATCHING` and remain dormant until slot data changes.
- Pause while rejoin recovery blocks automation.
- Deduplicate queued reconciliation so bursts of data events produce one deferred pass.
- Do not use `Heartbeat`, `RenderStepped`, or a timed polling loop.

## Scope

- Modify V6 only.
- Do not buy eggs, spend Robux to skip hatch time, delete pets, or change expedition behavior.
