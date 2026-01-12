# Fonts

This repository vendors the fonts needed to compile the Typst templates with consistent typography across machines.

- Titles / subtitles / headings: **Inter Tight**
- Body text: **Geist Regular**

Note: Typst currently warns that variable fonts may render incorrectly, so this repo vendors **static TTF instances** (Regular/SemiBold/Bold + italics) for Inter Tight and Geist.

## How Typst finds these fonts

When compiling, pass the folder as a font path:

- `typst compile --font-path fonts <file>.typ`
- `typst watch --font-path fonts <file>.typ`

(Alternatively, set `TYPST_FONT_PATHS=fonts` in your shell environment.)

## Licenses

Both families are licensed under the **SIL Open Font License 1.1 (OFL-1.1)**.

- Inter Tight: see `fonts/InterTight/OFL.txt`
- Geist: see `fonts/Geist/OFL.txt`
