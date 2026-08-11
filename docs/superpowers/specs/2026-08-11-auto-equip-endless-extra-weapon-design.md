# Auto Equip Endless Extra Weapon Design

## Goal

Automatically equip an eligible extra weapon before starting an Endless Tower run, while allowing a saved specific-weapon preference.

## Weapon Selection

- Default to `Highest Damage (Auto)`.
- List each eligible owned weapon as `<name> (+<fortify>) | DMG <damage>`; omit the fortify suffix when its displayed value is zero.
- Resolve names through `TranslationUtil`, displayed fortify as `Fortify - 1`, and damage through `EquipmentUtil:GetDmgOrHpByInfo`.
- Exclude time-limited weapons and weapons currently assigned to primary or secondary equip slots, matching the game's extra-weapon picker.
- Sort specific weapons by damage descending, then rarity descending, then equipment sort order.
- Persist the selected weapon UUID. If it becomes unavailable or ineligible, retain the preference but use the current highest-damage eligible weapon for that run.

## Refresh

- Rebuild dropdown options when owned equipment or equip slots change.
- Refresh through data listeners only; do not poll inventory every frame or on a timed loop.
- Keep `Highest Damage (Auto)` selected by default and always available.

## Endless Start Flow

- Run only when the existing Auto Join Endless Tower flow detects the visible `Equip Extra Weapon` modal.
- Resolve the configured eligible weapon, falling back to highest damage when needed.
- Fire `EquipmentRE:FireServer("RequestSetExtraWeapon", weaponUUID)` only when `ExtraWeaponUUID` does not already match.
- Wait with bounded retries for `LocalPlayer:GetAttribute("ExtraWeaponUUID")` to confirm the requested UUID.
- After confirmation, activate the modal's existing Start button.
- If the configured request times out, retry once with the current highest-damage weapon. If no eligible weapon exists or confirmation still fails, activate Start so the run does not remain stuck.

## UI And Configuration

- Add an extra-weapon dropdown to Utility -> Tower near existing Endless controls.
- Store the chosen UUID in `IronSoulConfig/YasirConfigV3.json`.
- Show the effective fallback weapon in runtime status when a saved specific weapon cannot be used.

## Scope

- Apply extra-weapon automation only to Endless Tower start modal.
- Do not change normal loadout slots, general equipment automation, or inventory sorting.
