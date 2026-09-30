# Visual QA Checklist

Use this checklist after art, scene, audio, or layout polish changes.

## Asset Readability

- Generate the cow/crop contact sheet:

```powershell
python tools\qa_asset_preview.py
```

- Review both `_qa_previews/cow_crop_contact_sheet.png` and
  `_qa_previews/seasonal_asset_contact_sheet.png`.
- Check that cow states keep the same character size, anchor, outline weight, and face style.
- Check that harvest icons are crop-only, mobile-readable, and free of dirt, full plants, or confusing background pieces.
- Check that plant sprites, seasonal trees, duck pond backgrounds, and winter backgrounds match the warm preschool style.
- Check that transparent padding is consistent enough that sprites do not jump when reused in scenes.

## Aspect Ratios

Verify desktop viewport behavior as evidence for the global stretch policy. This does not prove Android cutouts or device-specific immersive behavior.

- 16:9: `1920x1080`
- Wide phone landscape: `2340x1080`, `2400x1080`, `2520x1080`
- 16:10 tablet: `1280x800`, optionally `1920x1200`
- 4:3 tablet: `1280x960`, optionally `2048x1536`
- 3:2 tablet: `1440x960`, optionally `2160x1440`

For each viewport, confirm the complete 1920x1080 safe-area gameplay composition remains visible, backgrounds cover-fill the physical screen without gray/black bands, art is not visibly distorted, and HUD/touch targets remain readable. On farmyard, review edge cropping carefully because the background is cover-filled while gameplay objects remain in the safe area; taps in decorative space outside the safe area should only hint/pulse and should not open a chore.

## Audio Calmness

Run the audio audit:

```powershell
python tools\audio_loudness_audit.py --report _qa_previews\audio_loudness_report.txt
```

Listen to any clips reported as unusually hot or loud. Prefer scene/exported volume tuning before regenerating clips.

## Final Smoke

After visual or audio edits, run:

```powershell
python tools\audit_assets.py --fail-on-missing
python tools\project_health_check.py
```
