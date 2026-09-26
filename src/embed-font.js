// Run with Java 8's Nashorn and the installed JPEXS jar; see build.ps1.
// Produces a local GFx font definition, without replacing GTA's shared fonts.
var SWF = Java.type('com.jpexs.decompiler.flash.SWF');
var CompactedFont = Java.type('com.jpexs.decompiler.flash.tags.gfx.DefineCompactedFont');
var EditText = Java.type('com.jpexs.decompiler.flash.tags.DefineEditTextTag');
var FontType = Java.type('com.jpexs.decompiler.flash.types.gfx.FontType');
var FontTag = Java.type('com.jpexs.decompiler.flash.tags.base.FontTag');
var Font = Java.type('java.awt.Font');
var FontRenderContext = Java.type('java.awt.font.FontRenderContext');
var AffineTransform = Java.type('java.awt.geom.AffineTransform');
var File = Java.type('java.io.File');
var Input = Java.type('java.io.FileInputStream');
var Output = Java.type('java.io.FileOutputStream');
var Character = Java.type('java.lang.Character');

function requireCondition(condition, message) {
    if (!condition) throw new Error(message);
}

function readMovie(file) {
    var input = new Input(file);
    try { return new SWF(input, false); }
    finally { input.close(); }
}

requireCondition(arguments.length === 3 || (arguments.length === 4 && arguments[3] === 'shared'), 'Expected input.gfx output.gfx Figtree-Bold.ttf [shared]');
var bindAreaTitle = arguments.length === 3;
var movie = readMovie(arguments[0]);
var originalTagCount = movie.getTags().size();
function embedFace(file, bold) {
    var ttf = Font.createFont(Font.TRUETYPE_FONT, new File(file));
    FontTag.getInstalledFontsByName();
    FontTag.addCustomFont(ttf, new File(file));
    requireCondition(String(ttf.getFamily()) === 'Figtree', 'Unexpected font family: ' + ttf.getFamily());
    requireCondition((String(ttf.getFontName()).indexOf('Bold') !== -1) === bold, 'Unexpected Figtree weight');

    var embedded = new CompactedFont(movie);
    var data = embedded.fonts.get(0);
    data.fontName = 'Figtree';
    // Preserve the base flags used by the game's compacted fonts.
    // Set flags directly: JPEXS 23's compacted-font style setters clear other bits.
    data.flags = 0x6000 | (bold ? FontType.FF_Bold : 0);
    data.nominalSize = 1024;
    var context = new FontRenderContext(new AffineTransform(), true, true);
    var metrics = ttf.deriveFont(1024.0).getLineMetrics('Hgj', context);
    data.ascent = Math.round(metrics.getAscent());
    data.descent = Math.round(metrics.getDescent());
    data.leading = Math.round(metrics.getLeading());

    // Include every printable BMP character supplied by this static font, including
    // accented Latin characters. GFx compacted font codes are unsigned 16-bit.
    var characters = [];
    for (var code = 32; code < 0xffff; code++) {
        if (!Character.isISOControl(code) && ttf.canDisplay(code)) {
            var character = String.fromCharCode(code);
            requireCondition(embedded.addCharacter(character, ttf), 'Failed to embed U+' + code.toString(16));
            characters.push(character);
        }
    }
    requireCondition(characters.length > 200, 'Unexpectedly incomplete Figtree character coverage');

    // Insert before any text definition, and reserve this character ID before
    // creating the next weight.
    var insertAt = 0;
    while (!(movie.getTags().get(insertAt) instanceof EditText)) insertAt++;
    movie.addTag(insertAt, embedded);
    movie.updateCharacters();
    return {tag: embedded, data: data, characters: characters, bold: bold};
}
var boldFace = embedFace(arguments[2], true);
var bindings = [];
for (var index = 0; index < movie.getTags().size(); index++) {
    var tag = movie.getTags().get(index);
    if (bindAreaTitle && tag instanceof EditText && tag.characterID === 139 && tag.fontId === 130) {
        tag.fontId = boldFace.tag.fontId;
        tag.hasFont = true;
        tag.useOutlines = true;
        tag.setModified(true);
        bindings.push({id: tag.characterID, fontId: tag.fontId});
    }
}
requireCondition(!bindAreaTitle || bindings.some(function(binding) { return binding.id === 139; }), 'Base locationTF changed');
movie.updateCharacters();
var output = new Output(arguments[1]);
try { movie.saveTo(output); }
finally { output.close(); }

// Reopen the serialized bytes, then verify every code and outline survived.
var built = readMovie(arguments[1]);
requireCondition(built.getTags().size() === originalTagCount + 1, 'Unexpected tag-count change');
[boldFace].forEach(function(face) {
    var embedded = face.tag;
    var data = face.data;
    var characters = face.characters;
    var saved = built.getCharacter(embedded.fontId);
    requireCondition(saved instanceof CompactedFont, 'Embedded compacted font missing from output');
    requireCondition(String(saved.getFontNameIntag()) === 'Figtree' && saved.isBold() === face.bold && !saved.isItalic(),
        'Embedded font name/style mismatch');
    requireCondition(saved.getCharacterCount() === characters.length, 'Glyph count changed during serialization');

    characters.forEach(function(character) {
        var glyphIndex = saved.charToGlyph(character);
        requireCondition(glyphIndex >= 0, 'Missing serialized glyph: ' + character);
        var originalIndex = embedded.charToGlyph(character);
        requireCondition(saved.fonts.get(0).glyphs.get(glyphIndex).contours.length ===
            data.glyphs.get(originalIndex).contours.length, 'Glyph contours changed: ' + character);
    });
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.split('').forEach(function(character) {
        requireCondition(saved.fonts.get(0).glyphs.get(saved.charToGlyph(character)).contours.length > 0,
            'Empty outline for required character: ' + character);
    });
    print('PASS: embedded Figtree ' + (face.bold ? 'Bold' : 'Regular') + ', ' + saved.getCharacterCount() + ' glyphs; serialized outlines verified.');
});
bindings.forEach(function(binding) {
    requireCondition(built.getCharacter(binding.id).fontId === binding.fontId, 'Text lost its local font binding: ' + binding.id);
});
