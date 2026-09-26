param(
    [string]$JpexsJar = 'C:\Program Files (x86)\FFDec\ffdec-cli.jar'
)

$ErrorActionPreference = 'Stop'
$original = Join-Path $PSScriptRoot 'src\base\pause_menu_pages_map.gfx'
$scripts = Join-Path $PSScriptRoot 'src\scripts'
$output = Join-Path $PSScriptRoot 'stream_enhanced\pause_menu_pages_map.gfx'
$buildDirectory = Join-Path ([IO.Path]::GetTempPath()) ('aj-map-legend-' + [guid]::NewGuid())
[IO.Directory]::CreateDirectory($buildDirectory) | Out-Null
$candidate = Join-Path $buildDirectory 'pause_menu_pages_map.gfx'
$fontBase = Join-Path $buildDirectory 'map-with-figtree.gfx'
$fontFile = Join-Path $PSScriptRoot 'src\fonts\Figtree-Bold.ttf'
$sharedOriginal = Join-Path $PSScriptRoot 'src\base\pause_menu_shared_components_03.gfx'
$sharedCandidate = Join-Path $buildDirectory 'pause_menu_shared_components_03.gfx'
$sharedFontBase = Join-Path $buildDirectory 'shared-with-figtree.gfx'

& node (Join-Path $PSScriptRoot 'test-layout.cjs')
if ($LASTEXITCODE -ne 0) {
    throw 'Grouped legend layout or selection regression check failed.'
}
& node (Join-Path $PSScriptRoot 'test-hover-card.cjs')
if ($LASTEXITCODE -ne 0) { throw 'Hover-card source checks failed.' }

# Isolate JPEXS preferences so builds do not change the desktop app's settings.
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $buildDirectory
    # Java 8 includes Nashorn; the helper uses the same installed JPEXS library.
    & java "-Duser.home=$buildDirectory" '-Djava.awt.headless=true' -cp $JpexsJar jdk.nashorn.tools.Shell (Join-Path $PSScriptRoot 'src\embed-font.js') -- $original $fontBase $fontFile
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $fontBase)) {
        throw 'Font embedding failed. Use Java 8 (with Nashorn) and JPEXS 23.0.1.'
    }
    & java "-Duser.home=$buildDirectory" -jar $JpexsJar -onerror abort -importScript $fontBase $candidate $scripts
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $candidate)) {
        throw 'JPEXS did not produce the patched Scaleform.'
    }
    if ((Get-FileHash -LiteralPath $original).Hash -eq (Get-FileHash -LiteralPath $candidate).Hash) {
        throw 'The output is unchanged; the ActionScript import did not apply.'
    }

    # Check the final movie, after script compilation, for the actual local font.
    $fontXmlPath = Join-Path $buildDirectory 'font-verification.xml'
    & java "-Duser.home=$buildDirectory" -jar $JpexsJar -swf2xml $candidate $fontXmlPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect final font data.' }
    [xml]$fontXml = Get-Content -LiteralPath $fontXmlPath -Raw
    $fontTags = @($fontXml.swf.tags.item | Where-Object { $_.type -eq 'DefineCompactedFont' -and $_.fonts.item.fontName -eq 'Figtree' })
    if ($fontTags.Count -ne 1) { throw 'Final movie must contain one Figtree Bold face.' }
    foreach ($fontTag in $fontTags) {
        $fontData = $fontTag.fonts.item
        if (([int]$fontData.flags -band 3) -ne 2 -or [int]$fontData.nominalSize -ne 1024 -or @($fontData.glyphInfo.item).Count -ne 407) {
            throw 'Final Figtree style, scale, or glyph coverage is incorrect.'
        }
        $locationText = $fontXml.swf.tags.item | Where-Object { $_.type -eq 'DefineEditTextTag' -and $_.characterID -eq 139 }
        if (([int]$fontData.flags -band 2) -eq 2 -and $locationText.fontId -ne $fontTag.fontId) { throw 'Area title is not bound to embedded Bold.' }
        $glyphCodes = @($fontData.glyphInfo.item | ForEach-Object { [int]$_.glyphCode })
        foreach ($code in 33..126) {
            $glyphIndex = [Array]::IndexOf($glyphCodes, $code)
            if ($glyphIndex -lt 0 -or @($fontData.glyphs.item[$glyphIndex].contours.item).Count -eq 0) {
                throw "Missing printable ASCII outline: $code"
            }
        }
    }
    $otherText = @($fontXml.swf.tags.item | Where-Object { $_.type -eq 'DefineEditTextTag' -and $_.characterID -ne 139 })
    if (@($otherText | Where-Object { $_.fontId -notin @('130','132') }).Count -ne 0) {
        throw 'Non-title text must retain its native GTA font binding.'
    }
    Write-Output 'PASS: final movie retains Figtree Bold for headings and native GTA body-text bindings.'

    # Decompilation can hide broken accessor calls behind identical-looking AS2.
    $verification = Join-Path $buildDirectory 'verification'
    & java "-Duser.home=$buildDirectory" -jar $JpexsJar -format script:pcode -export script $verification $candidate | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'JPEXS could not inspect the compiled bytecode.'
    }
    $codeRoot = Join-Path $verification 'scripts\__Packages\com\rockstargames\gtav\pauseMenu'
    $checks = @(
        @{
            Path = 'pauseMenuItems\singleplayer\PauseMenuMapItem.pcode'
            Calls = @{ __set__data = 1; __get__data = 6; __get__uniqueID = 2; __get__columnID = 1; __get__highlighted = 2 }
        },
        @{
            Path = 'pauseComponents\PAUSE_MENU_MAP.pcode'
            Calls = @{ __set__index = 1; __get__showBlips = 1; __set__showBlips = 1 }
        },
        @{
            Path = 'pauseMenuItems\singleplayer\PauseMenuMapView.pcode'
            Calls = @{ __set__data = 1 }
        },
        @{
            Path = 'pauseMenuItems\singleplayer\PauseMenuMapModel.pcode'
            Calls = @{ __set__params = 1; __get__index = 1 }
        }
    )
    foreach ($check in $checks) {
        $code = [IO.File]::ReadAllText((Join-Path $codeRoot $check.Path))
        foreach ($accessor in $check.Calls.Keys) {
            $pattern = '"' + [regex]::Escape($accessor) + '"\r?\nCallMethod'
            if ([regex]::Matches($code, $pattern).Count -ne $check.Calls[$accessor]) {
                throw "Required compiled accessor call is missing or duplicated: $accessor in $($check.Path)"
            }
        }
        if ($code -match '"data"\r?\n(?:GetMember|Push register\d+\r?\nSetMember)') {
            throw 'Compiled code uses the empty data property instead of explicit accessor methods.'
        }
    }
    # Run the same scenarios on code recovered from the actual compiled movie.
    # JPEXS 23 can silently omit initializers in AS2 for(var ...) loops.
    $roundtrip = Join-Path $buildDirectory 'roundtrip'
    & java "-Duser.home=$buildDirectory" -jar $JpexsJar -export script $roundtrip $candidate | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'JPEXS could not decompile the candidate for behavioral checks.'
    }
    & node (Join-Path $PSScriptRoot 'test-layout.cjs') (Join-Path $roundtrip 'scripts\__Packages\com\rockstargames\gtav\pauseMenu')
    if ($LASTEXITCODE -ne 0) {
        throw 'The compiled movie failed the grouped legend behavioral checks.'
    }
    # Build the shared component as a companion to the map page. Its styling is
    # enabled only by SET_MAP_CARD_LAYOUT from that page.
    & java "-Duser.home=$buildDirectory" '-Djava.awt.headless=true' -cp $JpexsJar jdk.nashorn.tools.Shell (Join-Path $PSScriptRoot 'src\embed-font.js') -- $sharedOriginal $sharedFontBase $fontFile shared
    if ($LASTEXITCODE -ne 0) { throw 'Hover-card font embedding failed.' }
    & java "-Duser.home=$buildDirectory" -jar $JpexsJar -onerror abort -importScript $sharedFontBase $sharedCandidate (Join-Path $PSScriptRoot 'src\shared-scripts')
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $sharedCandidate)) { throw 'Hover-card compilation failed.' }
    $sharedXmlPath = Join-Path $buildDirectory 'shared-font-verification.xml'
    & java "-Duser.home=$buildDirectory" -jar $JpexsJar -swf2xml $sharedCandidate $sharedXmlPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect hover-card fonts.' }
    [xml]$sharedXml = Get-Content -LiteralPath $sharedXmlPath -Raw
    $sharedFaces = @($sharedXml.swf.tags.item | Where-Object { $_.type -eq 'DefineCompactedFont' -and $_.fonts.item.fontName -eq 'Figtree' })
    if ($sharedFaces.Count -ne 1) { throw 'Hover card is missing its local Figtree face.' }
    $sharedFont = $sharedFaces[0].fonts.item
    if (([int]$sharedFont.flags -band 3) -ne 2 -or @($sharedFont.glyphInfo.item).Count -ne 407) { throw 'Hover-card font style/coverage changed.' }
    $sharedCodes = @($sharedFont.glyphInfo.item | ForEach-Object { [int]$_.glyphCode })
    foreach ($code in 33..126) {
        $glyphIndex = [Array]::IndexOf($sharedCodes, $code)
        if ($glyphIndex -lt 0 -or @($sharedFont.glyphs.item[$glyphIndex].contours.item).Count -eq 0) { throw "Missing hover-card glyph: $code" }
    }
    $sharedPcode = Join-Path $buildDirectory 'shared-pcode'
    & java "-Duser.home=$buildDirectory" -jar $JpexsJar -format script:pcode -export script $sharedPcode $sharedCandidate | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect hover-card bytecode.' }
    $sharedCode = [IO.File]::ReadAllText((Join-Path $sharedPcode 'scripts\__Packages\com\rockstargames\gtav\pauseMenu\pauseComponents\PAUSE_MENU_FREEMODE_DETAILS.pcode'))
    if ([regex]::Matches($sharedCode, '"__set__data"\r?\nCallMethod').Count -ne 1) { throw 'Hover-card title lost its explicit accessor.' }
    # This external type is absent from the shared movie. JPEXS 23 compiles its
    # apparent cast as CallMethod, invoking the class rather than casting a clip.
    if ($sharedCode -match '"ImageLoaderMC"\r?\nCallMethod') { throw 'ImageLoaderMC cast became a class-function call; use the registered attachMovie instance directly.' }
    if ($sharedCode -match '"ImageLoaderMC"') { throw 'Hover card must not resolve or invoke the external ImageLoaderMC class.' }
    Write-Output 'PASS: hover-card bytecode uses the registered image clip without an external class call.'
    $sharedRoundtrip = Join-Path $buildDirectory 'shared-roundtrip'
    & java "-Duser.home=$buildDirectory" -jar $JpexsJar -export script $sharedRoundtrip $sharedCandidate | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Cannot decompile hover-card candidate.' }
    & node (Join-Path $PSScriptRoot 'test-hover-card.cjs') (Join-Path $sharedRoundtrip 'scripts')
    if ($LASTEXITCODE -ne 0) { throw 'Compiled hover-card checks failed.' }
    # Publish neither candidate until both have passed their checks.
    Copy-Item -LiteralPath $candidate -Destination $output -Force
    Copy-Item -LiteralPath $sharedCandidate -Destination (Join-Path $PSScriptRoot 'stream_enhanced\pause_menu_shared_components_03.gfx') -Force
    Write-Output "Built $output"
    Write-Output 'Built companion pause_menu_shared_components_03.gfx'
}
finally {
    $env:APPDATA = $previousAppData
}
