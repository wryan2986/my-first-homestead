# PC QA Script

Use this script when testing from the Godot editor or a debug desktop run. Open
the Farmyard settings panel and use the debug-only Tester Tools section to move
quickly between farm states.

## Fast Setup

Run the baseline checks first:

```powershell
python tools\project_health_check.py
python tools\qa_asset_preview.py
python tools\audio_loudness_audit.py --report _qa_previews\audio_loudness_report.txt
python tools\release_readiness_check.py
```

## Farmyard And Seasons

- Use Spring, Summer, Fall, and Winter buttons.
- Confirm the farmyard art updates immediately for each season.
- Confirm Santa appears only in winter, and tapping Santa plays a ho-ho sound
  without routing into a chore.
- Confirm spring geese appear only when their pond unlock is available and keep
  their own pond art.
- Confirm the duck pond activity stays optional and once per day.
- Turn on the Duck Pond Timer setting, choose a short preset, and confirm the
  label includes the selected minutes.
- Press Custom, confirm the minute box appears next to the Custom chip, enter a
  custom value, and confirm Duck Pond returns to the farmyard after that timeout.
- Turn on the Mole Garden Timer setting with a different preset or custom value
  and confirm Mole Garden returns independently at its own timeout.
- Complete a chore, then tap its farmyard hotspot again. It should pulse with a
  done-for-today message instead of reopening the completed chore scene.

## Garden Flow

- Jump to Day 1 in spring, summer, or fall: plots should be ready to plant.
- Jump to Day 2: plots should be in care/grow mode.
- Jump to Day 3: plots should be harvestable.
- Jump to Winter Day 1: lettuce seeds should plant in cold frames.
- Jump to Winter Day 2: cold-frame lettuce should water/grow.
- Jump to Winter Day 3: full lettuce should harvest into the basket.
- Watch harvested crops land inside the basket, not floating above it.

## Chores

- Use Complete Next to verify the chore badge order: eggs, milking, garden,
  feeding, brushing.
- Use Complete All to unlock the Next Day button state quickly.
- Use Unlock Everything to reveal every progression gate, reward, and debug
  content path in one step.
- Use Reset Today and confirm badges, chore progress, and duck pond visit state
  clear for the same farm date.
- Repeatedly tap during chore completion and confirm the farmyard does not
  immediately enter another chore.
- In settings, turn Tap Anywhere to Play Off and confirm random completion-screen
  taps do not return early. Then return to the farmyard and confirm blank
  background taps do not auto-route you into the next chore. The Back to Farm
  button and auto-return should still work.

## Audio

- In Settings > Sound, confirm All Sound, Music, Sound Effects, and Voice Over
  mute buttons are visually clear, set their slider to 0%, and restore the
  previous non-zero slider value when pressed again.
- Egg scene: chicken taps should sound and hop, with calm random clucks.
- Farmyard winter: Santa ho-ho variants should play on Santa tap.
- Night transition: owl and cricket ambience should be calm and not too loud.
- Night transition: day 1 should show a new moon, day 2 a waxing moon, and day 3
  a full moon.
- Duck pond: seasonal background and music should load for each season.

## Aspect Ratios

Desktop viewport checks do not prove Android cutouts, but they are useful for
the global stretch policy:

- 1920x1080
- 2340x1080
- 2400x1080
- 2520x1080
- 1280x800
- 1280x960
- 1440x960
- 1920x1200, 2048x1536, and 2160x1440 when time allows

For each size, check that the complete 1920x1080 safe-area composition remains
visible, expanded space has decorative fill instead of black/gray bars, art is
not distorted, and HUD controls stay readable. On farmyard, taps in decorative
space outside the safe area should hint or pulse only, not open a chore.

## Device-Only Checks

These still need a real phone or tablet:

- Android cutouts/status-bar behavior.
- Touch target feel with toddler-sized fingers.
- Speaker loudness and balance.
- Signed AAB upload readiness.
- Store listing screenshots.
