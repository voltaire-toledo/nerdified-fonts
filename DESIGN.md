# vt/nerdified-fonts design contract

## Direction

A font workbench for people patching and inspecting their own font families. Monospaced typography, font specimens, file paths, real commands, comparison tables, and actual browser captures provide the visual vocabulary. The landing page helps visitors act; the validator remains a tool.

## Remove

Remove the slogan-heavy hero, italic accent phrase, status badges, sparkle branding, decorative numbering, fabricated browser/search chrome, metric strip, repeated card grids, ornamental arrows, and closing sales pitch. Consolidate duplicate patch explanations. Keep meaningful setup steps as an ordered list. Do not use serif type for headings.

## Change

Use a split intro with a one-time plain-to-patched file-list transition. The list keeps the same file names while actual Nerd Font glyphs, language marks, and color appear. Reduced-motion users see the patched view directly. Use a compact patch setup, icon width specimens, a semantic width table, and real font test captures. Light mode pairs the JuliaMono-based specimen face with Lekton headings. Dark mode uses thin TUI rules, one-character rounded corners, restrained colored glyphs, and gradients behind the demo panels. No heading uses a serif face.

## Add

Add a nav button labeled “Validate fonts,” a persistent three-mode theme button, retro motion controls, locally generated retro image assets, and inline validator load feedback. Move the validator into site/ so the publishing directory is self-contained. Its glyph samples must always use the loaded font, regardless of UI theme.

## Shared tokens

| Role | Light | Dark | Fun |
| --- | --- | --- | --- |
| Page | #f7faf8 | #0c1418 | #ffff00 with grain texture |
| Surface | #ffffff | #101e22 | #00ffff |
| Text | #172d2c | #dceee8 | #240040 |
| Secondary | #536d69 | #9db8b2 | #411255 |
| Action | #166b63 | #79dfc6 | #800080 |
| Rule | #b9cbc5 | #34535a | #48005a |

The stylesheet is the implementation source of truth. Light/dark share structure and spacing. The fun theme keeps the user-requested yellow/cyan/magenta palette, grain, a looping four-frame disk GIF at two frames per second, marquee text, and outset/inset borders, with monospaced text and headings. The retro art is intentionally low resolution. Avoid invented visitor counts, testimonials, or claims of browser compatibility.

## Layout and components

1120px main reading width; validator can expand to 1440px. Intro and setup use two columns above 760px and one below. Font results scroll horizontally inside a named keyboard-focusable region. Navigation wraps naturally on narrow screens. Buttons have at least 44px height. Light mode uses restrained flat surfaces and thin rules. Dark mode uses thin rules, one-character radii, and subtle teal gradients in the TUI specimen.

Both pages use styles.css and theme.js. The theme button cycles light → dark → fun → light. First visit follows system light/dark preference; explicit choices persist under vt-nerdfonts-theme. Old validator light/dark choices are accepted as a migration fallback. Reduced-motion preference pauses retro motion; the visible pause control stops both the marquee and GIF by selecting its still frame. Paused choice persists. Essential content never depends on animation.

## Skill routing

avoid-ai-design leads the audit and rebuild. Taste Skill supplies brief inference and selective hierarchy guidance. anti-slop supplies content truth, meaningful controls, and selected accessibility/responsive principles. humanizer edits prose while preserving factual qualifications and code. humanize-writing is an alternative editor, not a second pass over the same copy. Impeccable is not installed; its tooling requires a separate review. harshaneel/humanize and anti-ai-slop-writing remain reviewed alternatives. gpt-taste, high-end-visual-design, image-to-code, and imagegen workflows are unsuitable as automatic defaults here.

The user's requested fun aesthetic overrides generic anti-cliché bans in that theme. Do not force generated photography, GSAP, React, randomized layout selection, elaborate skill setup wizards, or long mandatory PASS reports into this static project. Keep validator wording stable while the visual theme is being selected. Report actual inspection limits and unresolved defects.

## Requested refinements

Brand labels use vt/nerdified-fonts. The setup section uses the direct heading “Keep your mono. Add the icons.” The landing page specimen font is a small, licensed subset with the actual Nerd Font codepoints used in the examples; attributions and license files live under site/fonts/. Validator preview defaults to 12 pt; its point sizes convert to CSS pixels for all glyphs, diagrams, ANSI samples, and advance measurements. Descriptive UI copy keeps its reading size. Original ANSI artwork lives in site/samples/font-workbench.ans with its browser representation in ansi-sample.js.
