# Stability Audit

This project now has a repeatable health check for gameplay stability, scene
wiring, and asset/audio references.

## Command

```powershell
python tools\project_health_check.py
```

You can also set `GODOT` to the console executable and run:

```powershell
python tools\project_health_check.py
```

The wrapper intentionally launches Godot with `--disable-crash-handler`,
explicit headless/audio flags, a project-local `.godot/health_check_*.log`
file, and a timeout. It also prefers the sibling `_console.exe` when a
windowed Godot executable is supplied and enables Windows' inherited
no-error-dialog mode before launching child processes. Prefer this wrapper
over manually running raw Godot headless commands on Windows, because direct
Godot calls can show a modal crash dialog if the engine crashes while rotating
`user://logs`.

`project.godot` sets `network/tls/certificate_bundle_override` to
`res://certificates/godot_tls_bundle.pem`. This project-local Mozilla CA bundle
keeps Windows headless Godot startup from emitting noisy root certificate store
warnings. The game does not use runtime network access; this is a tooling
stability setting. Re-check whether the override is still needed after Godot
engine upgrades.

## What It Checks

- Missing `res://` asset references through `tools/audit_assets.py`.
- Retired runtime paths such as `assets/placeholders/audio`.
- Godot headless project load.
- Godot health-check logs for script errors, engine errors, and crash markers,
  even when the Godot process exits successfully.
- Main and shared scene instantiation.
- Exported `NodePath` wiring on scene root scripts.
- Required autoloads: `FarmState`, `MusicManager`, and `VoiceOverManager`.
- Voice-over catalog entries, clip paths, and aliases.
- Voice-over `.ogg` files that accidentally contain WAV/RIFF data instead of
  real Ogg Vorbis data.
- Localization translation catalogs, shipped locale coverage, and locale voice-pack manifests.
- Voice-prompt translation catalogs used by the Google pack generator.
- Music playlists for farmyard, chore, and all four seasons.
- Seasonal background and farmyard prop family completeness.
- `FarmState` progression across a full 12-day season/year loop.
- `FarmState` edge cases for optional duck pond visits, seasonal garden dates,
  old apple plot cleanup, malformed daily save shapes, and debug tester helpers.
- Missing locale translation keys compared with English source text.
- Missing voice-prompt translation catalogs for shipped locales.
- Missing locale-specific voice-pack catalog files.
- Missing voice-over clip files in the shared catalog.

`GameSettings` is also checked as a required autoload.

Additional polish QA helpers are available outside the core health wrapper:

- `python tools\qa_asset_preview.py` writes `_qa_previews/cow_crop_contact_sheet.png` for phone-readable cow and harvest icon review.
- `python tools\qa_asset_preview.py` also writes `_qa_previews/seasonal_asset_contact_sheet.png` for plant, animal, seasonal tree, duck pond, and background review.
- `tools/settings_timer_stepper_test.gd`, `tools/settings_language_popup_layout_test.gd`, `tools/settings_privacy_policy_test.gd`, `tools/rainbow_tree_drop_mapping_test.gd`, `tools/scene_navigator_persistent_pool_test.gd`, `tools/feeding_station_visual_test.gd`, `tools/garden_plot_visual_test.gd`, `tools/duck_pond_asset_wiring_test.gd`, `tools/egg_basket_fill_test.gd`, and `tools/milking_scene_cache_test.gd` cover focused settings, localized privacy-policy scrolling and live refresh, seasonal reward, harvested-plot and feeding visual states, asset wiring, and cached scene-switching regressions. The Milking cache test also verifies warm initialization, current-season background loading, two-entry cache enforcement, and Milking's protected priority entry.
- `python tools\audio_loudness_audit.py` reports audio duration and simple level checks for runtime sound and music files. Add `--report _qa_previews\audio_loudness_report.txt` to save a review artifact.
- `python tools\release_readiness_check.py` checks lightweight Android export settings such as package id, version code, landscape/stretch settings, ARM64, and sensitive permissions.
- `docs/VISUAL_QA_CHECKLIST.md` and `docs/PC_QA_SCRIPT.md` list aspect-ratio, asset-readability, audio-calmness, Tester Tools, and device-only review steps.
- `docs/COMPETITOR_POLISH_AUDIT.md` records the Sago Mini Farm preschool benchmark, Hay Day presentation benchmark, evidence set, and remaining device-QA gap.

Debug/editor runs also expose a Farmyard settings-panel Tester Tools section for manual QA. It can jump days/seasons, complete one or all chores, unlock everything, reset today's progress, mark the duck pond visited, and reset the farm state. These controls intentionally modify the local `user://farm_chore_friends_state.json` save so QA can verify real progression behavior.

Generated helper output folders such as `_qa_previews`, `tmp`,
`tools/voice_generation`, and `tools/voice_comparison` are marked with
`.gdignore` so Godot does not import source previews, work-in-progress voice
samples, Python environments, or other non-runtime artifacts when the editor
opens the project.

If voice generation leaves WAV data in `.ogg` filenames, run:

```powershell
python tools\repair_mislabeled_voice_ogg.py
```

The repair tool archives originals under `_assets_archive/audio_sources/` and
rewrites the existing runtime paths as valid Ogg Vorbis, so scene and catalog
references do not change.

## Stabilization Changes

- `scripts/core/ChoreRuntime.gd` centralizes repeated chore assist-memory setup, failed-tap recording, progress recording, and assist-action persistence.
- Chore controllers still own their scene-specific action logic, but no longer duplicate the assist persistence plumbing.
- `ChoreCompletionFlow.gd` now guards farmyard returns so a button press, tap-after-completion, and auto-return timer cannot trigger repeated scene transitions.
- `scripts/core/SceneNavigator.gd` now keeps the farmyard resident and warms activity scenes in a hidden cache, reducing mobile launch/return stalls while preserving the guarded completion-return flow.
- `SceneNavigator` eagerly warms the milking route before deferred activity warm-up continues, and exposes a cache-readiness check so the cow activity does not instantiate synchronously on a tap.
- Feeding stations now reveal only a feed pile over the troughs baked into the background; the station scene no longer creates a runtime trough layer.
- `MilkingScene.gd` now handles direct udder taps in `_unhandled_input()` as a fallback, so a valid tap cannot be swallowed if the `Area2D` input signal path does not fire.
- `SettingsPanel.gd` now preserves the visible scroll transform when refreshing sound controls, so muting a lower sound row does not snap its content out of view before the next tap.
- `FarmNightTransition.gd` now relies on the overlay's full-rect anchors instead of writing a conflicting manual size, removing the repeated anchor-layout warning during farmyard startup.
- `DuckPondMusicScene.gd` now resolves its farm and settings autoloads through the scene tree, so isolated scene wiring tests do not hide a compile error behind a passing node check.
- `ResponsiveSceneLayout.gd` now leaves full-rect background overlays sized by their anchors, removing the responsive-capture size override warning.
- `settings_language_popup_layout_test.gd` now awaits its asynchronous layout and cleanup checks, preventing leaked test coroutine state.
- The store and aspect-ratio capture helpers now release captured references and clear the activity warm cache between runs, keeping repeated visual QA captures isolated.

## Android Emulator QA (2026-08-01)

The current Android export was installed and launched successfully on the
`CodexFarmTest` Android 15 AVD with package
`com.cozysproutgames.myfirsthomestead`. The activity stayed alive and produced
no crash-buffer entries. The Android UI tree exposes only the full Godot
surface, so game taps require coordinate mapping from the 1920x1080 design
space to the emulator's 2400x1080 landscape surface.

The AVD's SwiftShader graphics path does not currently provide a valid render
surface for this project:

- The shipped `gl_compatibility` renderer reaches the main loop but reports
  built-in `SceneShaderGLES3`/`CanvasShaderGLES3` uniform-limit failures and
  captures a gray surface.
- A temporary Android-only `mobile`/Vulkan export reaches the main loop but
  reports `QueuePresentKHR failed with error: 5` and captures a black surface.
- ANGLE/SwiftShader and the host-GPU emulator launch path reproduce the same
  limitation; the guest still selects SwiftShader.
- A second fresh `CodexFarmAlt` medium-phone AVD using the same Android 15
  image also launches the app and reaches `OnGodotMainLoopStarted`, but
  reproduces the same gray surface and GLES shader-link failures. This rules
  out the original AVD's saved state or launcher setup as the primary cause.

The project remains on its original `gl_compatibility` setting until the APK
can be visually validated on a physical Android device or an emulator with a
working Vulkan/host presentation path. This is an emulator graphics blocker,
not evidence of an application crash. The emulator also reports
`Text to Speech not initialized`, which is expected for this AVD's missing TTS
voice data and should be rechecked on a device with Android TTS voices.

## Current Known Cleanup Candidates

The asset audit separates cleanup candidates from intentionally retained
unreferenced assets in `docs/ASSET_KEEP_LIST.txt`. Candidates are not
automatically wrong and should not be deleted without review.

Keep the current policy:

- Report unreferenced assets.
- Archive only after confirming they are not future animation states, source references, or editor-only material.
- Delete only in a later reviewed cleanup pass.

## When To Run

Run the stability check after changes to:

- chore scene scripts;
- `FarmState`;
- scene transitions or completion flow;
- music, sound effects, or voice-over;
- seasonal backgrounds or prop families;
- asset moves or folder cleanup;
- release/export preparation.
