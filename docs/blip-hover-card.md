# Blip hover-card source map

Located by inspecting the installed Enhanced archives with CodeWalker and the extracted JPEXS source. The resource now ships a map-scoped restyle of this component; this document records the original routing and current editing points.

## Target movie

The card is the **`freemodeDetails`** symbol in **`pause_menu_shared_components_03.gfx`**:

```text
Grand Theft Auto V Enhanced/
  update/update.rpf/
    x64/data/cdimages/scaleform_frontend.rpf/
      pause_menu_shared_components_03.gfx
```

Open that GFX in JPEXS. The map movie's `ImportAssets2Tag` imports `freemodeDetails` from `PAUSE_MENU_SHARED_COMPONENTS_03.swf`. The `.swf` name in the import refers to the shared movie; the game archive contains the `.gfx` file.

`PAUSE_MENU_PAGES_MAP.setupPage()` attaches this symbol as `column2`, alongside the map legend. Its fullscreen placement is controlled in the map page's `setDisplayConfig()`.

## Classes and artwork to inspect

Under `scripts/__Packages/com/rockstargames/gtav/pauseMenu/`:

| Class | Responsibility |
| --- | --- |
| `pauseComponents/PAUSE_MENU_FREEMODE_DETAILS.as` | Card image/placeholder, title, verified badge, RP/cash/AP/CM fields, visibility, background height |
| `pauseMenuItems/singleplayer/PauseMenuFreemodeDetailsItem.as` | Detail row fonts, left/right labels, icons, checkmarks, separators and wrapping |
| `pauseMenuItems/singleplayer/PauseMenuFreemodeDetailsTitleItem.as` | Attached title row and shadow text |
| `pauseMenuItems/singleplayer/PauseMenuFreemodeDetailsModel.as` | Detail data model |
| `pauseMenuItems/singleplayer/PauseMenuFreemodeDetailsView.as` | Detail list view |

The default-package registration binds `freemodeDetails` to `PAUSE_MENU_FREEMODE_DETAILS`. Related symbols include `freemodeTitleItem`, `freemodeDetailsItem` and `verified`. Inspect the symbols as well as the AS2 when changing artwork or initial text formats.

`SET_TITLE()` handles the exact elements seen in the reference: the Rockstar verified mark, texture dictionary/name, RP value and cash value. `PauseMenuFreemodeDetailsItem` supports types 0/1 for paired text, 2 for icon/checkmark rows, 3 for player-name/crew information, 4 for separator/header rows, and 5 for wrapping description text.

## Frontend call routing

The exported frontend dispatcher is `PAUSE_MENU_SP_CONTENT`, whose class is present in `pause_menu_shared_components.gfx`:

```text
Lua: BeginScaleformMovieMethodOnFrontend(method)
  -> PAUSE_MENU_SP_CONTENT selects GET_COLUMN(first argument)
     SET_COLUMN_TITLE    -> column.SET_TITLE(remaining arguments)
     SET_DATA_SLOT       -> column.SET_DATA_SLOT(remaining arguments)
     DISPLAY_DATA_SLOT   -> column.DISPLAY_VIEW(0)
     SET_DATA_SLOT_EMPTY -> column.SET_DATA_SLOT_EMPTY(0)
```

Both shared movies and `pause_menu_sp_content.gfx` are in `scaleform_frontend.rpf`. The map page itself is in `scaleform_generic.rpf`.

There is already a local Lua implementation in `resources/[escape]/object_gizmo/client/client.lua`:

- `SetTitle()` sends the title, verified state, image and economy fields through `SET_COLUMN_TITLE`.
- `SetText()` / `SetIcon()` supply the detail rows through `SET_DATA_SLOT`.
- `UpdateDisplay()` calls `DISPLAY_DATA_SLOT`.
- The hover loop uses `GetNewSelectedMissionCreatorBlip()` and `IsHoveringOverMissionCreatorBlip()`, then fills the card from `BLIP_INFO_DATA`.
- The `blip_test_aj` command creates the existing `[CUSTOM2] [NEW] Test Blip` and supplies example card information.

That helper uses logical frontend selector `Display = 1`. Do not change it to 2 merely because the map page's member is called `column2`: frontend selectors and member names are different layers.

## Starting an edit

The current override lives in `src/shared-scripts/__Packages/com/rockstargames/gtav/pauseMenu/pauseComponents/PAUSE_MENU_FREEMODE_DETAILS.as`. The untouched template is `src/base/pause_menu_shared_components_03.gfx`; `build.ps1` compiles the companion into `stream_enhanced` together with the map page.

`PAUSE_MENU_PAGES_MAP.setDisplayConfig()` calls `SET_MAP_CARD_LAYOUT(fullscreen, safeTop, safeBottom)` on its details column. That opt-in enables the white Figtree header and dark GTA-font rows. The component centers its content on the left at 85% scale, reserving space for the area title and bottom controls; tall cards shrink further to fit. The other shared-component consumers never receive this opt-in. The original placeholder and loaded photos share a permanent 288-by-160-unit image area. Pending/missing images retain the placeholder, and switching back to a card without a photo restores it. Existing title, texture and detail-row calls remain the data source; photo capture itself is not implemented here.

For card styling, start with the shared `_03` movie and its component/row classes. For placement relative to the map or legend, inspect the map page. For content changes, use the existing Lua helper.

The shared component also contains a standalone initialization path for `mp_mission_details_card`; a shared replacement may affect other consumers. Decide whether the new style should be shared or scoped to the map before building it. Preserve the native data contract and verify the actual frontend route in-game; locating the source does not validate a modified card.

Follow the [Scaleform editing notes](scaleform-editing-notes.md), especially explicit accessors, source-and-compiled checks, fonts and frontend caching.

## Image crash investigation (2026-09-26)

The user reported a crash only when hovering a blip with an image. The client log confirmed `pause_menu_pages_char_mom_dad` loaded before the crash. CodeWalker, using Gen9 mode and the resource-entry overload of `YtdFile.Load`, confirmed `mumdadbg` exists in that Enhanced dictionary at 512x256. Loading a dictionary and identifying its texture do not prove the frontend can render it successfully.

The four current September 26 dumps in `%APPDATA%/FiveM for GTAV Enhanced/gta5enhanced/crashes` record the same access violation at `GTA5_Enhanced.exe+0x1FD45E5`, reading address `0x8` through a null `RDX`. No symbolized stack was available. An earlier note incorrectly cited `+0x482FF0` from an unrelated July dump; that evidence has been discarded. Check timestamps and the active game's crash directory before comparing dumps.

The user then tested the original Scaleform with the image and confirmed it rendered without crashing. This isolates the regression to the replacement movies rather than an inherently unusable texture or Lua call.

Concrete wrapper issues fixed in `resources/[escape]/object_gizmo/client/client.lua`:

- Convert the verified flag to an integer before `ScaleformMovieMethodAddParamInt`; the resource enables experimental OAL and must use the native's declared types.
- Pass `false`, not numeric `0`, to `ScaleformMovieMethodAddParamBool` for omitted rewards.
- End `SET_COLUMN_TITLE` / `SET_DATA_SLOT_EMPTY` calls only when beginning the method succeeded.
- Normalize nil rewards before `tostring`, which otherwise produces the visible word `nil`.
- Bound the test texture request to 10 seconds and release its request on timeout/resource stop.

### Compiled image-loader regression and 0.6.3 correction

Comparing the original and rebuilt P-code exposed a concrete difference in `SET_TITLE`: the original `ImageLoaderMC(attachMovie(...))` ends in `CastOp`, while JPEXS 23.0.1 compiled that expression as `Push "ImageLoaderMC"` followed by `CallMethod`. The class is supplied externally and is absent from this shared movie's local class definitions. The rebuilt expression invokes a class function instead of casting the attached clip. Other locally defined casts, such as `ROCKSTAR_VERIFIED`, still compiled as `CastOp`.

The override now assigns the result of `attachMovie("GenericImageLoader", ...)` directly. That symbol already has its class registration, so it needs no cast or constructor call. Image initialization, TXD reference handling, callback routing and transitions remain native. The build rejects any reintroduced reference to the unresolved external class in this component's P-code.

The source and decompiled-output harness exercise `SET_TITLE` with the supplied dictionary/texture, assert the attached instance is retained, reject calls to the external class function, check the four-part callback path and check loaded/no-image transitions. These checks establish the compilation correction; they do not emulate the native renderer. The user subsequently confirmed the corrected image hover loads successfully in-game, with a screenshot showing the photo and restored cash icon (0.6.4). Keep that successful runtime test separate from the automated checks.
