# My First Homestead Architecture

This guide is for developers joining the Godot project and needing the wiring map quickly. The project is intentionally simple: scenes stay separate, shared systems stay in `scripts/core/`, and toddler-friendly input always favors clear single-tap success.

## Scene Flow

The normal play loop is:

1. `StartScene.tscn`
2. `SceneNavigator.gd` creates and owns `FarmyardScene.tscn`
3. One cached activity scene is shown above the resident farmyard
4. The activity is freed and the resident farmyard is shown again

Chore scenes are independent scenes:

- `EggCollectingScene.tscn`
- `MilkingScene.tscn`
- `WateringScene.tscn`
- `FeedingScene.tscn`
- `BrushingScene.tscn`

The farmyard hub owns navigation into these chores through `SceneHotspot` nodes. `SceneNavigator.gd` keeps the farmyard instance alive after Start, fully prepares Milking as the priority hidden activity, retains Milking plus at most one recently used activity, and swaps only the active activity layer during launch/return. Chore scenes report progress and completion through `FarmState`, then use `ChoreCompletionFlow` to show completion feedback and return to the hub through the navigator.

## Main Systems

- `FarmState.gd` is the progression source of truth. It owns day, year, season, chore completion, garden plot states, unlocks, reward milestones, and local farm save/load.
- `FarmState.gd` also exposes locale-neutral helpers for season names, encouragement lines, sticker names, and completion feedback so saves never depend on translated text.
- `SceneNavigator.gd` is the persistent navigation layer. It owns the resident farmyard, synchronously prepares Milking during route registration, activates cached scenes on tap, keeps a two-entry cache with Milking protected from eviction, and returns to the farmyard without reloading its scene tree. Debug builds emit `[SceneTiming]` stage and first-frame measurements for phone profiling.
- `FarmyardScene.gd` is the hub controller. It refreshes day/season UI, hotspot badges, reward visuals, ambient life, seasonal overlays, and forgiving background routing.
- `SceneHotspot.gd` is the reusable chore navigation area. It handles tap feedback and routes through `SceneNavigator.gd` when available. In the farmyard, hotspot routing is called manually after hub-life objects get input priority.
- `ChoreAssist.gd` tracks staged toddler help inside chore scenes. It moves from normal play to gentle hints, stronger hints, and one assisted action at a time.
- `ChoreCompletionFlow.gd` standardizes chore completion: hide/show Back to Farm, lock immediate skip briefly, allow saved-settings-controlled tap-anywhere return after completion, and auto-return after final action feedback has finished.
- `ChoreRuntime.gd` centralizes repeated chore assist-memory setup and persistence so chore controllers keep only their scene-specific action logic.
- `FarmFeedback.gd` contains reusable pulses, flashes, bounces, celebrations, and one-shot sound helpers.
- `MusicManager.gd` keeps music continuous across scene changes, selects season-aware playlists, and supports the shared audio settings.
- `VoiceOverManager.gd` speaks only help tips and completion messages when voice-over is enabled. It prefers bundled recorded prompt clips and uses platform TTS only as a missing-clip fallback.
- `SeasonalBackground.gd` applies current-season background textures for chore scene `Sprite2D` backgrounds. It supports direct texture resources and path-based loading; Milking uses paths so its warm instance holds only the active barn background instead of all four seasons. Garden care handles its seasonal backgrounds in `GardenScene.gd` because winter also affects the garden presentation.

## Localization Flow

- `GameSettings.gd` owns the runtime locale state, including the automatic-vs-manual choice, the chosen locale code, and the `locale_changed` signal that scenes listen to for live refreshes.
- `scenes/settings_panel.tscn` and `scripts/ui/SettingsPanel.gd` expose the language picker. The panel refreshes its labels when the locale changes so the current language can be changed without restarting the game.
- Translation source text lives in `localization/translations/*.json`. English is the source language, and `tr()` lookups in code and translated control text in scenes use the same keys.
- `LocalizationFonts.gd` installs bundled Noto fonts as a fallback chain for Latin, Arabic, Devanagari, Simplified Chinese, Japanese, and Korean text. Mixed-script UI such as the language picker should render without requiring OS language packs.
- Spoken prompt text for generated voice packs lives in `localization/voice_prompts/*.json`. Those catalogs are loaded alongside the main translation files so the TTS generator and runtime settings can stay aligned.
- `VoiceOverManager.gd` follows the active locale, tries locale-specific prompt packs under `sounds/voice_over/locales/<locale>/voice_lines.json`, and falls back to the shared catalog when a locale pack is missing a clip.
- `tools/generate_voice_over.py` is the local AI generation pipeline for the shipped shared and locale voice packs. It can target a local command template so the project never needs runtime voice generation, and it reads the voice-prompt translation catalogs when building locale packs.

## Input Routing

Farmyard input priority is:

1. Hub-life interactables, such as chickens, bees, and spring geese.
2. Chore hotspots.
3. Empty background helper taps.

This matters because the farmyard uses broad toddler-friendly hotspot and helper areas. A direct tap on a critter must not also route to a chore or count as a background helper tap.

For `Area2D` hub interactables:

- Use a generous `CollisionShape2D`.
- Keep the object script responsible for its own feedback.
- Provide `handle_tap()` where possible.
- Call `get_viewport().set_input_as_handled()` after a successful tap.

`FarmyardScene.gd` disables direct hotspot picking in the hub and routes hotspots manually from `_unhandled_input()`. This keeps the order predictable: object interaction first, hotspot routing second, helper fallback last. The saved "Tap Anywhere to Play" setting now also gates the farmyard's blank-background auto-routing so turning it off keeps kids from drifting into the next chore by accident.

Required chore launches are gated by a short Farmyard-entry cooldown so kids see the hub before the next chore can open. Optional hub interactions remain active during this pause. Before Farmyard launches an activity, it snapshots transient ambient state into `FarmState` so the cat/mouse chase and winter Santa fly-by can restore their visible positions when the resident hub is shown again. New activity routes should use `SceneNavigator.gd`; direct `change_scene` calls should stay as fallback paths only.

For chore scenes, direct gameplay targets should also consume handled input when they react. Background/assist logic should run only for unhandled taps.

The shared settings panel is a screen-relative overlay that sizes itself to the current viewport. `res://scenes/settings_panel.tscn` is the canonical editable scene instanced by both Start and Farmyard; `SettingsPanel.gd` should keep behavior, responsive fitting, tab state, saved-value refresh, and invisible touch proxies. The panel uses a 1900x1040 parent-notebook backing asset, Sound and Gameplay tabs, and notebook-style controls so Start and Farmyard settings stay visually consistent. Its scroll view is wider than the centered controls, leaving side gutters that act as reliable scroll-start space on phones. Slider touch proxies capture horizontal slider intent, and toggle touch proxies capture quick taps, but both allow vertical drags to continue into the scroll container so controls do not steal scroll gestures. The Sound tab uses volume sliders with high-contrast mute buttons for all sound, music, sound effects, and voice-over; muting preserves the last non-zero slider value. The Gameplay tab stores tap-anywhere return plus independent Duck Pond and Mole Garden timer toggles and durations, with a Custom chip that reveals minus/plus minute controls instead of a device-keyboard text field.

Privacy & Parents is a Language-tab-only control. It opens a scrollable, bundled policy matching the active app locale from `res://resources/privacy_policy*.txt`, with `res://resources/privacy_policy.txt` as the English fallback. The Android export preset explicitly includes all localized policy files, and every in-game copy links to the public policy page at `https://github.com/wryan2986/my-first-homestead-privacy`. Leaving the Language tab closes the policy overlay so it cannot cover Sound or Gameplay controls.

## Save Files

Farm progress saves to:

- `user://farm_chore_friends_state.json`

Audio and voice settings save to:

- `user://farm_chore_friends_audio_settings.json`

Simple gameplay settings, including optional activity timer enablement and durations, save to:

- `user://farm_chore_friends_game_settings.json`

Old save compatibility belongs in `FarmState.gd` or the relevant settings manager. Avoid one-off migration logic inside scene controllers.

## Adding A Chore

1. Create a separate scene under `res://scenes/`.
2. Add a thin controller in `res://scripts/chores/`.
3. Reuse shared scenes from `res://scenes/shared/` where practical.
4. Add shared progression state and APIs to `FarmState.gd`.
5. Add a chore hotspot to `FarmyardScene.tscn`.
6. Wire the hotspot target scene and visual node.
7. Add completion messaging and daily reset behavior in the centralized systems.

Keep chore scripts focused on scene interaction. Do not put global day, season, reward, or save rules in a chore controller.

## Adding A Hub Critter

1. Create or reuse an `Area2D` scene under `res://scenes/shared/`.
2. Add a large collision shape that is easy for toddlers to tap.
3. Put animation and sound feedback in the critter script.
4. Add a public `handle_tap()` method that consumes the event.
5. Instance the critter under the farmyard ambient-life area.
6. Keep movement bounded away from UI and chore hotspots.
7. If the critter needs special seasonal behavior, refresh it from `FarmyardScene.gd` using `FarmState.current_season`.

Optional seasonal farmyard features should stay outside required daily chore completion. `FarmyardScene.gd` currently enables winter Santa fly-bys and small seasonal tap surprises from shared scenes under `res://scenes/shared/`. Spring pond geese use their own `geese_pond` unlock and carry their built-in pond art under `AmbientLife`. The unlocked duck pond decoration routes to `res://scenes/DuckPondMusicScene.tscn`, an optional lily-pad music activity with seasonal backgrounds that records a once-per-day visit in `FarmState` but does not gate Next Day progression. Duck Pond and `MoleGardenScene.tscn` each read their own optional timer enablement and duration from `GameSettings.gd`, allowing parents to tune those optional activities independently, and return to the hub through the guarded completion-flow transition helper. Both optional scenes are registered with `SceneNavigator.gd` so they can launch from the warmed cache like required chores.

A separate calm mini-play scene can also live beside the garden as a farmyard decoration hotspot. `MoleGardenScene.tscn` follows the same optional pattern: it launches from the hub, stays out of progression, uses seasonal backgrounds like the other farm scenes, and should keep its feedback soft, readable, and toddler-friendly.

The Next Day button runs `FarmNightTransition` before calling `FarmState.advance_day()`. This is a visual pause only: it blocks taps during the short firefly transition, then preserves the existing daily reset and reward/unlock flow.
`FarmNightTransition` uses larger phone-readable stars/fireflies plus random owl and short cricket ambience variants. Long source recordings may stay in `sounds/` for editing, but runtime scenes should reference short derived clips.

Garden harvest basket visuals use crop-only item sprites under `art/garden/harvest_items/` so collected crops do not reuse whole in-ground plant art with dirt.

## Adding Reward Decorations

Reward progression belongs in `FarmState.gd`; visual placement belongs in `FarmyardScene.gd`.

Use curated slots rather than random coordinates. Decorations should avoid:

- roads and paths
- chore hotspots
- UI
- animals and critters
- garden interaction previews

Prefer replacement-style upgrades or small intentional additions so the farm feels cared for instead of cluttered.

## Replacing Art Or Audio

Most visual assets live under `res://art/`. Replace textures through scene inspector assignments or by overwriting same-size PNGs when that is intentional.

Chore scene seasonal backgrounds live under `res://art/backgrounds/` as 1920x1080 PNGs. Keep each season's layout aligned so foreground animals, tools, hit areas, and UI remain readable and unchanged.

Audio is split between short sound effects under `res://sounds/`, generated music under `res://assets/music/`, and voice-over clips under `res://sounds/voice_over/`. Retired placeholder/source files are archived under `_assets_archive/` rather than kept in runtime folders. When replacing audio, derive short OGG runtime variants from long raw recordings and update exported `AudioStream` arrays on the relevant scene instead of hard-coding paths in scripts.

For audio conversion and trimming, run `ffmpeg` from the project root. Example for making a short OGG clip from a source recording:

```sh
ffmpeg -y -ss 0 -t 5 -i input.wav -ac 1 -ar 44100 -c:a libvorbis -q:a 4 sounds/short_clip.ogg
```

Use short derived clips in runtime scenes and keep long raw recordings only as source material for future edits.

Seasonal background music is assigned through the exported spring, summer, fall, and winter playlists on `MusicManager.tscn`. Scene changes should request the appropriate music context without forcing the current track to restart.

Voice-over prompt clips live under `res://sounds/voice_over/` and are cataloged in `res://sounds/voice_over/voice_lines.json`. Completion messages should use `FarmState.get_chore_completion_feedback()` so the visible text and spoken prompt key stay synchronized.
Locale voice packs live under `res://sounds/voice_over/locales/<locale>/` with the same prompt keys, and the runtime falls back to shared audio if a localized clip is missing.

Run `python tools\project_health_check.py` after scene, asset, audio, or progression changes. It wraps the asset audit, Godot headless load, scene smoke checks, voice/music catalog checks, seasonal content completeness checks, and a multi-day `FarmState` progression simulation.

## Responsive Layout

The project treats 1920x1080 landscape as the centered safe design area. It is the gameplay coordinate system, not a fixed device requirement. `project.godot` uses canvas-item stretch, `expand` aspect, fractional scale mode, and landscape orientation so wide phones and tablet layouts expose extra logical viewport space instead of forcing a 16:9 display.

`res://scripts/ui/ResponsiveSceneLayout.gd` centers fixed scene content in the expanded viewport without scaling it. World-space visuals and their matching `Area2D` hotspots must stay in the same shifted hierarchy or direct scene-root group so collisions remain aligned with sprites. Do not use cover-fit scaling for gameplay objects or hotspots, because it crops the safe area on wide phones and can hide important toddler-facing content.

Chore scenes whose background contains the actual play surface, such as nests, troughs, stalls, or garden beds, opt into `ResponsiveSceneLayout.fit_design_roots_to_viewport`. In that mode the non-HUD design roots use the same cover-fit transform as the background, keeping props, animals, tap areas, and baked-in background targets aligned on wide phones. Use this only for contained chore scenes; hub scenes such as Farmyard keep gameplay roots centered in the safe area.

HUD controls belong under `CanvasLayer` or another screen-relative `Control` surface. Buttons, completion panels, labels, and overlays should be anchored to the physical viewport, not locked to the 1920x1080 safe-area corners. Full-screen transparent controls must use `mouse_filter = IGNORE` unless they intentionally handle input.

Completion celebration props are part of the HUD overlay. If one chore has tall foreground art on phones, adjust the chore-specific completion visual size, spacing, or vertical offset in `ChoreCompletionFlow.gd` instead of moving the whole shared panel for every chore.

Runtime scene backgrounds use cohesive 1920x1080 source art cover-filled to the physical viewport by `res://scripts/ui/ResponsiveCoverSprite2D.gd`, `res://scripts/ui/ResponsiveCoverTextureRect.gd`, or the Farmyard layer-group helper `res://scripts/ui/ResponsiveCoverNode2D.gd`. This fills wide phones and tablets without mismatched AI bleed. Background edge cropping is acceptable; important characters, buildings, labels, chore hotspots, and other gameplay objects must remain separate from the background and inside the central safe area.

FarmyardScene cover-fills the `BackgroundLayers` group in screen space, while `ActivityAreas`, `Decorations`, and `AmbientLife` stay in the centered gameplay safe area. `ResponsiveCoverNode2D` derives the cover source size from the actual layer texture, so downsampled farmyard exports such as the 1600x900 Android tier still fill the 1920x1080 scene coordinate space without gray bands. Its seasonal base and split sky/ground/season overlay assets use the non-bleed sources. This scene is the most likely to need visual phone review because it contains the richest background composition.

Standard landscape QA sizes are `1920x1080`, `2340x1080`, `2400x1080`, `2520x1080`, `1280x800`, `1280x960`, and `1440x960`. When practical, also check `1920x1200`, `2048x1536`, and `2160x1440`. The 4:3 tablet case is the important worst case because it is much taller and narrower than 16:9; the complete central composition must still remain visible.
