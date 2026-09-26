# Figtree Bold

Static TTF from [Erik Kennedy's Figtree repository](https://github.com/erikdkennedy/figtree), commit `032dfa7fe219ef3a02890d6d3add84eacc9aebfe`.

- Source: `fonts/ttf/Figtree-Bold.ttf`
- SHA-256: `71a35e2bd92a05427e2dc9897bab41f8a865800e148238007735b5934508198a`
- License: SIL Open Font License 1.1; see [OFL.txt](OFL.txt).
- Copyright: 2022 The Figtree Project Authors.

The build converts Bold's 407 printable BMP characters into a local `DefineCompactedFont` for the area title and panel headings. Legend rows, cycling counters, and the empty-state message use the shared GTA font. This covers Figtree's supplied Latin characters and punctuation; it does not add scripts absent from Figtree. Players do not need to install the TTF. The build reads the vendored file offline and does not install it on the build machine.

If updating the font file, update this provenance/hash and review glyph coverage, the build's expected glyph count, font/style names, and in-game rendering. Keep the license with the font.
