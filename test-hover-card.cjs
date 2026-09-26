// Executes the scoped layout on source and JPEXS-decompiled output; not a GFx renderer.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = process.argv[2] || path.join(__dirname, 'src/shared-scripts');
const source = fs.readFileSync(path.join(root, '__Packages/com/rockstargames/gtav/pauseMenu/pauseComponents/PAUSE_MENU_FREEMODE_DETAILS.as'), 'utf8').replace(/\r\n/g, '\n');
function field(text = '') {
  return {
    text, format: {}, _width: 130,
    get textWidth() { return this.text.length * (this.format.size || 18) * 0.5; },
    get textHeight() { return this.multiline ? 85 : 22; },
    getTextFormat() { return { ...this.format }; },
    setTextFormat(format) { this.format = { ...format }; this.formattedText = this.text; },
    setNewTextFormat() {}
  };
}
function clip() {
  return {
    _visible: true, rects: [],
    createEmptyMovieClip(name) { return this[name] = clip(); },
    createTextField(name) { return this[name] = field(); },
    clear() { this.rects = []; }, beginFill() {}, moveTo() {}, lineTo() {}, endFill() {}
  };
}
function row(type = 1) {
  return {
    type, _visible: true, itemTextLeft: field('Left label with some extra words'),
    itemTextRight: field('A very long detail value'), labelMC: { nameTF: field('Player name') },
    bgMC: {}, outlineMC: {}, checkMC: { _visible: true }, iconMC: { _visible: true }
  };
}
const methods = {};
for (const name of ['SET_MAP_CARD_LAYOUT', 'cardRect', 'cardText', 'fitCardText', 'applyMapCardStyle', 'SET_TITLE', 'transitionComplete']) {
  const match = source.match(new RegExp('function ' + name + '\\(([^)]*)\\)\\s*\\{([\\s\\S]*?)\\n   \\}'));
  assert.ok(match, `Missing ${name}`);
  methods[name] = vm.runInNewContext('(function(' + match[1] + '){' + match[2] + '\n})', {
    com: { rockstargames: {
      gtav: { Multiplayer: { ROCKSTAR_VERIFIED: value => value }, pauseMenu: { pauseComponents: {
        PAUSE_MENU_FREEMODE_DETAILS: { DISPLAY_TYPE_STORE: 1, DISPLAY_TYPE_MISSION: 0 }
      } } },
      ui: {
        media: { ImageLoaderMC() { throw new Error('Use the registered clip; do not invoke the external class function'); } },
        tweenStar: { TweenStarLite: { removeTweenOf() {} } },
        utils: { Colour: { Colourise() {} }, HudColour: function() {} }
      }
    } }
  });
}
function fixture(items) {
  const CONTENT = Object.assign(clip(), {
    imgMC: {}, imgPlaceholderMC: {}, descBG: {}, titleTF: {}, verifiedbgMC: {}, verifiedMC: { _visible: false }
  });
  for (const key of ['rp', 'cash', 'ap', 'cm']) {
    CONTENT[key + 'MultTF'] = {};
    CONTENT[key + 'IconMC'] = { swapDepths(depth) { this.depth = depth; } };
  }
  return Object.assign({
    CONTENT, titleFreemode: {}, scrollableContent: {}, mapCardStyled: false,
    mapCardTitle: 'Test Blip Title', mapCardImage: false, mapCardStats: [], defaultPlaceholderA: 100,
    model: { getCurrentView: () => ({ itemList: items }) }
  }, methods);
}
const untouched = fixture([row()]);
untouched.applyMapCardStyle();
assert.equal(untouched.mapCardMC, undefined, 'Other shared-component consumers remain native');
for (const top of [0, 14, 36]) {
  for (const types of [[], [1], [0, 1, 2, 3, 4, 5], Array(10).fill(5)]) {
    for (const image of [false, true]) {
      const rows = types.map(type => {
        const item = row(type);
        item.itemTextLeft.multiline = type === 5;
        return item;
      });
      const card = fixture(rows);
      card.mapCardImage = image;
      card.mapCardStats = ['1 200', '12.85M', '2x', '3x'];
      card.CONTENT.verifiedMC._visible = true;
      card.SET_MAP_CARD_LAYOUT(true, top, 720 - top);
      const scale = card.CONTENT._yscale / 100;
      assert.ok(card.CONTENT._y >= top + 68, 'Clear the area heading');
      assert.ok(card.CONTENT._y + card.mapCardHeight * scale <= 720 - top - 43, 'Clear bottom controls');
      assert.equal(card.CONTENT.imgMC._visible, image);
      assert.equal(card.CONTENT.imgPlaceholderMC._visible, true, 'Show the placeholder until a photo is ready');
      assert.equal(card.CONTENT.imgPlaceholderMC._width, 288);
      assert.equal(card.CONTENT.imgPlaceholderMC._height, 160);
      assert.equal(card.CONTENT.imgPlaceholderMC._y, card.CONTENT.imgMC._y);
      assert.ok(scale <= 0.85, 'Hover card is 15 percent smaller at its maximum size');
      const initialHeight = card.mapCardHeight;
      card.imgLdr = { isLoaded: true, _visible: true };
      card.applyMapCardStyle();
      assert.equal(card.CONTENT.imgPlaceholderMC._visible, !image);
      assert.equal(card.mapCardHeight, initialHeight, 'Loaded photos must not move the card');
      assert.equal(card.mapCardMC.titleTF.format.font, 'Figtree');
      assert.equal(card.mapCardMC.titleTF.format.bold, true);
      assert.equal(card.mapCardMC.stat0.text, 'RP  1 200');
      assert.equal(card.mapCardMC.stat1.text, '12.85M');
      assert.equal(card.CONTENT.cashIconMC._visible, true);
      assert.ok(card.CONTENT.cashIconMC.depth > 9000, 'Native cash icon is above the custom backing');
      assert.ok(card.mapCardMC.stat1._x + card.mapCardMC.stat1._width < card.CONTENT.cashIconMC._x - card.CONTENT.cashIconMC._width / 2, 'Cash amount leaves room for its icon');
      assert.ok(card.CONTENT.cashIconMC._y - card.CONTENT.cashIconMC._height / 2 >= card.CONTENT.imgMC._y);
      assert.ok(card.CONTENT.cashIconMC._y + card.CONTENT.cashIconMC._height / 2 <= card.CONTENT.imgMC._y + 160);
      assert.equal(card.mapCardMC.stat1.format.align, 'right');
      assert.ok(card.mapCardMC.stat1._y >= card.CONTENT.imgMC._y);
      assert.ok(card.mapCardMC.stat1._y + 25 <= card.CONTENT.imgMC._y + 160, 'Cash stays over the photo');
      for (const item of rows) {
        assert.equal(item.itemTextLeft.format.font, '$Font2_cond_NOT_GAMERNAME');
        assert.equal(item.iconMC._visible, true, 'Keep icon data visible');
        assert.equal(item.checkMC._visible, true, 'Keep completion state visible');
        if (item.type < 2) assert.ok(item.itemTextLeft.textWidth < item.itemTextRight._x);
      }
      card.mapCardStats = [];
      card.mapCardImage = false;
      card.CONTENT.verifiedMC._visible = false;
      card.mapCardTitle = 'A very long location title '.repeat(8);
      card.applyMapCardStyle();
      assert.equal(card.CONTENT.imgPlaceholderMC._visible, true, 'Restore the placeholder on the next card without a photo');
      assert.equal(card.CONTENT.imgMC._visible, false);
      assert.equal(card.mapCardMC.stat0._visible, false, 'Clear old rewards when the next card has none');
      assert.equal(card.CONTENT.cashIconMC._visible, false, 'Hide cash icon when the next card has no cash');
      assert.equal(card.mapCardHeight, initialHeight, 'Rewards/verified mark do not add rows below the photo');
      assert.ok(card.mapCardMC.titleTF.textWidth <= 276);
      assert.ok(card.mapCardMC.titleTF.text.endsWith('...'));
      card.SET_MAP_CARD_LAYOUT(false, top, 720 - top);
      assert.equal(card.CONTENT._y, 0);
      assert.equal(card.CONTENT._yscale, 85);
    }
  }
}
const compact = fixture([row()]);
compact.mapCardStats = ['nil', '12.85M', 'undefined'];
compact.SET_MAP_CARD_LAYOUT(true, 0, 720);
assert.equal(compact.mapCardMC.stat0._visible, false);
assert.equal(compact.mapCardMC.stat2._visible, false);
assert.equal(compact.CONTENT._yscale, 85);
assert.ok(Math.abs(compact.CONTENT._y + compact.mapCardHeight * 0.85 / 2 - 360) <= 0.5);
// Exercise the previously untested native image request path with the exact
// frontend payload. Runtime texture rendering must still be checked in GTA.
const imageCard = fixture([row()]);
imageCard.gfxName = 'PAUSE_MENU_SP_CONTENT';
imageCard.depth = 4;
imageCard.menuBlackAlphaColor = { r: 0, g: 0, b: 0, a: 80 };
imageCard.titleFreemode = { highlightTitle() {}, __set__data(data) { this.titleData = data; } };
Object.defineProperty(imageCard.titleFreemode, 'data', { set(data) { this.__set__data(data); } });
imageCard.CONTENT.verifiedMC.SET_VERIFIED = function(value) { this.verifiedState = value; };
const requests = [];
const imageLoader = {
  toString() { return '_level0.frontend.pageMC.column2.myMC.imgMC.imgLdr'; },
  init(gfx, dict, texture, width, height, x, y) {
    this.textureDict = dict; this.textureFilename = texture;
    assert.equal(gfx, 'PAUSE_MENU_SP_CONTENT');
    assert.deepEqual([width, height, x, y], [288, 160, 0, 0]);
  },
  addTxdRef(route, callback, scope) { requests.push({ route, scope, kind: 'add' }); },
  requestTxdRef(route, same, callback, scope) { requests.push({ route, scope, kind: 'request', same }); },
  removeTxdRef() { this.isLoaded = false; }
};
imageCard.CONTENT.imgMC.attachMovie = () => imageLoader;
imageCard.CONTENT.imgMC.getNextHighestDepth = () => 1;
imageCard.SET_MAP_CARD_LAYOUT(true, 14, 706);
imageCard.SET_TITLE('', 'Photo title', 1, 'pause_menu_pages_char_mom_dad', 'mumdadbg', 0, 0, false, '12.85M');
assert.equal(requests.length, 1);
assert.equal(imageCard.imgLdr, imageLoader, 'Keep the instance created by attachMovie');
assert.equal(requests[0].kind, 'add');
assert.equal(requests[0].route, 'column2.myMC.imgMC.imgLdr');
assert.equal(requests[0].scope, imageCard);
assert.equal(imageLoader.textureDict, 'pause_menu_pages_char_mom_dad');
assert.equal(imageLoader.textureFilename, 'mumdadbg');
assert.equal(imageCard.mapCardMC.stat0._visible, false);
assert.equal(imageCard.mapCardMC.stat1.text, '12.85M');
assert.equal(imageCard.CONTENT.imgPlaceholderMC._visible, true);
imageLoader.isLoaded = true;
imageLoader._visible = true;
imageCard.transitionComplete();
assert.equal(imageCard.CONTENT.imgPlaceholderMC._visible, false);
imageCard.SET_TITLE('', 'Without photo', 0, '', '', 0, 0, false, false);
assert.equal(imageCard.CONTENT.imgMC._visible, false);
assert.equal(imageCard.CONTENT.imgPlaceholderMC._visible, true);
assert.equal(imageCard.mapCardMC.stat1._visible, false);
console.log('PASS: hover-card scope, text, optional media/rewards, empty/tall cards, safe-zone centering and normal-page reset.');
