# Asset Organization

This project keeps runtime assets organized by how Godot uses them, and keeps
old generated/source material out of the runtime folders.

## Runtime Folders

- `res://art/animals/` - polished animal sprites and animation state images.
- `res://art/backgrounds/` - full-scene backgrounds, including seasonal chore backgrounds and farmyard layers.
- `res://art/props/` - farmyard, chore, decoration, and shared prop sprites.
- `res://art/garden/` - garden plots, crops, and plant state sprites.
- `res://art/effects/` - feedback effects such as sparkles, glows, and indicators.
- `res://art/ui/` - buttons, icons, badges, app icons, and settings art.
- `res://assets/music/` - generated background music assigned through `MusicManager.tscn`.
- `res://sounds/` - short sound effects.
- `res://sounds/voice_over/` - bundled voice-over clips and `voice_lines.json`.
- `res://sounds/voice_over/locales/<locale>/` - localized voice packs, including the locale `voice_lines.json` catalog and any locale-specific special clips such as the Santa greeting.

## Archive Folders

Use `_assets_archive/` for files that should stay in the repository for now but
should not be treated as active runtime assets.

- `_assets_archive/unused_candidates/` - files that are not currently referenced by scenes, scripts, or configs.
- `_assets_archive/source_files/` - old editable/source assets such as `.xcf`, old `.webp`, and placeholder-era art.
- `_assets_archive/generated_originals/` - source generations kept only for future recrop/regeneration work.
- `_qa_previews/` - generated QA contact sheets and screenshot evidence. These are review artifacts, not runtime assets.

Do not delete archived assets in the same pass that moves them. Keep one cleanup
cycle between archiving and deletion so references, dynamic loads, and future
asset needs can be checked calmly.

## Reference Audit

Run the asset audit before and after moving or archiving assets:

```powershell
python tools\audit_assets.py --fail-on-missing
```

The audit reports:

- every runtime asset under `art`, `assets`, and `sounds`;
- `res://art/...`, `res://assets/...`, and `res://sounds/...` references found in scenes, scripts, configs, JSON, and docs;
- referenced paths that no longer exist;
- unreferenced candidates that may be stale or reserved;
- intentionally retained unreferenced paths listed by `docs/ASSET_KEEP_LIST.txt`.

An unreferenced asset is only a candidate. Some files may be intentionally kept
as source references, future animation states, or editor-only material.

## Moving Assets Safely

1. Run `python tools\audit_assets.py --fail-on-missing` and save the baseline result.
2. Move one small group of assets at a time.
3. Update all matching `res://` paths in `.tscn`, `.tres`, `.gd`, `.json`, `project.godot`, and `export_presets.cfg`.
4. Let Godot reimport moved assets so `.import` sidecars and `.godot/imported` cache entries refresh.
5. Run the audit again.
6. Run a Godot headless load.
7. Smoke-load the scenes that use the moved assets.

Prefer overwriting an asset in place when the filename and purpose are unchanged.
Move assets only when the organization benefit is worth updating references.
