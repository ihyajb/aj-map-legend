# Scaleform editing notes

Practical lessons from editing GTA V Enhanced's `pause_menu_pages_map.gfx` with JPEXS 23.0.1. Start here before another Scaleform edit. These are findings from this movie and toolchain, not guarantees about every GTA movie or JPEXS version.

## Problems we hit

| Symptom | Cause or lesson | What worked |
| --- | --- | --- |
| Every legend label became `NaN` | Decompiled property syntax did not preserve Rockstar's working data-access path. Some inherited properties have empty getters. | Keep explicit `__get__data()` / `__set__data()` calls and inspect compiled bytecode. |
| Panel existed but said **No locations** | The JPEXS compiler could omit the initializer in AS2 `for(var i = 0; ...)` loops. Source tests alone missed the compiled behavior. | Use a separately initialized variable and a `while` loop. Test code decompiled from the built movie too. |
| Text became square boxes | A font alias or requested weight did not guarantee usable glyphs were loaded. | Embed the required font face, match its name/style, and check serialized glyph outlines and text bindings. |
| Text formatting did not stick | Assigning new text can lose the intended formatting. | Set `.text`, then apply `setTextFormat()`; also set `setNewTextFormat()` for later text. |
| Edited movie appeared unchanged in-game | The frontend movie remained cached. | Restart the resource, fully exit FiveM, then reconnect. Reopening the map alone was insufficient. |
| Labels or click targets no longer fit after font changes | Text width changed while old geometry/hit regions assumed the previous font. | Measure text and cycling controls, reserve badge space, then shrink/truncate labels. Derive click regions from the actual controls. |

## Preserve the native contract

The movie is a presentation layer fed by GTA. Trace callbacks, base classes, and shared imports before rewriting it. Export related shared movies when the class definition is not in the target movie.

For this map:

- `SET_TITLE(str)` receives the live area label as one string. It does not calculate a zone or receive separate zone/street objects.
- `SET_DESCRIPTION()` originally fills the two map-ruler labels. Those are map-scale values, not waypoint distance.
- Legend rows contain names, RGB values, icon linkage, grouped counts, visibility and a native new-item flag. They do not contain all the server's blip configuration.
- Full slot arrays and item data have different offsets: the label is full-slot `[6]` but item-data `[0]`. Inspect the base setter before reading indexes.
- Native slot IDs and selected subindexes drive navigation. Keep a separate visual order when grouping/sorting; never reorder the native data array or treat an internal entry ID as a confirmed blip handle.
- Reused row clips must reset state on every update. Otherwise badges, icons or selection styling can leak onto another location.

Preserve explicit accessors where this hierarchy requires them:

```actionscript
super.__set__data(_d);
var rowData = this.__get__data();
var nativeId = this.__get__uniqueID();
```

JPEXS may pretty-print these calls as properties when exporting source. That is why [build.ps1](../build.ps1) checks the P-code for the accessor name followed by `CallMethod`, rather than trusting the decompiled appearance.

Use this loop pattern in edited AS2:

```actionscript
var i = 0;
while(i < items.length)
{
   // Process items[i].
   i++;
}
```

This compiler workaround applies to imported AS2, not the JavaScript font helper.

## Fonts: embed and verify

Setting `TextFormat.font`, enabling `embedFonts`, installing a Windows font, or copying a TTF into the resource does not embed that font in the movie.

Our working approach is in [src/embed-font.js](../src/embed-font.js):

1. Read the licensed static TTF and register it with JPEXS's font API. Initialize the font registry before `addCustomFont()`.
2. Create a local GFx `DefineCompactedFont`, including glyph outlines, metrics and the intended style flags. Our helper preserves the base flags explicitly because JPEXS 23's compacted-font style setters can clear other bits.
3. Insert the font before text definitions, update character IDs, and bind only the intended existing text fields. Dynamic fields select the embedded family and matching weight.
4. Save, reopen, and verify glyph codes, nonempty outlines, style flags and bindings. Repeat checks after ActionScript import.

Our Figtree Bold face contains 407 printable BMP characters. That count, the `Figtree` family, and text character ID `139` are **specific to this asset**; inspect another movie rather than copying those constants. Unsupported characters still need another font/coverage strategy. Keep the font license and provenance with the source.

Native body text currently uses `$Font2_cond_NOT_GAMERNAME`. Match `bold` and `italic` to an available face. Do not request an absent style or replace every shared font binding just to change one heading.

## Repeatable workflow

1. Extract the original GFX read-only using CodeWalker. Keep it as a build template: it contains symbols, imports and untouched scripts, not just the edited classes. Do not overwrite the game's RPF archives.
2. Export scripts with JPEXS, identify the relevant callbacks, and keep editable classes under `src/scripts`. Use Git instead of numbered working copies.
3. Make the smallest change, preserving native callbacks and IDs. Account for safe-zone positioning and both fullscreen and normal page layouts.
4. Build a temporary candidate, inspect its fonts and bytecode, and run behavioral checks against both source and decompiled output. Replace the streamed movie only after checks pass.
5. Restart and inspect in-game: empty/populated lists, long and accented labels, scrolling, selection, cycling, reopening, and safe-zone settings. The Node harness does not render GFx or prove native input dispatch.

For this resource, run from its directory:

```powershell
node .\test-layout.cjs
.\build.ps1
```

The build already runs the test harness; the standalone command is useful during iteration. It requires Node, JPEXS 23.0.1 and **Java 8 with Nashorn** for the font helper. A Java runtime without Nashorn cannot run this helper unchanged. The script isolates JPEXS preferences using a temporary `APPDATA` and `-Duser.home`, then restores `APPDATA`; this avoided preference-initialization trouble without altering desktop JPEXS settings.

Keep source, build tooling and `stream_enhanced/pause_menu_pages_map.gfx` together in Git. That stream folder targets Enhanced; verify asset/version compatibility separately for other game editions.

## Calling it from Lua

Lua can invoke exposed Scaleform methods ([Cfx guide](https://docs.fivem.net/docs/scripting-manual/using-scaleform/)). The pause menu also has [`BeginScaleformMovieMethodOnFrontend`](https://github.com/citizenfx/natives/blob/master/GRAPHICS/BeginScaleformMovieMethodOnFrontend.md).

An internal AS2 class method is not automatically a public frontend method. Trace the active frontend's routing into the nested component; requesting a movie handle alone does not establish that calls reach the visible pause map. This resource has no custom Lua API yet. Treat a new bridge as work requiring in-game verification. Our category and `[NEW]` tags instead travel through the existing blip-name payload.
