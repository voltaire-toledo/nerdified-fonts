# Editing the ANSI sample

Edit `font-workbench.txt` in a UTF-8 text editor using a monospaced font. Use spaces, not tabs. Preserve the horizontal positions of borders. The artwork is 26 character cells wide; shorter lines are padded automatically.

From the repository root run:

```sh
python3 scripts/generate_ansi_sample.py
```

This updates `font-workbench.ans` and `site/ansi-sample.js` together. The script uses only Python's standard library. It rejects empty artwork, lines over 26 characters, and embedded tabs/control codes before changing either output.

Do not edit the generated `.ans` or `.js` directly: their color codes and escaping are generated for you. To change colors, edit `COLORS` in the generator. UTF-8 characters are counted as individual cells; a terminal using fallback or double-width glyphs can still render them differently.

Preview in the validator or use `cat site/samples/font-workbench.ans` from the repository root. The browser preview uses line-height 1, zero letter spacing, and disabled ligatures to keep cell boundaries adjacent. In a terminal, use normal cell spacing and a font with the required glyphs.
