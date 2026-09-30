# My First Homestead

A Godot 4 toddler-friendly farm game built around separate chore scenes, single-tap interactions, cheerful feedback, lightweight day/season progression, and simple visual farm rewards.

## Feature Overview

- Toddler-friendly single-tap gameplay with no fail states, timers, lives, or precision dragging.
- `FarmyardScene` hub with large chore hotspots, ambient farm critters, day/season status, settings, and curated rewards.
- Separate chore scenes for egg collecting, milking, garden care, feeding, and brushing.
- Optional once-per-day duck pond music scene with seasonal pond backgrounds, lily-pad notes, duck quacks, snack feeding, and its own off-by-default safety timer with preset or custom durations.
- Egg collecting, duck pond play, and mole garden hits now use rainbow-tinted musical notes, with lower pitches reading as cooler colors and higher pitches as warmer colors.
- Central day, season, year, garden, reward, and daily chore progression through `FarmState.gd`.
- Discrete garden states that persist across days and change meaningfully by season.
- Curated farm reward decorations that make the farm feel cared for without random clutter.
- Local save/load for farm progress plus persistent audio, music, sound effect, voice-over, mute, and gameplay timer settings.
- Built-in Godot localization with a settings-panel language picker, persistent locale selection, and locale-aware voice-over fallback packs.
- A local AI voice generation pipeline in `tools/generate_voice_over.py` for building the shared pack and locale packs from the same prompt keys.
- Bundled Noto fallback fonts for Latin, Arabic, Devanagari, Simplified Chinese, Japanese, and Korean scripts so the shipped languages render cleanly on mobile devices.
- Mobile-first 1920x1080 landscape layout with large readable UI and generous touch targets.

## Project Structure

- `project.godot`
  - Main project settings, mobile-friendly rendering, touch emulation for desktop testing, and the `FarmState` autoload.
- `scenes/StartScene.tscn`
  - Start flow entry point.
- `scenes/FarmyardScene.tscn`
  - Main farm hub with chore hotspots, next-day button, unlock decorations, and season/day status.
- `scenes/EggCollectingScene.tscn`
  - Chicken coop egg collection chore.
- `scenes/MilkingScene.tscn`
  - Cow milking chore.
- `scenes/WateringScene.tscn`
  - Full garden-care chore scene.
  - The original watering scene path was preserved, but it now handles the broader garden sow/grow/harvest flow.
- `scenes/FeedingScene.tscn`
  - Animal feeding chore.
- `scenes/BrushingScene.tscn`
  - Animal brushing chore.
- `scenes/shared/`
  - Reusable interactive scenes such as eggs, plot cards, animal cards, and bouncy critters.
  - `EggBasketFill.tscn` is the replaceable basket-fill component used by egg collection.
  - `MusicManager.tscn` is the autoloaded music player with replaceable exported music streams.
- `scripts/core/`
  - Shared systems such as `FarmState`, `GameSettings`, tap scene routing, localization helpers, and feedback helpers.
- `scripts/chores/`
  - Thin chore-specific scene controllers.
- `scripts/ui/`
  - Reusable visual interaction scripts for plots, critters, and care cards.
- `art/`
  - Polished preschool-cartoon PNG art package organized by `animals`, `backgrounds`, `props`, `garden`, `effects`, `ui`, and `audio_prompts`.
  - Runtime sprites use transparent PNGs; landscape scene backgrounds are 1920x1080.
- `art/fonts/`
  - Bundled fallback fonts and licensing notes for localization coverage.
- `assets/music/`
  - Generated background music assigned through `MusicManager.tscn`.
- `sounds/`
  - Short sound effects and bundled voice-over clips.
- `localization/translations/`
  - JSON translation catalogs for the shipped languages. English is the source text, and the settings panel lets parents switch or reset the locale at runtime.
- `localization/voice_prompts/`
  - Voice-prompt translation catalogs used by both the runtime locale loader and the Google voice-pack generator.
- `.github/workflows/web-pages.yml`
  - Builds the Godot Web export and publishes it to GitHub Pages.
- `review/`
  - External design-review notes and 390×844 screen captures.
- `tools/generate_polished_assets.py`
  - Deterministic helper used to regenerate the original cohesive art package.
- `tools/audit_assets.py`
  - Read-only audit for missing `res://` asset references and unreferenced cleanup candidates.
- `docs/ASSET_ORGANIZATION.md`
  - Asset folder conventions and the safe cleanup workflow.
- `docs/ARCHITECTURE.md`
  - Practical scene-flow, input-routing, save/load, and extension-point guide for new developers.
- `docs/PC_QA_SCRIPT.md`
  - Manual QA script for debug Tester Tools, seasonal flow, audio, aspect ratios, and device-only checks.

## How To Run

1. Open the folder in Godot 4.
2. Let Godot import the project assets.
3. Run the project.
4. The game starts in `res://scenes/StartScene.tscn`.

The game now resumes the saved farm state from `user://farm_chore_friends_state.json`. To force a fresh toddler-test run, temporarily set `reset_on_start` on `scenes/StartScene.tscn` or delete that user save file.

For a command-line project-load check, use:

```powershell
godot --headless --path . --quit-after 5
```

For the fuller project stability check, run:

```powershell
python3 tools/project_health_check.py
```

For quick desktop QA in a debug/editor run, open the Farmyard settings panel and use the debug-only Tester Tools section. It can jump between days and seasons, complete the next chore, complete all chores, unlock everything, reset today's progress, mark the duck pond visited, or reset the farm state.

Localization QA has its own repeatable checks:

```powershell
python3 tools/verify_localization.py --project-root .
python3 tools/verify_voice_over.py --project-root .
```

The localization verifier checks that every shipped locale still has a catalog file, still matches the English source key set, and still has a locale voice-pack manifest under `sounds/voice_over/locales/`.

Voice generation is also scripted:

```powershell
python3 tools/generate_voice_over.py --dry-run --all-locales
```

Use `tools/google_generate_locale_packs.py` to rebuild the shipped locale packs with Google Cloud Chirp 3 HD voices from the project translations and the voice-prompt catalogs in `localization/voice_prompts/`.
The developer-only voice tools use Google Cloud credentials configured on the developer machine. Generated clips are bundled with the game; voice generation is not called at runtime.

Additional repeatable QA helpers:

```powershell
python tools\audio_loudness_audit.py
python tools\audio_loudness_audit.py --report _qa_previews\audio_loudness_report.txt
python tools\release_readiness_check.py
```

## FarmState System

`res://scripts/core/FarmState.gd` is the central progression singleton.

It tracks:

- current season
- current farm day
- current farm year
- garden plot states
- daily chore progress
- daily chore completion flags
- simple unlock progress
- simple hub reward decorations
- active reward progression design
- pending and placed farm rewards
- simple same-day completion history
- lightweight local save/load state

It also owns the simple progression APIs used by scenes:

- `collect_egg()`
- `add_milk()`
- `interact_with_plot()`
- `feed_animal()`
- `brush_animal()`
- `advance_day()`

Keep new progression logic here instead of scattering it across chore scenes.

## Replay Variety

Replay variety stays small and toddler-readable:

- FarmState picks deterministic daily variants from the current day, year, and season.
- The hub shows a changing daily encouragement line before chores begin.
- Chore completion messages rotate gently across days.
- Garden crops vary by season and plot, while still using the same simple plot states and placeholder art.
- Farmyard and chore backgrounds now show season-specific outdoor color, weather, and lighting while preserving the same readable play areas.
- Background music uses season-aware playlists so spring, summer, fall, and winter feel distinct without interrupting scene changes.
- Garden crop choices vary per plot within a season using deterministic day/year/plot selection, so a saved day stays stable while the garden avoids four identical crops.
- Completion feedback uses visual-first celebration panels with existing animal, basket, bucket, and crop art; voice-over remains, but large completion text is minimized.

## Polished Asset Package

The current art package uses a preschool farm style: warm colors, thick outlines, rounded shapes, simple silhouettes, soft shading, and large mobile-readable forms.

Generated art lives in:

- `res://art/animals/`
  - Cow, chicken, pig, goat, sheep, pony, and duck with idle, happy, excited, blinking, eating, and celebrating states. Cow states should stay matched as a set so milking, brushing, farmyard, and completion views do not jump between art styles.
  - Each animal also has a reusable horizontal state sprite sheet.
- `res://art/backgrounds/`
  - 1920x1080 farmyard, start, coop, barn, garden, animal pen, brushing barn, and seasonal chore backgrounds.
  - Chore scene seasonal variants keep foreground play spaces stable and change only the full background texture.
- `res://art/props/`
  - Eggs, basket, milk bucket, feed props, grooming brush, coop, barn, stanchions, watering can, fences, paths, trees, bushes, clouds, hay bales, and seasonal hub props.
- `res://art/garden/`
  - Plot tile, seed, sprout, plant growth stages, harvest state, friendly crop sprites, and crop-only basket item icons under `harvest_items/`.
- `res://art/effects/`
  - Sparkles, stars, touch indicators, success glow, bounce indicator, reward burst, water drop, and confetti sheet.
- `res://art/ui/`
  - Large readable buttons, icons, progress icons, completion badge, and reward star.
- `res://art/audio_prompts/`
  - Short prompt notes for creating matching future sound effects.

If you regenerate art, run:

```powershell
python tools\generate_polished_assets.py
Godot_v4.6.2-stable_win64_console.exe --headless --path . --import
```

For visual QA after art changes, generate a contact sheet:

```powershell
python tools\qa_asset_preview.py
```

The preview outputs go to `_qa_previews/cow_crop_contact_sheet.png` and `_qa_previews/seasonal_asset_contact_sheet.png`; they are not runtime assets.

## Toddler-Friendly Flow Helpers

Chore scenes use two small shared helpers:

- `res://scripts/core/ChoreAssist.gd`
  - Tracks failed attempts and time without progress, then moves through gentle hint, strong hint, and one-step assisted-action stages. Current default pacing waits longer before spoken/visual repeats so hints feel calmer.
- `res://scripts/core/ChoreCompletionFlow.gd`
  - Handles the 1-second completion lockout, saved-settings-controlled tap-anywhere return, short auto-return after final chore feedback finishes, farmyard return tap cooldown, and shared image-based completion celebration panels.
- `res://scripts/core/ChoreRuntime.gd`
  - Centralizes repeated chore assist-memory setup, failed-tap recording, progress recording, and assist-action persistence.
- `res://scripts/core/SceneNavigator.gd`
  - Keeps the farmyard resident after Start, fully prepares Milking as the priority hidden activity, retains at most two recent activity instances, and routes activity launch/return without reloading the hub on mobile. Debug builds print `[SceneTiming]` markers for cache preparation, activation stages, and the first rendered activity frame.

The farm hub also has forgiving background taps, but it highlights the next unfinished chore before routing. If all daily chores are complete, a background tap advances to the next day.

## How Input Works

Farmyard input has three priority levels:

1. Interactable hub objects, such as chickens, bees, and spring geese, handle direct taps first.
2. Chore hotspots route to their matching chore scenes.
3. Empty background taps use the toddler-friendly helper flow.

Hub interactables should be `Area2D`-based with generous collision shapes and a `handle_tap()` method when possible. They must call `get_viewport().set_input_as_handled()` when they react so helper routing does not also fire.

Farmyard chore hotspots still use `SceneHotspot.gd`, but `FarmyardScene.gd` manually routes them after hub-life objects get priority. This keeps broad toddler-friendly hotspot areas from stealing taps from decorative/interactable critters. Activity launches should go through `SceneNavigator.gd` so Farmyard stays loaded and chores can be served from the warmed cache, with direct scene changes kept only as a fallback.

When the hub loads, required chore routing has a short 3-second cooldown so mobile testers cannot bounce immediately from one chore to the next without seeing the farmyard. The cooldown only blocks chore launches; settings, rewards, ambient critters, optional duck pond play, and next-day controls remain responsive. Before entering a chore, Farmyard saves lightweight ambient runtime state so the cat/mouse chase and winter Santa fly-by can resume near the same visual spot on return.

## Day And Season Progression

- The season loop is `spring -> summer -> fall -> winter`.
- Each season lasts 3 farm days.
- When the loop wraps from winter back to spring, the farm year increases by 1.
- The player advances time with the large `Next Day` button in the farm hub.
- Advancing the day can play a short night transition with a darker sky, moon, stars, fireflies, quiet crickets/owl ambience, sleeping/paused ambient animals, and hidden daytime insects/season particles.
- Egg collection, milking, feeding, and brushing reset each new day.
- Garden plots persist across days and advance through discrete states.

Garden plot states:

- `empty`
- `seeded`
- `sprouting`
- `growing`
- `ready_to_harvest`
- `harvested`

Season behavior:

- Spring, summer, and fall each use the same clear 3-day rhythm: day 1 plants the season's crops, day 2 cares for/grows them, and day 3 harvests them into the basket.
- When the season changes, harvested plots reset so the next warm season starts with planting instead of leftover harvest work.
- Winter mostly pauses crop interaction and lets the player simply tuck the garden in.

Garden taps are intentionally forgiving: tapping any plot advances one valid garden action, and each plot can receive one care action per farm day. Background taps only hint first, then assist one step at a time after the staged assist thresholds.

## Farm Reward Decorations

The old fast decoration unlocks have been replaced by three slower progression designs that share one centralized `FarmState` milestone layer. The active design is selected by the exported `progression_design` property on `res://scenes/FarmyardScene.tscn`.

Recommended default: `farm_area_evolution`. It best fits the current toddler game because it rewards steady care without asking a 2-5 year old to manage a builder UI, and it keeps the farm scene clean by upgrading curated areas instead of stacking random objects.

Available designs:

- `player_placed_rewards`: chores slowly earn reward items into a tray. The child taps the tray, then taps one large glowing placement zone. Rewards snap into curated slots so the farm never becomes cluttered.
- `farm_area_evolution`: the player does not place items. Core farm rewards appear in curated, non-road locations: flower bed, hay bales, pond decoration, farm tree, windmill, and fence flowers.
- `reward_unlock_moments`: fewer major milestones unlock special decorations during celebration moments. The same curated farm rewards are revealed intentionally.

Progression is intentionally paced much slower now. Visual rewards are kept deliberately small and curated so the farm feels cared for instead of cluttered. Functional animal/crop unlocks also remain centralized in `FarmState` so chore scenes do not need their own progression rules.

Reward placement is curated in `res://scripts/FarmyardScene.gd`. Slots are named for safe visual areas such as fence edges, grass corners, pond edges, and background hill spaces. They intentionally avoid roads, chore hotspots, animals, UI, and garden interaction areas. Old save files that reference retired `path_*` slots are displayed through safe slot migrations without changing the save format. Stale references to intentionally removed decorations, such as the barn sign, are filtered out.

To add a new reward decoration:

1. Add a milestone to the matching table in `res://scripts/core/FarmState.gd`.
2. Add or instance the visual node in `res://scenes/FarmyardScene.tscn`.
3. Export and wire the visual node path on the farmyard controller.
4. If the item is placeable, add a curated default slot and allowed-slot list in `res://scripts/FarmyardScene.gd`.

## Replacing Placeholder Art

Most current visual art lives in `res://art/`.

To replace it:

1. Import your PNG into the matching `art` folder, or overwrite an existing PNG with the same dimensions/name.
2. Open the scene or shared scene that uses the art.
3. Select the relevant node or shared scene instance.
4. Replace the assigned texture in the Inspector if you used a new filename.
5. Let Godot reimport the asset before testing.

The easiest swap points are:

- `scenes/shared/Egg.tscn`
- `scenes/shared/BouncyCritter.tscn`
- `scenes/shared/FarmAnimalCard.tscn`
- `scenes/shared/GardenPlot.tscn`
- `scenes/EggCollectingScene.tscn`
- `scenes/MilkingScene.tscn`
- `scenes/FarmyardScene.tscn`

You can also replace entire visual subtrees without changing gameplay scripts, as long as you keep the exported node paths wired.

Seasonal chore backgrounds are applied with `res://scripts/ui/SeasonalBackground.gd` on simple `Sprite2D` backgrounds, except garden care, which uses exported seasonal background textures in `GardenScene.gd` because winter also changes the garden interaction presentation. New chore backgrounds should stay `1920x1080` and preserve the same gameplay-safe foreground layout across all seasons.

## Replacing Audio

One-shot sound effects live in `res://sounds/`. Runtime scenes should reference short `.ogg` clips; keep long source recordings outside runtime folders. Polished background music lives in `res://assets/music/`, and bundled voice-over clips live in `res://sounds/voice_over/`.

To replace them:

1. Import your new `.wav` or `.ogg` files into the project.
2. Open the relevant scene.
3. Replace the exported `AudioStream` resource assigned on the root chore or hotspot script.

Common swap points:

- `scenes/shared/MusicManager.tscn`
- `scenes/FarmyardScene.tscn`
- `scenes/EggCollectingScene.tscn`
- `scenes/MilkingScene.tscn`
- `scenes/WateringScene.tscn`
- `scenes/FeedingScene.tscn`
- `scenes/BrushingScene.tscn`

Music uses season-aware OGG playlists in `res://scenes/shared/MusicManager.tscn`:

- `spring_playlist`
- `summer_playlist`
- `fall_playlist`
- `winter_playlist`
- `farmyard_playlist`, `chore_playlist`, and `soundtrack_playlist` as fallbacks.

Current generated seasonal tracks live in `res://assets/music/`:

- `music_spring_gentle_morning.ogg`
- `music_summer_sunny_play.ogg`
- `music_fall_cozy_harvest.ogg`
- `music_winter_soft_bells.ogg`

To replace music, import your loopable `.ogg` or `.wav`, open `res://scenes/shared/MusicManager.tscn`, and update the relevant exported playlist. Prefer 44.1 kHz stereo OGG Vorbis for Godot compatibility.

By default, `keep_music_continuous_between_scenes` is enabled so the soundtrack keeps playing through scene changes instead of restarting. Turn it off only if you intentionally want scene-specific music changes.

Seasonal music was generated with Stable Audio 3 small, then normalized and converted to OGG before import. Keep future tracks calm, instrumental, toddler-safe, and free of sudden changes.

The start screen has a settings button for audio controls. These settings are saved to `user://farm_chore_friends_audio_settings.json` and include:

- All sound volume.
- Music volume.
- Sound effects volume.
- Voice-over volume.
- Clear mute buttons for all sound, music, sound effects, and voice-over. Mute preserves the last non-zero slider value so parents can quickly restore a preferred level.

The same shared settings panel is available from the farmyard hub. Its Gameplay tab includes tap-anywhere return plus separate Duck Pond and Mole Garden timers with 1, 2, 3, 5, and custom minute choices. Timer choices stay hidden while a timer is off and return with the saved duration when it is turned back on; the Custom chip reveals minus/plus buttons with a minute value so parents do not need the device keyboard. Voice-over is intentionally quiet: it only reads chore trouble tips and chore completion messages. `res://scripts/core/VoiceOverManager.gd` prefers bundled recorded `.ogg` clips from `res://sounds/voice_over/voice_lines.json`, then falls back to Godot's built-in text-to-speech if a clip is missing.

Voice clips were generated with Google Cloud Chirp 3 HD and imported as OGG files. Recheck the catalog with:

```powershell
python tools\verify_voice_over.py
python tools\verify_voice_over.py --strict-files
Godot_v4.6.2-stable_win64_console.exe --headless --path . --import
```

The generation toolchain is for development only. Never commit API keys or voice model credentials, and never ship runtime cloud voice calls in the app. Human recordings can replace the generated `.ogg` files as long as the same filenames and prompt keys are preserved. See `docs/VOICE_OVER.md` and `docs/VOICE_OVER_DECISION.md`.

To create a narrator-friendly human recording packet, run:

```powershell
python tools\export_voice_over_recording_script.py
```

## Adding A New Chore

To add a new chore while keeping the current architecture:

1. Create a new separate scene in `res://scenes/`.
2. Add a thin controller script in `res://scripts/chores/`.
3. Reuse shared scenes from `res://scenes/shared/` where helpful.
4. Add any new daily state or unlock logic to `res://scripts/core/FarmState.gd`.
5. Add a new hotspot to `res://scenes/FarmyardScene.tscn`.
6. If the chore should count toward daily progression, add a new chore id in `FarmState`.

## Adding A Hub Interactable

To add a new tappable farmyard critter or helper object:

1. Prefer a reusable `Area2D` scene under `res://scenes/shared/`.
2. Add a large toddler-friendly `CollisionShape2D` that covers the visible art plus a forgiving margin.
3. Put feedback in the object script, usually through a public `handle_tap()` method.
4. Call `get_viewport().set_input_as_handled()` inside the successful tap handler.
5. Wire the object under an ambient-life root that `FarmyardScene.gd` checks before hotspot/background routing.
6. Keep movement calm and bounded so it does not block chore hotspots or UI.

Optional farmyard play should not count toward daily progression. Current examples include `SantaSleighFlyer` for winter-only sky moments, `SeasonalTapSurprises` for small spring/fall/winter tap moments, and `DuckPondMusicScene` as an unlocked pond activity where toddlers tap big lily pads to play gentle notes. `FarmNightTransition` sits in the HUD and plays the short firefly nighttime transition before Next Day advances.

The unlocked rainbow tree is a calm seasonal tap surprise: spring drops blossoms, summer drops fruit, fall drops leaves and acorns, and winter drops snow puffs and snowflakes.

Duck pond play is optional and does not count as a required chore, but `FarmState` records one duck pond visit per farm day so it cannot be repeated indefinitely before rotating back to chores. The next farm day resets that optional visit flag. Duck Pond and Mole Garden each read their own saved timer setting from the Gameplay tab.

Sticker collection is archived for later implementation. Existing sticker save data still loads through `FarmState`, but current gameplay does not award stickers or show a sticker HUD badge. Feeding stays single-tap and automatically gives each animal its matching food so toddlers do not need to choose between feed types.

See `docs/ARCHITECTURE.md` for the fuller scene and system wiring guide.

## Extension Points

These are the main extension hooks intended for future expansion:

- `res://scripts/core/FarmState.gd`
  - Shared progression, unlocks, garden logic, daily resets, and season handling.
- `res://scripts/core/FarmFeedback.gd`
  - Reusable animation and sound helpers.
- `res://scripts/core/MusicManager.gd`
  - Shared looping background music with gentle track switching between hub and chore scenes.
- `res://scripts/core/VoiceOverManager.gd`
  - Shared calm voice-over for chore help tips and completion messages, with bundled recorded clips, OS TTS fallback, and saved on/off and volume settings.
- `res://scripts/ui/SettingsPanel.gd`
  - Behavior and responsive logic for the shared parent-notebook settings panel.
- `res://scenes/settings_panel.tscn`
  - Canonical editable settings panel scene instanced by the start screen and farmyard hub. Tune visual layout, style overrides, and control placement here so both entry points stay matched.
- `res://scripts/core/SceneHotspot.gd`
  - Reusable farm hub area navigation that routes through `SceneNavigator.gd` when available.
- `res://scenes/shared/FarmAnimalCard.tscn`
  - Reusable animal care card for feeding, brushing, or future chores.
- `res://scenes/shared/GardenPlot.tscn`
  - Reusable garden plot presentation.
- `res://scenes/shared/BouncyCritter.tscn`
  - Reusable tap-reactive critter for chickens or future hub life, with exported movement bounds and optional random cluck sounds.
- `res://scenes/shared/EggBasketFill.tscn`
  - Reusable visual fill component that shows one egg sprite per collected egg.

## Mobile Notes

The game is designed around large tappable targets, single-tap input only, and a centered 1920x1080 landscape safe design area. That safe area is the base coordinate system, not the only supported physical screen ratio. `project.godot` uses canvas-item stretch, `expand` aspect, fractional scale mode, and landscape orientation so wide phones and common tablets can use the full display without stretching or cropping the core composition.

Responsive layout is handled by `res://scripts/ui/ResponsiveSceneLayout.gd`, `res://scripts/ui/ResponsiveCoverSprite2D.gd`, `res://scripts/ui/ResponsiveCoverTextureRect.gd`, and `res://scripts/ui/ResponsiveCoverNode2D.gd`. Fixed gameplay visuals, animals, props, and their matching hotspots stay in the 1920x1080 safe-area coordinate system. HUD controls stay in `CanvasLayer`/screen-relative UI and are positioned against the physical viewport. New scenes should use the shared helpers instead of manual hotspot offsets or one-off viewport math.

Runtime scene backgrounds use cohesive 1920x1080 source art cover-filled to the physical viewport. This avoids mismatched AI bleed while keeping the playable safe area and collisions centered. The cover-fill may crop background edges on non-16:9 screens, so important characters, buildings, labels, and interaction targets should remain in gameplay nodes inside the central 1920x1080 safe area rather than being baked into crop-sensitive background edges. True hand-painted bleed art can still be used later if it matches the source scene cleanly.

Contained chore scenes whose background art defines the play targets use `ResponsiveSceneLayout.fit_design_roots_to_viewport` so eggs, animals, trough feed, stalls, and garden plots scale with that background. StartScene, FarmyardScene, and optional hub-like scenes should keep gameplay content separate from the cover-filled background unless visual QA proves otherwise.

Supported landscape families include 16:9, 19.5:9 through 21:9 wide phones, 16:10 tablets, 4:3 tablets, and 3:2 tablets. Background art fills the physical screen, while important gameplay content remains inside the central 1920x1080 composition.

The current Android preset is named `Android` and is configured for Google Play Android App Bundle export:

- package id: `com.cozysproutgames.myfirsthomestead`
- app name: `My First Homestead`
- version name: `1.1.2`
- version code: `6`
- export artifact: generated locally by Godot; release packages are not checked in
- target SDK: `35`
- ARM64 export enabled for device testing
- launcher app enabled
- immersive mode enabled

Launcher icons are assigned from `res://art/ui/app_icon_*`, and the Godot boot splash uses the app icon on a soft sky-blue background. Review or replace these before public release if you want a more custom brand treatment, and confirm the final package id with your Apple/Google developer accounts.

The gameplay logic is all GDScript-based and compatible with Godot 4 mobile export.

## Android Export Steps

Follow the official Godot Android export guide and Android developer Godot guide:

- Godot docs: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html
- Android docs: https://developer.android.com/games/engines/godot/godot-export

Recommended release flow:

1. Install Godot export templates for the exact Godot version used by the project.
2. Install Android Studio, Android SDK platform tools, and the Android build tools required by Godot.
3. In Godot Editor Settings, configure the Android SDK, Java/JDK, and debug keystore paths.
4. Create a private release/upload keystore outside the repo.
5. In the Android export preset, set the release keystore path, alias, and passwords locally.
6. For each new Play testing upload, run `python tools\bump_android_release.py --dry-run`, then `python tools\bump_android_release.py` to increment the patch version and Android version code by one. Use explicit values such as `--version-name 1.1.2 --version-code 6 --app-name "My First Homestead"` when matching a required Play upload version.
7. Use the `Android` export preset to export a signed `.aab`, then upload it through the Play Console.
8. Run `powershell -ExecutionPolicy Bypass -File tools\verify_android_release.ps1`.
9. Run `python tools\release_readiness_check.py` for a lightweight export-settings scan.
10. Test on a real ARM64 Android phone/tablet before store submission.

Do not commit release keystores, passwords, or `.godot/export_credentials.cfg`.

Keep signing credentials and Play Console service-account files on the release machine; they are not part of this review repository.

## iOS Export Steps

Follow the official Godot iOS export guide:

- Godot docs: https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_ios.html

Recommended release flow:

1. Move to macOS with Xcode installed for the final iOS build/archive step.
2. Install the matching Godot export templates.
3. Create an iOS export preset in Godot.
4. Set the bundle identifier to the Apple Developer bundle id you choose for the game.
5. Configure your Apple team, signing certificate, provisioning profile, icons, and launch screen.
6. Export the Xcode project from Godot.
7. Open the exported project in Xcode, archive it, and submit through App Store Connect.

Keep Apple certificates, provisioning profiles, team-specific values, and signing secrets out of source control.

## Store Packaging Checklist

- Replace or final-polish art in `res://art/`.
- Review SFX in `res://sounds/`, generated music in `res://assets/music/`, and voice clips in `res://sounds/voice_over/`.
- Run `python tools\project_health_check.py` and resolve failures before release/export checks.
- Review or replace app icon, adaptive icon layers, and splash/launch images.
- Confirm Android package id and iOS bundle id.
- Configure release signing separately on each packaging machine.
- Test on real Android and iOS hardware, especially touch target size, audio volume, safe areas, and landscape orientation.
- Prepare store screenshots, privacy policy, content rating, and toddler/children privacy disclosures appropriate for your target stores.
