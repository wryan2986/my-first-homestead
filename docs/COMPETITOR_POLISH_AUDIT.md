# Competitor-Referenced Polish Audit

Updated: 2026-08-01

This audit uses two references with different jobs:

- [Sago Mini Farm](https://sagomini.com/apps/farm/) is the audience reference.
  Its official page targets preschoolers ages 2–5 and emphasizes open-ended
  interaction, fun animation, curiosity, and no ads or in-app purchases.
- [Hay Day](https://supercell.com/en/games/hayday/) is the presentation
  reference for a mature, polished 2D farm game: cohesive world art, readable
  objects, friendly animals, satisfying progression surfaces, and a strong
  visual identity.

The game should match the references on scene-level finish and interaction
care, not on Hay Day's economy, content volume, live-service systems, or adult
player complexity.

## Polish Bar

| Area | Pass bar | Current evidence | Status |
| --- | --- | --- | --- |
| Art direction | Warm, coherent, readable silhouettes with no style breaks | Store captures across the start screen, farmyard, and five chore scenes | Pass |
| Preschool clarity | Large targets, forgiving taps, calm language, visible progress | Chore assist hints, direct-tap margins, touch proxies, and focused settings/chore tests | Pass |
| Interaction feedback | A successful tap produces state change plus visual/audio response | `FarmFeedback` pulse, bounce, sparkle, labels, SFX, voice prompts, and chore-specific animations | Pass; dynamic device feel still needs hardware review |
| World life | The hub and activities feel inhabited without visual clutter | Ambient critters, seasonal rewards, Santa/geese/duck/mole optional play, and farmyard captures | Pass |
| UI finish | Consistent controls, readable progress, no dead-end overlays | Settings regression suite, language popup layout test, and release screenshots | Pass |
| Responsive presentation | Safe-area composition stays intact across phone/tablet landscape ratios | Ten aspect-ratio captures, including 16:10, 4:3, and 3:2 | Pass; repeated-capture helper has a shutdown diagnostic |
| Calm/safe product surface | No ads or IAP references; optional timers disabled by default | No monetization references; Duck Pond and Mole Garden timers default to disabled | Pass |
| Runtime reliability | No missing assets, script errors, or failed focused flows | Project health, asset, audio, release, and 14 focused tests | Pass |

## Evidence Set

- `_qa_previews/android_store_screenshots/` contains nine fresh scene captures.
- `_qa_previews/aspect_ratios/` contains the responsive render matrix.
- `python tools\project_health_check.py` passes.
- `python tools\audit_assets.py --fail-on-missing` reports zero missing paths.
- `python tools\audio_loudness_audit.py` reports zero flagged clips.
- `python tools\release_readiness_check.py` passes.
- All fourteen focused Godot tests pass with clean fresh logs.

## Remaining Proof Gap

The static capture set proves composition and readability, but it cannot prove
the feel of a toddler using a real phone: tap size, latency, speaker balance,
gesture comfort, and device cutouts still need a physical Android pass. The
aspect-ratio helper also emits a generic Godot ObjectDB/resource shutdown
diagnostic after its repeated matrix run; the captures complete and the game
health/focused checks remain clean.
