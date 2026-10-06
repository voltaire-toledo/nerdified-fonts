# VT-NerdFonts

## What this repository does

A font is a collection of characters and symbols. A **Nerd Font** adds icons used by terminal prompts, file listings, editors, and other developer tools. Patching a font means taking the original font files and adding those icon glyphs. A font **family** is a named collection such as Lekton; a **face** is one weight or style in that family, such as Regular, Bold, or Italic. The patcher processes each face separately.

This repository patches font families placed under `fontsrc/`, validates the patched faces, and creates one ZIP per family **and selected patch mode**. It currently includes JuliaMono and Lekton sources. You can add another family if you have its unpatched TTF or OTF files. Your source files stay in `fontsrc/`; generated fonts go in `patched/`, and family archives go in `releases/`. The project follows Nerd Fonts **patcher** release versions. It does not automatically update the original source fonts to a newer JuliaMono, Lekton, or other family release.

## How does this repo work

1. The script lists family directories under `fontsrc/` and lets you choose which to patch. A family can list several modes in `patch-modes.txt`; otherwise it uses `auto`.
2. It checks the latest stable [Nerd Fonts release](https://github.com/ryanoasis/nerd-fonts/releases), unless you supply a version. It downloads that release's `FontPatcher.zip` into `.cache/nerd-fonts-X.Y.Z/` inside this repo. The archive contains the patcher program and the versioned glyph sources.
3. Run the same guided script on a supported host or through Docker Compose. FontForge runs the patcher once for every TTF or OTF face in the chosen families. The script enables `--complete` so the patcher adds all available icon sets. By default, `auto` mode chooses single-cell-width icons for fixed-pitch fonts and normal patching for proportional fonts.
4. The scripts normalize the family and style metadata, validate Private Use Area icon coverage, then produce `patched/FontName/` and `releases/FontName-vX.Y.Z.zip` for the default mode. Additional modes get their own named directories and ZIPs, such as `JuliaMonoForced-0.63.2-v3.5.1.zip`. Each ZIP includes the available source font license and Nerd Fonts glyph notices.
5. The [GitHub](.github/workflows/release.yml) or [Forgejo](.forgejo/workflows/release.yml) release workflow can repeat the build for **committed** source families when a new Nerd Fonts version appears.

The directory names have distinct jobs:

| Path | Purpose | Kept after a successful build? |
| --- | --- | --- |
| `fontsrc/FontName/` | Original font faces and their license | Yes; your input |
| `fontsrc/FontName/patch-modes.txt` | Optional list of patch modes to build for that family | Yes; project configuration |
| `.cache/nerd-fonts-X.Y.Z/` | Downloaded `FontPatcher.zip`, extracted `font-patcher`, and `src/glyphs/` | Yes; reused for that version |
| `patched/FontName/` | Patched font faces | Yes |
| `releases/FontName-vX.Y.Z.zip` | One archive per family, including licenses | Yes |
| `patched/FontName/.work.*/` | Working font and `fontforge.log` for one face | Removed after that face finishes; may remain after interruption |

The generated directories and cache are excluded by [.gitignore](.gitignore); the original fonts under `fontsrc/` are not ignored. A local family with a license that prohibits redistribution must remain uncommitted and unpublished.

## The Nerd Fonts Patcher

![Nerd Fonts Patcher logo](https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/images/nerd-fonts-patcher-logo.png)

The [Nerd Fonts Font Patcher](https://github.com/ryanoasis/nerd-fonts#font-patcher) is an upstream Python program run through FontForge. It reads an original font face, takes icons from separate glyph source files, maps them into icon codepoints, adjusts icon size and spacing according to its options, and writes a new font. Its `--complete` option selects all supported icon collections. The program alone is insufficient: Nerd Fonts says its helper and glyph files must be downloaded with it. This repo gets the program and `src/glyphs/` from the **same versioned release archive** and passes that directory through `--glyphdir`.

A release may change the glyph source files, the patcher's mapping rules, or both. Rebuilding the same source font with a newer Nerd Fonts release can therefore add icons or change how an icon is placed. The resulting family ZIP has the Nerd Fonts release version in its filename. The original font's own version is independent of that number.

## Types of Nerd Fonts

Nerd Fonts names describe how the added icons use character width. A **cell** is one character position in a terminal grid. A fixed-pitch or monospaced font normally advances by the same width for every character; a proportional font does not. The [upstream explanation](https://github.com/ryanoasis/nerd-fonts/discussions/1103) and [FAQ](https://github.com/ryanoasis/nerd-fonts/wiki/FAQ-and-Troubleshooting) distinguish these variants:

| Name you may see | Meaning | Typical use |
| --- | --- | --- |
| `Nerd Font` or `NF` | Standard variant; icons may visually extend into the next cell while retaining a cell advance | Terminal use when larger icons are desired |
| `Nerd Font Mono` or `NFM` | `--mono` variant; added icons fit into one cell, and it requires a monospaced source font | Terminals that require strict cell alignment |
| `Nerd Font Propo` or `NFP` | Proportional variant; icon advance width follows its visual width | GUI text and other proportional layouts |

`NF`, `NFM`, and `NFP` are shorter **name abbreviations**, not separate icon collections or licenses. A font whose original name contains “Mono” is a monospaced **source family**; that word alone does not say which Nerd Fonts patch mode was applied. “Monotype” is not a Nerd Fonts patch variant.

This repo has additional patch policies. Its `normal` mode uses upstream `--careful` to preserve existing glyphs at conflicting codepoints; `mono` adds `--mono`. Its project-specific `forced` and `forced-mono` modes allow replacement at conflicts. `auto` chooses `mono` or `normal` per source face. The wrapper currently has no `Propo` mode. Its name normalizer reports both `normal` and `mono` as `SourceFamily Nerd Font`, and both forced modes as `SourceFamilyForced Nerd Font`. Consequently, do not install different modes with the same reported family and style at the same time; the operating system may choose one unpredictably. The folder and ZIP names reflect the source directory and mode, while the displayed family name comes from the font's internal metadata.

| This repo's mode | Patcher behavior | Display family pattern |
| --- | --- | --- |
| `auto` | Picks `mono` for fixed-pitch faces, `normal` for proportional faces | `SourceFamily Nerd Font` |
| `normal` | `--complete --careful` | `SourceFamily Nerd Font` |
| `mono` | `--complete --careful --mono` | `SourceFamily Nerd Font` |
| `forced` | `--complete` with replacement policy | `SourceFamilyForced Nerd Font` |
| `forced-mono` | Replacement policy plus `--mono` | `SourceFamilyForced Nerd Font` |

### Forced, width, and padding: which should you choose?

**Forced describes what happens at a codepoint conflict.** In this repo, `normal` and `mono` pass `--careful`: if the source font already has a glyph at an icon's target codepoint, that source glyph stays and the Nerd Fonts icon at that position is omitted. `forced` and `forced-mono` omit `--careful`, so the incoming icon may replace the source glyph. The word “Forced” in this repo's family name is a local naming convention, not an upstream Nerd Fonts width category. Forced patching can remove a source font's existing icons or symbols at overlapping codepoints. It does **not** make icons wider, narrower, closer to cell edges, or more monospaced. [Nerd Fonts documents `--careful` separately from its width options](https://github.com/ryanoasis/nerd-fonts/wiki/ScriptOptions).

**Mono, standard NF, and Propo describe width behavior.** Upstream `--mono` makes the added icons one cell wide and also forces preexisting glyphs into the standard cell. Standard `Nerd Font` icons can be drawn wider while still advancing one cell, so they may overhang the next cell. `Nerd Font Propo` lets the icon's advance follow its visual width; it is intended for proportional layout and is not available through this repo's wrapper. You can choose `forced-mono` to combine the conflict policy with mono width. You cannot request Propo from this repo's guided script today.

| What you want | Best starting point | Important limit |
| --- | --- | --- |
| Added Nerd Fonts icons should occupy exactly one terminal cell | A truly monospaced source plus this repo's `mono` mode, or default `auto` when it identifies the face as fixed-pitch | The icon's **advance** fits one cell; visible strokes may still have side bearings or look smaller than letters |
| Keep an original symbol already present at an icon codepoint | `normal` or `mono` (`--careful`) | The colliding Nerd Fonts icon will be absent |
| Prefer the Nerd Fonts icon over an original symbol at the same codepoint | `forced` or `forced-mono` | The original glyph can be overwritten; “Forced” does not control width |
| Larger terminal icons with less apparent empty space | `normal` on a monospaced source; `forced` only if replacement is also wanted | Standard icons may extend into the next cell; leave a blank after icons if they visually collide with text |
| Icons whose spacing follows their drawn width in a GUI | Upstream `Nerd Font Propo` | This repo does not expose Propo through `patch_fonts.sh` |
| Every emoji and embedded symbol must have precisely the same visible width as letters | No patch mode can guarantee this | Emoji may come from a separate fallback font and may occupy two terminal cells; an existing glyph can have internal whitespace even if its advance is one cell |
| A sequence such as `<-` becomes one drawn glyph with exact alignment | Choose a source font with the desired ligature, then test it in the target terminal or editor | A ligature replaces a **sequence** of characters during text shaping. Nerd Fonts width mode does not create that ligature or guarantee its two-character advance or visual margins |

If “padding” means the empty visual space inside a character cell, there is no universal zero-padding switch. The patcher controls glyph scale and advance width, while the source glyph's outline and the terminal's cell metrics also matter. `mono` protects the grid but often makes icons look smaller. Standard NF makes icons look fuller but permits overhang. Propo gives an icon a wider advance and suits interfaces without a fixed grid. Compare a few actual icons in the application you use before deciding; [the upstream explanation shows these three layouts](https://github.com/ryanoasis/nerd-fonts/discussions/1103).

## Quickstart: Patch fonts locally

1. Clone the repository and enter it:

   ```bash
   git clone https://github.com/voltaire-toledo/nerdified-fonts.git
   cd nerdified-fonts
   ```

   | Command | Option or argument | Meaning |
   | --- | --- | --- |
   | `git clone` | Repository URL | Downloads this project into `nerdified-fonts/` |
   | `cd` | `nerdified-fonts` | Makes the project your working directory |

2. Download an **unpatched** font from its publisher. Extract each family's `.ttf` or `.otf` files into its own directory, for example `fontsrc/MyFont/`. Nested directories are allowed. Put the font's license in the same family directory. Do not add a font that is already patched with Nerd Fonts icons. Check the source font's terms before committing it or sharing patched copies. If you want multiple variants, add `patch-modes.txt` to that family directory with one mode per line (`auto`, `normal`, `mono`, `forced`, or `forced-mono`); blank lines and lines starting with `#` are ignored. The bundled [JuliaMono configuration](fontsrc/JuliaMono-0.63.2/patch-modes.txt) requests both `auto` and `forced`.
3. Start the guided build:

   ```bash
   ./scripts/patch_fonts.sh
   ```

   | Command | Option or argument | Meaning |
   | --- | --- | --- |
   | `./scripts/patch_fonts.sh` | None | Installs dependencies on supported systems, lists available families, asks for a selection, shows the Nerd Fonts version and mode, and asks to proceed |

4. When the script completes, open `patched/FontName/` for the default faces or `releases/FontName-vX.Y.Z.zip` for the default archive. A configured extra mode has its own output, such as `patched/JuliaMonoForced-0.63.2/` and `releases/JuliaMonoForced-0.63.2-vX.Y.Z.zip`. The script prints the output root locations and cached patcher path. It does not install the fonts into your operating system.

On Debian/Ubuntu the installer needs `sudo`; on Homebrew systems it uses `brew`. It installs FontForge, Python/fontTools, curl, and unzip. If these dependencies are already available, skip that installation step. For an unattended build of every family:

```bash
./scripts/patch_fonts.sh --all --yes --no-install
```

| Command | Option or argument | Meaning |
| --- | --- | --- |
| `./scripts/patch_fonts.sh` | `--all` | Select every directory under `fontsrc/` |
| `./scripts/patch_fonts.sh` | `--yes` | Accept the displayed version and selection without a prompt |
| `./scripts/patch_fonts.sh` | `--no-install` | Use dependencies already installed in the environment |

Other options:

| Option | Argument | Meaning |
| --- | --- | --- |
| `--font` | A `fontsrc/` directory name | Select one family; repeat the option for several |
| `--version` | `X.Y.Z` | Patch with a specific Nerd Fonts release instead of checking latest |
| `--mode` | `auto`, `normal`, `mono`, `forced`, or `forced-mono` | Override each selected family's `patch-modes.txt` with one mode; absent an option or config file, default is `auto` |
| `--no-install` | None | Skip automatic dependency installation |
| `--yes` | None | Run without the confirmation prompt; also pass `--all` or `--font` in noninteractive use |

### Use the patched font

A successful build creates files; it does not register them with your operating system. On Windows, extract the desired ZIP and install the `.ttf` or `.otf` faces with the Windows font installer. Then select the **patched family name** in your terminal or editor's font settings. A terminal running inside WSL still uses fonts installed on the Windows side. On Linux, place the desired patched faces in your user font directory and refresh the font cache:

```bash
mkdir -p ~/.local/share/fonts/MyFontNerd
cp patched/MyFont/*.ttf ~/.local/share/fonts/MyFontNerd/
fc-cache -f
```

| Command | Option or argument | Meaning |
| --- | --- | --- |
| `mkdir` | `-p`, destination directory | Create the user font directory if needed |
| `cp` | Source font glob, destination directory | Copy the patched TTF faces; use `*.otf` instead if that family produces OTF files |
| `fc-cache` | `-f` | Refresh Linux font discovery |

Install only the patch mode you intend to use when two modes report the same family and style name.

### Windows and containers

Docker Compose provides the container path on Windows, Linux, and macOS. Install Docker Desktop (or Docker Engine with the Compose plugin) and start it. In PowerShell, clone this repository, enter its directory, put each unpatched font family and its license under `fontsrc/FontName/`, then run:

```powershell
docker compose run --build --rm patcher
```

| Command | Option or argument | Meaning |
| --- | --- | --- |
| `docker compose run` | `--build` | Build this project's small image using the official `nerdfonts/patcher:4.26.0` image as its FontForge runtime |
| `docker compose run` | `--rm` | Remove the one-off container when patching finishes |
| `docker compose run` | `patcher` | Run the guided family selection and version confirmation inside the container |

For a repeatable unattended build of selected families:

```powershell
docker compose run --build --rm -T -e JOBS=4 patcher --font MyFont --version 3.5.1 --yes
```

| Command | Option or argument | Meaning |
| --- | --- | --- |
| `docker compose run` | `--build` | Build or refresh the local project image before this run |
| `docker compose run` | `--rm` | Remove the one-off container afterward |
| `docker compose run` | `-T` | Disable the terminal allocation for unattended use |
| `docker compose run` | `-e JOBS=4` | Allow up to four font faces to be patched at once; adjust for available memory |
| `docker compose run` | `patcher` | Use this repo's container service |
| `patcher` | `--font MyFont` | Build one directory under `fontsrc/`; use `--all` for every family |
| `patcher` | `--version 3.5.1` | Use this Nerd Fonts **release**; omit it to check the latest stable release |
| `patcher` | `--yes` | Skip the confirmation prompt |

The container runs [the same script](scripts/patch_fonts.sh) as the host path with dependency installation skipped. [The Dockerfile](Dockerfile) adds Bash, curl, unzip, and fontTools to the [official Nerd Fonts patcher image](https://hub.docker.com/r/nerdfonts/patcher). The image's `4.26.0` tag identifies its bundled patcher program, **not** the Nerd Fonts release used for output. This repo downloads `FontPatcher.zip` and `src/glyphs/` for the selected release into `.cache/nerd-fonts-X.Y.Z/`, then runs those downloaded files through the container's FontForge. The ZIP version is therefore the selected Nerd Fonts release, such as `v3.5.1`, in either environment.

[The Compose file](compose.yaml) mounts the repository at `/workspace`, so `fontsrc/`, `.cache/`, `patched/`, and `releases/` are the same folders on your computer. Files from a container run remain after the container exits. The [`.dockerignore`](.dockerignore) keeps your fonts and generated ZIPs out of the image build context; it does not exclude them from the run-time mount. On Linux, Docker may create root-owned output files when run as root in the container. You can supply your host numeric user and group with Compose's `-u` option if needed. On Windows, keep the project in a drive shared with Docker Desktop. The host path remains available through `./scripts/patch_fonts.sh` on Debian/Ubuntu or Homebrew, and through a compatible WSL environment. The WSL host path has not been validated end to end by this project.

### Files kept after a build

- `.cache/nerd-fonts-X.Y.Z/` retains `FontPatcher.zip`, the extracted `font-patcher`, and `src/glyphs/`. This is inside the repo and ignored by Git. The direct fetch script also defaults to this location regardless of your current working directory.
- `patched/FontName/` retains the patched faces; `releases/` retains one ZIP per built family. These paths are ignored by Git.
- A face is built in `patched/FontName/.work.*/`, with its `fontforge.log` there. The work directory is normally removed when the face finishes. A killed or interrupted run can leave it behind. The main script reports any such directories when it completes.
- The older `build_family.sh` and `patch_ttf.sh` scripts use the system temporary directory, usually `/tmp` on Linux, and remove their temporary directories on normal exit. The main guided script does not retain a temporary directory outside this repo.

The cache can be deleted after you no longer need that Nerd Fonts version; a future build will download it again. Deleting `patched/` or `releases/` removes local results and requires a rebuild. Check for a running FontForge process before removing a `.work.*` directory.

## Automated releases

The [GitHub Actions workflow](.github/workflows/release.yml) checks for the latest stable Nerd Fonts release at 04:17 UTC each day and can also be started manually. If this repo already has a release with that version tag, it skips the build. Otherwise it patches every family **committed** under `fontsrc/`, validates the fonts, and publishes a `vX.Y.Z` release with one ZIP per configured family mode. JuliaMono therefore publishes separate regular and Forced ZIPs. It uses a GitHub Actions token with `contents: write` permission. A manual run does not add assets to an already existing release because of the current skip check.

The [Forgejo Actions workflow](.forgejo/workflows/release.yml) runs at 04:37 UTC daily or on manual dispatch. It currently rebuilds all committed families every time. Its upload script skips ZIPs already attached to the matching release. Configure the Forgejo repository variable `FORGEJO_API_URL` with the instance's API base URL and the secret `FORGEJO_TOKEN` with release write access. Its Ubuntu runner needs `sudo` and `apt-get`.

These schedules respond to **Nerd Fonts patcher releases**. They do not fetch updated source fonts, and they cannot see a family kept only in your local checkout. Inspect the font licenses before committing source files or publishing their ZIPs. The locally tested Input fonts, for example, prohibit distribution of modified copies and must stay local.

The publishing script can upload local archives when the provider, repository, token, and (for Forgejo) API URL are supplied in environment variables. Its version argument selects the matching release tag:

```bash
python3 scripts/publish_release.py 3.5.1
```

| Command | Option or argument | Meaning |
| --- | --- | --- |
| `python3` | `scripts/publish_release.py` | Runs this repo's release uploader |
| `publish_release.py` | `3.5.1` | Creates or updates tag `v3.5.1` with ZIPs matching that version |
| Environment | `RELEASE_PROVIDER` | `github` or `forgejo` |
| Environment | `RELEASE_REPOSITORY`, `RELEASE_TOKEN` | Target `owner/repo` and a token with release write access |
| Environment | `RELEASE_API_URL` | Forgejo API base URL; not needed for GitHub |

The legacy `build_family.sh` and `patch_ttf.sh` scripts remain available for individual builds. Use `patch_fonts.sh` for the guided, validated, per-family ZIP workflow.

## Website

The static project page lives in [`site/`](site/). It explains the patching flow with diagrams, links to the official [Nerd Fonts Icon Finder](https://www.nerdfonts.com/cheat-sheet), and includes screen captures from [Programming Fonts](https://www.programmingfonts.org/) that compare box drawing in two unpatched source fonts. The captures demonstrate why you should test the final patched font in your own terminal as well. The [GitHub Pages workflow](.github/workflows/pages.yml) publishes that directory when its files change on `main` or when manually dispatched. In GitHub repository settings, Pages must use **GitHub Actions** as its build and deployment source; the workflow needs the repository's Pages permissions. The expected project URL is `https://voltaire-toledo.github.io/nerdified-fonts/` after a successful deployment.

Forgejo Actions can run a deployment job, but a Forgejo instance does not automatically provide a GitHub Pages equivalent. A Forgejo administrator needs to provide a static web host (or a separate Pages service such as Codeberg Pages) and its deployment credentials. The same `site/` directory can be served there without a build step. This repository does not configure a Forgejo publishing target because no Forgejo host or Pages service has been specified.

## Troubleshooting

| Symptom | Likely cause | What to do |
| --- | --- | --- |
| No families appear | `fontsrc/` has no family directories containing TTF or OTF files | Check the extraction path and file extensions; each family needs its own directory |
| The script asks for `sudo` or says a package is missing | Dependencies are not installed, or package installation lacks permission | Install the listed dependencies in a supported environment, or rerun with `--no-install` once they are available |
| The patcher rejects `--mono` | The source face is proportional | Use the default `auto` mode or `normal` instead of forcing `mono` |
| A font family has duplicate or unexpected names in the terminal | Multiple patch modes or old copies with the same internal family/style are installed | Remove duplicate installed faces, refresh the font cache, and select the intended patched family |
| Icons are missing after a successful build | The terminal may be using another installed font, or an app may expect icons from a different Nerd Fonts version | Check the terminal's font setting and the app's icon version; see the [upstream FAQ](https://github.com/ryanoasis/nerd-fonts/wiki/FAQ-and-Troubleshooting) |
| `.work.*` remains | A build was interrupted | Stop the build process, inspect `fontforge.log` inside that directory, then rerun the family; the next run removes old patched font files |
| A release lacks a newly added family | GitHub skips tags that already have a release; CI only sees committed source families | Add a permitted family to `fontsrc/` and publish with a later Nerd Fonts release, or revise the release workflow's skip behavior |

For a local family whose patching is complete, run the validator again if you want to inspect its reported family, style, total mapped characters, and Private Use Area icon count:

```bash
./scripts/validate_fonts.sh patched/MyFont
```

| Command | Option or argument | Meaning |
| --- | --- | --- |
| `./scripts/validate_fonts.sh` | `patched/MyFont` | Validate every patched TTF or OTF in that family directory |

A ZIP can be checked for archive corruption with:

```bash
unzip -t releases/MyFont-v3.5.1.zip
```

| Command | Option or argument | Meaning |
| --- | --- | --- |
| `unzip` | `-t` | Test ZIP entries and CRCs without extracting them |
| `unzip` | `releases/MyFont-v3.5.1.zip` | Archive to check; replace the family and version with yours |

## License

- This repo's original scripts, workflows, and documentation are under the [MIT License](LICENSE).
- [Nerd Fonts uses several licenses](https://github.com/ryanoasis/nerd-fonts/blob/master/LICENSE). Its original patcher code is MIT licensed. Its patched fonts and glyph sources carry the SIL Open Font License 1.1 and other terms detailed in its [license audit](https://github.com/ryanoasis/nerd-fonts/blob/master/license-audit.md). Using that patcher does not erase the original font's license. The ZIPs from this repo include available Nerd Fonts glyph license notices.
- The bundled [JuliaMono](fontsrc/JuliaMono-0.63.2/OFL.txt) and [Lekton](fontsrc/Lekton/OFL.txt) source fonts are under the SIL Open Font License 1.1. Their copyright and license notices must accompany redistributed patched versions.
- Fonts you add keep their own license terms. The locally tested Input fonts allow personal modifications but prohibit distributing modified versions, so their patched ZIPs must stay local. Check each new font's terms before committing its source files or publishing a release.
