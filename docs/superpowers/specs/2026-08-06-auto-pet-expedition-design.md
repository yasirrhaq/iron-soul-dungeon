# Auto Pet Expedition Design

## Scope

Add persisted Auto Expedition and Auto Claim Expedition controls to V6 only. Claim completed expeditions and immediately consume remaining daily dispatch chances using eligible highest-affinity pets.

## Configuration

- `AutoPetExpedition` defaults `false`.
- `AutoClaimPetExpedition` defaults `false`.
- `PetExpeditionSlotOrder` defaults `{ 2, 3, 4 }`.
- UI `Slot Order` accepts unique comma-separated slots from `1` through current `SlotCount`.
- Invalid and duplicate slots are removed while preserving first occurrence order.
- Empty order disables dispatch while claims remain active.

## Runtime

- Claim scans every slot, including slots excluded from dispatch order.
- Dispatch scans configured order left to right and uses first empty slot.
- Available daily chances are consumed immediately.
- Eligible pets must pass `CanDispatch` validation.
- Priority is higher affinity, higher rarity, lower definition sort, then lower UID.
- Claim wins over dispatch.
- Only one remote action runs at a time.
- Claim waits for slot clear; dispatch waits for expected UID.
- Runner pauses during rejoin recovery.

## Remote Contract

```lua
PetsExpeditionUtil.RemoteEvent:FireServer("Claim", SlotIndex)
PetsExpeditionUtil.RemoteEvent:FireServer("Dispatch", SlotIndex, PetUID)
```

Remaining chances equal `DailyLimit - _GetEffectiveDailyCount(LocalPlayer)`.

## Menu

Add `Auto Expedition`, `Auto Claim Expedition`, `Slot Order`, remaining-chances line, and status line to existing V6 Utility menu. Save all values in existing config. Default order is `2,3,4`.

## Validation

Add focused static check for defaults, slot normalization, remote argument order, chance calculation, all-slot claiming, highest-affinity selection, confirmation flow, rejoin pause, and menu controls. Run focused check, V6 menu check, `luaparse`, and `git diff --check`. Verify V5 unchanged.

## Non-Goals

- No recall automation.
- No automatic reward ranking.
- No GUI clicking.
- No V5 changes.
