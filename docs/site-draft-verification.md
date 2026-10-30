# Site draft verification

2026-10-07. The implementation is a local review draft; it has not been published or committed.

## Performed

- Installed avoid-ai-design into /home/human/.codex/skills/avoid-ai-design with the standard skill installer. The upstream rules were not modified.
- JavaScript syntax checks passed for site/theme.js and site/validation.js with node --check.
- Parsed both HTML pages and checked local link targets, fragment targets, scripts, and images. All referenced local assets and fragments exist. The root validator is removed, and the current Pages workflow publishes site/ without a copy step.
- Opened the draft in Chrome at http://localhost:8765/ and visually inspected desktop dark/fun layouts and mobile light home/dark validator layouts.
- Exercised all three theme modes. Reload preserved light mode; navigation into the validator preserved fun mode and paused motion.
- Started fun animation through its visible control: the marquee's computed animation name was retro-marquee and the image source became retro-disk.gif. The GIF decoded at its expected 32px source size. Pausing changed the computed animation name to none and selected retro-disk.png. It stayed paused on the validator.
- The browser's reduced-motion preference initialized retro motion as paused. Explicit play is allowed; a subsequent preference change to reduced motion pauses it again.
- Used Enter on the theme control; it switched modes and retained a computed 3px visible focus outline.
- Checked 390px-wide home and validator layouts. A long command initially caused page overflow; changed the grid to use zero-minimum tracks and bounded children. Recheck returned pageWidth 375 with innerWidth 390 (the difference is the vertical scrollbar), with no page-level horizontal overflow.
- Calculated contrast for primary text, secondary text, secondary text on panels, and button text in all themes. The minimum among these checked pairs was 6.04:1. This is a check of named token pairs, not a full accessibility certification.
- Reran the optional design detector on the two HTML pages and stylesheet: zero P0 and three P1 flags. Two K7 flags are external-stylesheet false positives: styles.css defines :focus-visible and browser inspection confirmed it. The C2 flag is the explicitly requested purple action color in fun mode. Removed colored side stripes rather than treating them as intentional decoration.

## Not completed

Automated local font selection was blocked by the Chrome extension's file-access permission. Actual TTF/OTF loading, invalid-file handling, preview-size changes on loaded faces, removal, and clear-all therefore need a manual browser pass. Existing rendering and controls were carried over with these fixes: registered FontFace.family now identifies the displayed font; glyph size inherits the selected preview size; loading/errors appear inline; clear-all invalidates pending loads; measured sample characters use the chosen face.

No release workflow, patching script, remote deployment, or external-link destination behavior was tested by this site task. Existing unrelated working-tree changes were preserved.

## Manual review

1. From the repository root run `python -m http.server 8765 --directory site`, then open http://localhost:8765/.
2. Cycle the theme button through light, dark, and fun. Reload and open “Validate fonts” to confirm persistence.
3. In fun mode, play and pause. Confirm that both the marquee and disk image stop. Check the width table's beveled borders and grainy yellow background.
4. In the validator choose JuliaMono-Regular.ttf and Lekton-Regular.ttf from their fontsrc directories. Confirm separate filename-labeled columns and distinct selected-font shapes. Files stay in the browser.
5. Change preview size, remove one font, add it again, and clear all. Try an invalid font file and confirm an inline error. Clear while a large font is loading to check cancellation.
6. Review at a narrow window width and navigate with Tab/Enter. Focus should remain visible in each theme.

The parent project's Backlog Definition of Done requires human approval of a verification artifact or adversarial agent verification. TASK-3 remains open for review; this report is the concrete verification artifact. No user approval was inferred from agreement about avoiding skill stacking.

## Requested refinements, 2026-10-07

Updated branding to vt/nerdified-fonts; added an SVG green-screen monitor with live cursor text; changed previews to 12 pt by default with 16 pt and larger options; applied the selected size to glyphs, box diagrams, ANSI art, and measurement characters. Added supplied box/identifier layouts and original RGB ANSI art at site/samples/font-workbench.ans. The archived Fastfetch file was inspected for format and character usage, not copied.

New builds normalize family, full, PostScript, and face filenames to NF/NFM abbreviations with Forced distinguished. The family builder copies normalized filenames directly; the single-file wrapper preserves an explicitly requested output destination. Existing installed/generated fonts were not rebuilt or renamed. Bash and JavaScript syntax and Python compilation checks passed. FontTools is unavailable in this shell, so no real font normalization/build was run. The live page's accessible heading showed the monitor prompt; browser screenshot/file-picker checks timed out during this follow-up, so loaded-font sizing still needs manual confirmation.
