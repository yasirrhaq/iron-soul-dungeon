# Auto-Skill Visual Suppression Design

## Goal

Add an optional persisted setting that hides character skill animations and local skill VFX only for skills cast by the script's auto-skill loop. Skill execution, animation timing, damage markers, cooldown state, and manual skill casts remain active.

## User Interface

- Add `Disable Auto Skill Animation` to the Farm tab.
- Default the setting to off.
- Persist it in `IronSoulConfig/YasirConfigV3.json`.
- Apply changes immediately without restarting the script.

## Cast Scoping

- Open a short suppression session immediately before auto-skill presses `Q`, `E`, `R`, or `G`.
- Never open a suppression session for manual input or weapon switching with `C`.
- Associate newly played skill animation tracks with only the active auto-skill session.
- End the session when the skill track finishes or a bounded timeout expires.

## Character Animation

- Keep each matched skill animation track playing so keyframe markers and client-side skill callbacks can still run.
- Hide body movement by forcing zero animation weight every rendered frame instead of calling `AnimationTrack:Stop()`.
- Keep `IsSkillAnimating()` aware of the hidden track so auto-skill does not overlap casts.
- Do not modify non-skill locomotion, enemy, or manual-cast tracks.

## Skill VFX

- During the active auto-skill session, watch and repeatedly scan local character, equipped tool, camera, and known local effect containers so pooled instances are suppressed too.
- Suppress only visual properties on matched particles, trails, beams, smoke, fire, sparkles, lights, highlights, decals, textures, and effect parts.
- Clear already emitted particles when supported.
- Preserve original properties and restore them when the session ends.
- Leave an effect visible when ownership cannot be scoped safely; never disable scripts, remotes, hitboxes, attachments, sounds, or gameplay objects.

## Lifecycle And Safety

- Rebind animation observation after character or Animator replacement.
- Turning the toggle off immediately ends suppression and restores tracked visual properties.
- Timeout cleanup prevents stale hidden effects when animation completion signals do not fire.
- Errors in visual suppression fail open: skill stays visible but continues normally.

## Verification

- Add a runnable PowerShell check before implementation and verify it fails for missing behavior.
- Verify config default, load/save wiring, Farm toggle, auto-skill-only session creation, zero-weight animation handling, VFX class allowlist, restoration, and no `Track:Stop()` use.
- Run focused check, existing auto-skill check, menu/config check, Luau parse, and `git diff --check` after implementation.

## Non-Goals

- No direct damage remote invocation.
- No suppression of manual skills, enemy VFX, environment VFX, sounds, camera shake, or damage numbers.
- No destruction of effect instances or gameplay objects.
