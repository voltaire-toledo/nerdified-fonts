# Project handoff

Onboard yourself to this repo and read the HANDOFF.md to pick up where we left off.

## Current task

Continue the static site redesign for Nerdified Fonts. The user is reviewing prototypes before changing the production homepage.

## Decisions and feedback

- The user preferred the Jules Monitor layout and Build Trace's three-step workflow.
- Combine those in `site/prototypes/dark-set/jules-monitor.html`.
- The hero title should say only `nerdified-fonts`, centered. The user wants a PNG wordmark in the style of the sample PNGs in `site/samples/`, with an 80s look using flames or metallic gold. They asked specifically for a Gemini image-generation model.
- Do not render or copy `.ans` files into the page. Use a PNG wordmark. The current page has centered sans-serif text as a temporary placeholder because no Gemini image-generation tool was available in the previous environment.
- The previous environment exposed only the built-in image generator, not Gemini. Do not silently substitute a different model. Confirm Gemini availability in the new system and create the requested transparent PNG if available.
- Keep the three real steps accurate: choose source TTF/OTF files and include their license under `fontsrc/FontName/`; run `./scripts/patch_fonts.sh`; inspect generated faces under `patched/` and archives under `releases/`. Link to `site/validation.html` for glyph comparison.
- Use sans-serif headings. Keep the graphite dark theme with marigold/burnt-yellow accents. No mint/light green, purple, or amber.
- Avoid slogan copy in the “not X, but Y” contrastive pattern. The user called it corrective contrast/antithesis and dislikes it.
- Leave the production homepage and validator unchanged until the user chooses a design direction.

## Prototype files

- `site/prototypes/index.html` links to the current dark prototype set.
- `site/prototypes/dark-set/index.html` shows four prototypes side by side.
- `merge-room.html`, `motion-study.html`, and `build-trace.html` are the other dark design studies.
- Shared styling and responsive behavior live in `site/prototypes/dark-set/prototypes.css`.
- The current design contract is `site/prototypes/dark-set/DESIGN.md`.

## Last checks

- `avoid-ai-design` scanner: 0 findings in `site/prototypes/dark-set/`.
- `antislop-copywriting` linter: passed for `jules-monitor.html`.
- No browser screenshot/render review was done. Ask the user to review the live prototype pages for visual spacing and hierarchy.
