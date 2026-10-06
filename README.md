# VT-NerdFonts

Patch your own font families with the official [Nerd Fonts Font Patcher](https://github.com/ryanoasis/nerd-fonts#option-9-patch-your-own-font). The script uses the upstream release archive, including the patcher's required glyph files. It runs FontForge with `--complete` and, by default, `--mono` for single cell icon widths.

## Patch fonts locally

1. Clone this repository.
2. Download clean, unpatched fonts and extract each family into `fontsrc/FontName/`. TTF and OTF files can be nested inside that directory. Keep the font's license file there too.
3. Run `./scripts/patch_fonts.sh`. On Debian/Ubuntu or Homebrew systems it installs the required packages, lists the available families, asks which to patch, checks the latest [Nerd Fonts release](https://github.com/ryanoasis/nerd-fonts/releases), shows the version, and asks you to proceed.
4. Find patched files in `patched/FontName/` and one `releases/FontName-vX.Y.Z.zip` per selected family. Each ZIP includes the available source license files.

For an unattended build, run `./scripts/patch_fonts.sh --all --yes`. Use `--font FontName` (repeatable) to choose families, `--version X.Y.Z` to pin an upstream release, or `--no-install` if dependencies are already present. `--mode normal` uses `--careful`; `mono` adds single cell icon widths; `forced` and `forced-mono` allow glyph replacement. The latter two use the project's `Forced Nerd Font` family naming convention. Font licensing remains the responsibility of the distributor.

The patcher output is validated for family metadata and Private Use Area glyph coverage. The archive is made only after that validation succeeds. The `.cache/`, `patched/`, and `releases/` directories are generated and ignored by Git.

## Automated releases

The GitHub Actions and Forgejo Actions workflows check the latest stable Nerd Fonts release daily. For a new upstream version, they rebuild every family present in the checked out `fontsrc/` tree and publish a matching `vX.Y.Z` release with a ZIP for each family. GitHub uses its built in `GITHUB_TOKEN` with contents write permission. For Forgejo, configure repository variable `FORGEJO_API_URL` (for example `https://forge.example/api/v1`) and secret `FORGEJO_TOKEN` with release write access. The Forgejo runner needs an Ubuntu image with `sudo` and `apt-get`. Both workflows can also be started manually.

To publish archives built locally, set `RELEASE_PROVIDER` (`github` or `forgejo`), `RELEASE_REPOSITORY` (`owner/repo`), `RELEASE_TOKEN`, and for Forgejo `RELEASE_API_URL`, then run `python3 scripts/publish_release.py X.Y.Z`. Publishing is idempotent for archives already attached to the matching release.

The legacy `build_family.sh` and `patch_ttf.sh` scripts remain available for individual builds. The main workflow is `patch_fonts.sh`.
