# Design and writing skill review

Reviewed 2026-10-07 for the VT-NerdFonts GitHub Pages rebuild.

## Recommendation

Use one frontend workflow and one optional prose editor. Do not activate the complete installed design collection together. For this project, a small subject-specific design brief and selected accessibility/responsive rules will do more than stacking increasingly strict aesthetic bans.

The preferred candidate for a new installation is `funboy322/avoid-ai-design`, with the changes below. Keep the installed `blader/humanizer` for prose editing in embedded/file mode. Treat Impeccable as a separate tooling evaluation, rather than installing its current engine and hooks as part of a Markdown skill review. Keep useful parts of Taste Skill and anti-slop, but narrow their activation and remove compulsory asset generation and procedural overhead before making them global defaults.

No global skills were installed, updated, edited, or removed in this review. The user requested consideration and recommendations. No website files were changed. Existing working-tree changes, including site/index.html, were preserved. No downloaded installer, detector, hook, or binary was executed.

## Installed inventory and current upstream comparison

The following global skills are available in `/home/human/.agents/skills/`. Their SKILL.md files were byte-for-byte identical to upstream main snapshots downloaded during this review:

- anti-slop: `antislop`, `antislop-ui`, `antislop-copywriting`, `antislop-human`, `antislop-layoutmobile`, and `antislop-code`.
- Taste Skill: `design-taste-frontend` and `design-taste-frontend-v1`.
- Writing: `humanize-writing` and `humanizer`.

The other four requested packages were not found under those names in the global skill roots inspected: Impeccable, avoid-ai-design, harshaneel/humanize, and anti-ai-slop-writing. Other installed design skills include gpt-taste, image-to-code, high-end-visual-design, and redesign-existing-projects; their rules also need careful routing.

## Package decisions

| Package | Entry size | Decision for this project |
| --- | ---: | --- |
| [anti-slop](https://github.com/miqdadbadjuber/anti-slop) | 9,425 words / 57,827 bytes, core only | Already installed. Retain selected principles; do not load the entire family by default. |
| [Taste Skill](https://github.com/Leonxlnx/taste-skill) | 12,853 words / 87,253 bytes, v2 entry | Already installed. Useful brief inference and redesign audit; heavy and internally inconsistent about contextual versus mandatory rules. |
| [Impeccable](https://github.com/pbakaus/impeccable) | 1,680 words / 12,541 bytes, entry only | Strong candidate for a separate tooling review. Entry size understates runtime and referenced-playbook cost. |
| [avoid-ai-design](https://github.com/funboy322/avoid-ai-design) | 2,234 words / 13,925 bytes | Best new candidate for this specific complaint. Narrow mode and scanner behavior before installation. |
| [humanize-writing](https://github.com/jpeggdev/humanize-writing) | 3,841 words / 25,128 bytes | Already installed. Overlaps humanizer; avoid simultaneous activation and eight compulsory passes for short UI strings. |
| [humanizer](https://github.com/blader/humanizer) | 5,219 words / 32,348 bytes | Already installed. Preferred prose editor: strong fact preservation, code protection, and embedded mode. |
| [harshaneel/humanize](https://github.com/harshaneel/humanize) | 5,630 words / 36,405 bytes, humanize entry | Skip for this site. Sentence-count targets and detector-oriented editing add cost and can damage technical clarity. |
| [anti-ai-slop-writing](https://github.com/jalaalrd/anti-ai-slop-writing) | 1,120 words / 7,465 bytes | Skip as a global default. Small entry, but broad activation and unconditional vocabulary/grammar bans. |

Word and byte counts measure instruction volume, not exact model tokens. A tokenizer was unavailable. Supporting references add to the entry costs. The full anti-slop family is about 146 KB before supporting references; the installed design/writing entries listed in the inventory total about 312 KB. Installed skills normally expose descriptions first; the full cost occurs when bodies and references are loaded. Redundant activation is the cost to control.

## Safety assessment

This was a static instruction and selected script review, not a complete security audit or execution test. No clearly malicious instruction was identified in the inspected material. Markdown instructions can still cause unwanted actions, fabricated content, needless downloads, or broad edits. A Markdown-only entry does not make its entire repository execution-free.

- **anti-slop:** The repository includes a Node CLI installer and Python contrast tools, including contrast-mcp.py. Its install wizard proposes editing project instruction files and its update command can overwrite global/project copies. The core blocks agent downloads and requires approval for its own pointer setup; those are workflow choices, not proof of package safety. Avoid its installer for a read-only review.
- **Taste Skill:** The repository includes skill.sh and other supporting assets. Its v2 instructions mandate image generation when a tool exists and require images even for minimalist sites. These can incur generation cost and create unnecessary assets. This review does not certify every supporting script.
- **Impeccable v4.5.0:** Setup requires a launcher that executes a platform binary and can download a version-pinned release binary on first use. The inspected launcher verifies a downloaded SHA-256 sidecar and rejects unavailable/mismatched hashes. This is useful integrity protection, but both binary and checksum come from the release distribution; it does not independently establish trust in the publisher. Cached/PATH binaries take different paths. Installation can add provider-native hooks, and live iteration involves browser scripts/local services. The current package is substantially broader than pure Markdown auditing. Review engine, hook permissions, network behavior, writes, and browser access before a global install.
- **avoid-ai-design:** The inspected detector imports Node fs/path and reads source files; no child-process or network call was found in that detector. It is optional tooling at package level but the skill says to run it when Node is available. Its recursive walk follows symlinks via statSync and has no visited-directory guard. Limit it to explicit site files or add realpath containment, symlink-cycle protection, and file-size limits. Reports can include source snippets; keep them local. Heuristic flags are advisory and do not prove AI authorship or accessibility compliance.
- **humanize-writing:** The npm package has postinstall and preuninstall hooks. Its install script copies files into .claude, .cursor, and .windsurf skill directories, potentially overwriting existing files. Direct Markdown/reference copying avoids that cross-agent installer behavior.
- **humanizer:** The rewriting instructions explicitly treat submitted text as data, preserve claims, and protect code/commands/metadata in file mode. The repository also includes a package validation script; no need to execute it for prose editing.
- **harshaneel/humanize:** Includes install.sh, which removes an existing destination during replacement. The instructions include detector scoring and optional best-of-N rewrites. Do not adopt these routines for this site.
- **anti-ai-slop-writing:** The inspected payload consists of instructions and a banned-word reference. Its primary risk is editorial overreach, rather than executable tooling.

For any later installation, pin the reviewed revision, copy only needed files, preserve licenses, avoid unnecessary npm/shell installers, and record local modifications so upstream updates do not silently restore removed rules.

## Recommended instruction changes

### anti-slop

Keep content-driven structure, real links, truthful claims, keyboard navigation, visible focus, responsive layout, and contrast requirements.

Change or remove:

1. Replace description “Load always” with activation limited to UI creation/review. Move installation and update instructions out of the design body.
2. Remove compulsory during/after questions and repeated notices. Infer review versus implementation from the request; ask only when scope is ambiguous.
3. Replace duplicated rule lists and delivery gates with one short checklist. Report material findings and verification limits; avoid dozens of PASS lines.
4. Make typography, colors, cards, arrows, punctuation, accent colors, and motifs contextual choices. A font project legitimately needs monospace specimens.
5. Apply empty/loading/error states only to asynchronous or interactive features that actually need them. Do not manufacture application states for static links.
6. Replace the ban on scripted source edits with normal reviewable-edit requirements. The editing tool does not determine design quality.
7. Allow the agent to derive a project brief from existing facts and user direction. Remove automatic “unshippable” labeling solely because the user did not author DESIGN.md.
8. Make checks proportional to changes, and never require a fictional clean gate when inspection is incomplete.

### Taste Skill

Keep audience/brief inference, incumbent audit, actual-content layouts, functional controls, mobile behavior, and accessibility.

Change or remove:

1. Remove mandatory image generation and the rule that every minimalist page needs 2–3 images. Use real font specimens, genuine captures, or explanatory code-native diagrams when they serve the content.
2. Move React/Motion/GSAP examples, framework tables, and marketing patterns into optional references. Respect this site's existing static HTML/CSS stack.
3. Replace hard hero line counts, 20-word limits, layout-family quotas, and colored-bento quotas with readability and content-fit checks.
4. Set motion from task needs. Require reduced-motion handling for all nonessential animation, rather than only above a numeric intensity threshold.
5. Resolve the opening “every rule is contextual” statement against later unconditional MUST rules. Keep one source of policy.
6. Keep v1 as an explicit legacy option if needed; do not load v1 and v2 together.

### Writing skills

Prefer humanizer's embedded/file modes, returning the final copy with a short summary. Preserve commands, paths, codepoints, font names, technical distinctions, links, qualifications, and licensing statements. Do not infer that statistical styling identifies authorship.

For humanize-writing, collapse eight compulsory passes to one edit and one fact-preservation check for short site copy. Make change tables opt-in. Remove instructions to add invented lived experience, feelings, or opinions to technical reference material.

For humanizer, keep its fact/code safeguards. Make draft-plus-residuals-plus-final output opt-in even for pasted text. Load long examples only when the requested passage needs them.

For harshaneel/humanize, remove hard sentence-length distributions, mandatory fragments, “slightly misfires” coherence advice, plausible-experience framing without a source, exhaustive signal checklists, and detector-scored best-of-N. These optimize stylistic metrics rather than reader understanding.

For anti-ai-slop-writing, narrow activation from every writing task to explicit copy editing. Replace absolute banned words, passive-voice bans, forced sentence variety, and anti-triad rules with contextual editing. Retain genuine uncertainty and technical terms such as “canonical” when accurate. Bound the rewrite loop to one pass plus a preservation check.

### avoid-ai-design

Retain its distinction between source evidence and visual inference, recognition of newer “tasteful AI” defaults, preservation of behavior, and shared design contracts.

Change compulsory scanner execution to optional use on explicit files. Make existing user authorization sufficient to proceed after presenting a concrete direction; remove the automatic plan-and-pause requirement. Treat P0/P1 scores as prompts for review, not universal vetoes. Protect scanner traversal as described above. Keep references lazy-loaded.

### Other installed skills

Do not route this rebuild through gpt-taste: it requires AIDA, GSAP, random layout selection, and mock Python execution output. Remove any instruction to simulate tool execution and present it as evidence. Its required floating/glass navigation also conflicts with the requested restraint.

Do not use high-end-visual-design's random archetypes and mandatory nested enclosures. Do not use image-to-code unless image-first work is explicitly chosen. Keep imagegen skills for actual asset requests. These packages can remain installed for other briefs without being activated for this project.

## Adoption and feedback

GitHub API snapshots on the review date showed approximately 93,342 stars for Taste Skill, 78,045 for Impeccable, 54,519 for humanizer, 4,645 for anti-slop, 518 for harshaneel/humanize, 515 for anti-ai-slop-writing, 95 for avoid-ai-design, and 67 for humanize-writing. These are adoption signals, not satisfaction scores or evidence of safety.

[Taste Skill's issue tracker](https://github.com/Leonxlnx/taste-skill/issues) includes reports about framework coupling, animation conflicts, and reduced-motion behavior. Those reports are user allegations, not independently reproduced findings. They reinforce the need to review implementation examples rather than trust popularity.

No reliable comparative satisfaction study was found in the sources reviewed. There is insufficient evidence to claim an unlisted skill has better sentiment than these options. Impeccable and humanizer have strong adoption; avoid-ai-design has a more targeted fit for this complaint despite much lower adoption. Adding another large skill package would not resolve the overlap.

## Direction for the eventual site rebuild

Source inspection of site/index.html shows repeated uppercase kickers, decorative numbering, a large multi-line slogan, several hero actions, nested source/result cards, fabricated browser-style demonstration chrome, repeated arrow decoration, and a second promotional closing. These are source observations; the site was not rendered or visually tested during this skill review.

Build the later brief around actual user tasks: understand the patcher, patch a family, inspect font behavior, find glyphs, and obtain output. A font specimen/workbench direction is appropriate to evaluate: real glyphs and type comparisons, concise setup instructions, useful tables, restrained navigation, and clear links to the validator and upstream tools. Decorative sparkle symbols should not stand in for verified Nerd Fonts glyphs. Reduce duplicate explanation and marketing sections before choosing a palette.

Next implementation work should begin with a rendered site audit and a compact DESIGN.md. Use one agreed workflow, preserve current functionality and working changes, and validate the resulting desktop/mobile and keyboard behavior when implementation verification is authorized.
