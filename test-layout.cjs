// Exercises the AS2 view's algorithms in JavaScript; this does not render GFx.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const sourceRoot = process.argv[2] || path.join(__dirname, 'src/scripts/__Packages/com/rockstargames/gtav/pauseMenu');
const viewSource = fs.readFileSync(path.join(sourceRoot, 'pauseMenuItems/singleplayer/PauseMenuMapView.as'), 'utf8').replace(/\r\n/g, '\n');
const rowSource = fs.readFileSync(path.join(sourceRoot, 'pauseMenuItems/singleplayer/PauseMenuMapItem.as'), 'utf8').replace(/\r\n/g, '\n');

function clip() {
  return {
    _visible: true,
    createEmptyMovieClip(name) { return this[name] = clip(); },
    createTextField(name) {
      return this[name] = {
        text: '',
        setNewTextFormat(format) { this.defaultFormat = format; },
        setTextFormat(format) { this.format = format; this.formattedText = this.text; }
      };
    },
    attachMovie(linkage, name) {
      const item = Object.assign(clip(), {
        initStoreMethod(fn, scope) { this.store = fn.bind(scope); },
        __set__data(data) {
          this.raw = data;
          this.index = data[0];
          this.uniqueID = data[2];
          this.selectedValue = data[4];
        }
      });
      // JPEXS pretty-prints explicit accessor calls as properties on export.
      // build.ps1 separately checks that the bytecode still uses CallMethod.
      Object.defineProperty(item, 'data', { set(data) { this.__set__data(data); } });
      return this[name] = item;
    },
    clear() {}, beginFill() {}, moveTo() {}, lineTo() {}, endFill() {}, removeMovieClip() {}
  };
}
class BaseView {
  constructor() {
    this.dataList = []; this.itemList = []; this._index = 0; this.topEdge = 0;
    this.viewContainer = clip();
  }
  addItem(index, data) { this.dataList[index] = data; }
}
const javascript = viewSource
  .replace(/^class .* extends .*\n/, 'class GroupedView extends BaseView\n')
  .replace(/^   var \w+;\r?\n/gm, '')
  .replace(/^   var (\w+) =/gm, '   $1 =')
  .replace(/function PauseMenuMapView\(/, 'constructor(')
  .replace(/\bfunction (\w+)\(/g, '$1(');
const GroupedView = vm.runInNewContext(javascript + '\nGroupedView', {
  BaseView, TextFormat: function(font, size, color) { this.font = font; this.size = size; this.color = color; }
});
function record(index, name, sprite = 'radar_test') {
  return [index, 0, 10000 + index, 0, 0, 1, name, 80, 180, 210, sprite, 3, true, false];
}
const labels = ['Barber', 'Garbage Depot', 'Garages: Sandy Docks Depot', 'Police Department',
  'City Services', 'Gold Panning', 'Bank', 'Crafting Bench', 'Fantastic Plaza',
  'Unclassified Location', 'Los Santos Customs: Los Santos Customs - Vinewood', 'Air Shop',
  'Prison', 'Foundry Shop', 'Diving Area', 'Clothing Store', 'Downtown Cab'];
const view = new GroupedView();
const originals = [];
for (let index = 0; index < 70; index++) {
  const data = record(index, labels[index % labels.length] + ' ' + index);
  originals.push(data);
  view.addItem(index, data);
}
view.addItem(70, record(70, '<C>PrivateUsername</C>', 'radar_centre'));
view.addItem(71, record(71, 'Waypoint', 'radar_waypoint'));
view.displayView();
assert.equal(view.order.length, 72);
assert.equal(view.order[0].nativeIndex, 70, 'Player comes first regardless of native slot');
assert.equal(view.order[1].nativeIndex, 71, 'Waypoint follows player');
assert.equal(new Set(view.order.map(entry => entry.nativeIndex)).size, 72);
assert.ok(view.order.every((entry, i) => !i || view.order[i - 1].group <= entry.group));
assert.equal(view.categoryFor(record(0, 'Garages: Sandy Docks Depot')), 3);
assert.equal(view.categoryFor(record(0, 'Garbage Depot')), 2);
assert.equal(view.categoryFor(record(0, ': Prison')), 1);
assert.equal(view.categoryFor(record(0, 'Mystery blip')), 7);
for (let i = 0; i < originals.length; i++) {
  assert.equal(view.dataList[i], originals[i], 'Native array must not be reordered');
}

function checkSelection(nativeIndex) {
  const selected = view.itemList.filter(item => item._visible && item._highlighted);
  assert.equal(selected.length, 1);
  assert.equal(selected[0].index, nativeIndex);
  assert.equal(selected[0].uniqueID, 10000 + nativeIndex);
  assert.equal(view._index, nativeIndex);
  assert.equal(view.itemList[view.highlightedItem], selected[0]);
  const rectangles = [];
  for (const item of view.itemList.filter(item => item._visible)) {
    rectangles.push([item._y, item._y + 32]);
    assert.equal(item.raw, view.dataList[item.index]);
  }
  for (const heading of view.headings.filter(heading => heading._visible)) {
    rectangles.push([heading._y, heading._y + 24]);
    assert.equal(heading.titleTF.formattedText, heading.titleTF.text, 'Apply formatting after assigning each heading');
    assert.equal(heading.titleTF.format.font, 'Figtree');
    assert.equal(heading.titleTF.format.bold, true);
    assert.equal(heading.titleTF.format.color, 15725555);
  }
  assert.equal(view.panelMC.positionTF, undefined, 'No position count should be created');
  assert.equal(view.panelMC.emptyTF._visible, false);
  assert.equal(view.panelMC.titleTF.format.font, 'Figtree');
  assert.equal(view.panelMC.titleTF.format.bold, true);
  rectangles.sort((a, b) => a[0] - b[0]);
  assert.ok(rectangles.every(([start, end], i) => start >= 34 && end <= 570 &&
    (!i || rectangles[i - 1][1] <= start)), 'Rows and headers must fit without overlapping');
}
view.jumpTo(70);
checkSelection(70);
for (let position = 1; position <= view.order.length; position++) {
  view.moveSelection(1);
  checkSelection(view.order[position % view.order.length].nativeIndex);
}
view.moveSelection(-1);
checkSelection(view.order[view.order.length - 1].nativeIndex);
for (let nativeIndex = 0; nativeIndex < 72; nativeIndex++) {
  view.jumpTo(nativeIndex);
  checkSelection(nativeIndex);
}
const selectedItem = view.itemList[view.highlightedItem];
selectedItem.store(selectedItem.index, 4, 2);
view.renderSelection(view._index);
assert.equal(view.dataList[71][4], 2, 'Grouped cycling must persist against native slot');
assert.equal(view.itemList[view.highlightedItem].selectedValue, 2);
view.addItem(71, record(71, 'Hospital', 'radar_hospital'));
view.renderSelection(71);
checkSelection(71);
assert.equal(view.order[view.positions[71]].group, 1, 'Updated slot must be recategorized');

const labelBody = rowSource.match(/function displayLabel\(\)\s*\{([\s\S]*?)\n   \}\n   function updateDisplay/)[1];
const displayLabel = new Function(labelBody);
function labelFixture(iconID, label) {
  return { iconID, storeScope: view, __get__data: () => [label], get data() { return [label]; } };
}
assert.equal(displayLabel.call(labelFixture('radar_centre', '<C>PrivateUsername</C>')), 'You');
assert.equal(displayLabel.call(labelFixture('radar_test', 'Garages: Sandy Docks Depot')), 'Sandy Docks Depot');
const tags = [
  ['[VEHICLES] Hayes Depot', 'VEHICLES', 'Hayes Depot'],
  ['Garages: [VEHICLES] Hayes Depot', 'VEHICLES', 'Hayes Depot'],
  ['Stores: [FOOD] Burger Shot', 'FOOD', 'Burger Shot'],
  [' \t[ vehicles ]  Hayes Depot  ', 'VEHICLES', 'Hayes Depot'],
  ['<C>[MEDICAL] Pillbox</C>', 'MEDICAL', 'Pillbox'],
  ['[SHOPS & SERVICES] Bank', 'SHOPS & SERVICES', 'Bank']
];
for (const [raw, category, label] of tags) {
  assert.equal(view.parseLabel(raw).category, category);
  assert.equal(view.parseLabel(raw).label, label);
  assert.equal(displayLabel.call(labelFixture('radar_test', raw)), label);
}
for (const raw of ['[] Depot', '[  ] Depot', '[VEHICLES Depot', '[VEHICLES]', 'Depot [VIP]', '[[BROKEN] Depot']) {
  assert.equal(view.parseLabel(raw).category, undefined);
  assert.equal(view.parseLabel(raw).label, raw, 'Malformed tags must not delete the name');
}
for (const [raw, category, label] of [
  ['[CUSTOM2] [NEW] Test Blip', 'CUSTOM2', 'Test Blip'],
  ['[NEW] [CUSTOM2] Test Blip', 'CUSTOM2', 'Test Blip'],
  ['Garages: [CUSTOM2] [new] Test Blip', 'CUSTOM2', 'Test Blip'],
  ['<C>[CUSTOM2] Test [NEW] Blip</C>', 'CUSTOM2', 'Test Blip'],
  ['[CUSTOM2] Test Blip [NEW]', 'CUSTOM2', 'Test Blip'],
  ['[NEW] [NEW] Bank', undefined, 'Bank'],
  ['[CUSTOM2][NEW]Test Blip', 'CUSTOM2', 'Test Blip']
]) {
  const parsed = view.parseLabel(raw);
  assert.equal(parsed.category, category);
  assert.equal(parsed.label, label);
  assert.equal(parsed.isNew, true);
  assert.equal(displayLabel.call(labelFixture('radar_test', raw)), label);
}
for (const raw of ['[NEW]', '[NEW] [new]', 'New Store', '[NEWISH] Test Blip', 'Test [NEW']) {
  assert.equal(view.parseLabel(raw).isNew, false, 'Only complete tags on nonempty names set the badge');
}
assert.equal(view.parseLabel('[CUSTOM2] [PUBLIC] Test Blip').label, '[PUBLIC] Test Blip');
const taggedView = new GroupedView();
taggedView.addItem(0, record(0, '[CUSTOM2] Zeta'));
taggedView.addItem(1, record(1, '[CUSTOM2] [NEW] Alpha'));
taggedView.addItem(2, record(2, '[NEW] Bank'));
taggedView.displayView();
assert.equal(taggedView.order[taggedView.positions[2]].category, 'SHOPS & SERVICES');
assert.ok(taggedView.positions[1] < taggedView.positions[0], 'NEW does not affect alphabetical sorting');
assert.equal(taggedView.dataList[1][6], '[CUSTOM2] [NEW] Alpha', 'NEW parsing preserves native slot data');
assert.ok(!taggedView.groupNames.includes('NEW'), 'NEW is a reserved badge, not a category');
view.addItem(72, record(72, '[VEHICLES] Hayes Depot'));
view.addItem(73, record(73, '[MEDICAL] Hospital'));
view.addItem(74, record(74, '[medical] Clinic'));
view.addItem(75, record(75, '[FOOD] Burger Shot'));
view.renderSelection(72);
checkSelection(72);
assert.equal(view.order[view.positions[72]].group, 3, 'Known tags merge with fallback groups');
assert.equal(view.order[view.positions[73]].category, 'MEDICAL', 'Explicit tags override keyword matching');
assert.equal(view.order[view.positions[73]].group, view.order[view.positions[74]].group);
assert.equal(view.dataList[72][6], '[VEHICLES] Hayes Depot', 'Do not alter the native name');
assert.equal(view.groupNames.filter(name => name === 'MEDICAL').length, 1);
assert.ok(view.positions[75] < view.positions[74], 'Custom categories sort alphabetically');
assert.ok(view.positions[74] < view.positions[73], 'Names sort without the category tag');
view.addItem(73, record(73, '[FOOD] Hospital Cafe'));
view.renderSelection(73);
checkSelection(73);
assert.equal(view.order[view.positions[73]].category, 'FOOD', 'Rename moves a live slot into its new category');
view.addItem(74, record(74, 'Clinic'));
view.renderSelection(74);
assert.ok(!view.groupNames.includes('MEDICAL'), 'Unused dynamic category is removed on rebuild');
view.destroy();
assert.equal(view.dataList.length, 0);
view.displayView();
assert.equal(view.panelMC.emptyTF.text, 'No locations');
assert.equal(view.panelMC.emptyTF._visible, true);
assert.equal(view.panelMC.positionTF, undefined);
assert.ok(view.itemList.every(item => !item._visible));
view.addItem(0, record(0, 'Only Location'));
view.renderSelection(0);
view.moveSelection(1);
checkSelection(0);
const expandedView = new GroupedView();
for (let index = 0; index < 20; index++) {
  expandedView.addItem(index, record(index, '[JOBS] Location ' + String(index).padStart(2, '0')));
}
expandedView.displayView();
const expandedRows = expandedView.itemList.filter(item => item._visible);
assert.equal(expandedRows.length, 16, 'Reclaimed footer fits 16 rows plus their category heading');
assert.equal(expandedRows[15]._y + 32, 570, 'Last row fills the former footer space');
expandedView.jumpTo(19);
assert.equal(expandedView.itemList[expandedView.highlightedItem].index, 19);
assert.equal(expandedView.panelMC.positionTF, undefined);
// Exercise title/distance callbacks and safe-zone changes from both source and
// the decompiled movie. These are separate from the grouped list's layout.
const componentSource = fs.readFileSync(path.join(sourceRoot, 'pauseComponents/PAUSE_MENU_MAP.as'), 'utf8').replace(/\r\n/g, '\n');
const pageSource = fs.readFileSync(path.join(sourceRoot, '../pauseMenuPages/PAUSE_MENU_PAGES_MAP.as'), 'utf8').replace(/\r\n/g, '\n');
function method(source, name) {
  const match = source.match(new RegExp('function ' + name + '\\(([^)]*)\\)\\s*\\{([\\s\\S]*?)\\n   \\}'));
  assert.ok(match, 'Missing method: ' + name);
  return vm.runInNewContext('(function(' + match[1] + '){' + match[2] + '\n})', {
    TextFormat: function(font, size, color) { this.font = font; this.size = size; this.color = color; },
    com: { rockstargames: {
      gtav: { pauseMenu: { pauseComponents: { PAUSE_MENU_MAP: value => value } } },
      ui: { utils: { Colour: { Colourise() {} } } }
    } }
  });
}
const titleClip = clip();
titleClip.createTextField('locationTF');
const mapComponent = {
  location: { _x: 0, _y: -30, bgMC: { _visible: true }, labelMC: titleClip },
  zoom: { _visible: true }, updateScroll() {}
};
const setTitle = method(componentSource, 'SET_TITLE');
const setDescription = method(componentSource, 'SET_DESCRIPTION');
for (const label of ['Alta', 'Redwood Lights Track', '', undefined, 'Pillbox Hill']) {
  mapComponent.zoom._visible = true;
  setTitle.call(mapComponent, label);
  assert.equal(mapComponent.zoom._visible, false, 'Area updates must never restore the distance scale');
  assert.equal(mapComponent.location.bgMC._visible, false);
  assert.equal(mapComponent.location._y, 0, 'Remove the old bottom-relative title offset');
  assert.equal(mapComponent.location._visible, Boolean(label));
  if (label) {
    assert.equal(titleClip.locationTF.text, label.toUpperCase());
    assert.equal(titleClip.locationTF.formattedText, label.toUpperCase());
    assert.equal(titleClip.locationTF.format.font, 'Figtree');
    assert.equal(titleClip.locationTF.format.bold, true, 'Match the embedded bold face');
    assert.equal(titleClip.locationTF.format.italic, false, 'Do not request an unloaded italic face');
    assert.equal(titleClip.locationTF.format.size, 32);
    assert.equal(titleClip.locationTF.format.color, 0xffffff);
    assert.equal(titleClip.weightTF, undefined, 'Real bold font needs no duplicate weight layer');
  }
  mapComponent.zoom._visible = true;
  setDescription.call(mapComponent, '0', '5639ft');
  assert.equal(mapComponent.zoom._visible, false, 'Distance updates must stay hidden');
}
setTitle.call(mapComponent, '');
assert.equal(mapComponent.location._visible, false, 'Empty area hides the title');
// Approximate measured widths to exercise fitting and hit regions independently
// of GFx. The final movie's actual font data is checked separately by the build.
function measuredText() {
  return {
    text: '', format: {},
    getTextFormat() { return {}; },
    setNewTextFormat(format) { this.defaultFormat = { ...format }; },
    setTextFormat(format) { this.format = { ...format }; },
    get textWidth() { return this.text.length * this.format.size * 0.6; },
    get _width() { return this.textWidth + 4; }
  };
}
const updateRow = method(rowSource, 'updateDisplay');
const clickRow = method(rowSource, 'mPress');
for (const count of [1, 39, 1000]) {
  const rowData = ['A very long location name with extra details', 80, 180, 210, undefined];
  const row = Object.assign(clip(), {
    __get__data: () => rowData, get data() { return rowData; },
    __get__highlighted: () => true, highlighted: true,
    displayLabel: () => rowData[0], _showBlips: true,
    bgMC: {}, bMC: {}, labelMC: {}, newIconMC: {}, iconMC: clip(),
    itemTextLeft: measuredText(), valueTF: measuredText(), lMC: {}, rMC: {},
    valuesLength: count, selectedValue: count - 1,
    stepVal(direction) { this.lastStep = direction; }
  });
  row.valueIndicatorMC = { get _width() { return row.rMC._x + 8; } };
  updateRow.call(row);
  assert.equal(row.itemTextLeft.format.font, '$Font2_cond_NOT_GAMERNAME');
  assert.equal(row.itemTextLeft.format.bold, false);
  assert.ok(row.itemTextLeft.format.size <= 18 && row.itemTextLeft.format.size >= 16);
  assert.equal(row.itemTextLeft.embedFonts, true);
  assert.ok(row.itemTextLeft.text.endsWith('...'), 'Long labels must still fit');
  if (count > 1) {
    assert.equal(row.valueTF.format.font, '$Font2_cond_NOT_GAMERNAME');
    assert.equal(row.valueTF.format.bold, false);
    assert.equal(row.valueTF.embedFonts, true);
    assert.ok(row.itemTextLeft.textWidth <= row.valueIndicatorMC._x - 10);
    const counterLeft = row.labelMC._x + row.valueIndicatorMC._x;
    row._xmouse = counterLeft + row.lMC._x;
    clickRow.call(row);
    assert.equal(row.lastStep, -1, 'Left arrow hit region follows the resized counter');
    row._xmouse = counterLeft + row.rMC._x;
    clickRow.call(row);
    assert.equal(row.lastStep, 1, 'Right arrow hit region follows the resized counter');
  } else {
    assert.ok(row.itemTextLeft.textWidth <= 240);
  }
  row.storeScope = view;
  row.displayLabel = () => displayLabel.call(row);
  rowData[0] = '[CUSTOM2] [NEW] A very long location name with extra details';
  for (const highlighted of [false, true]) {
    row._highlighted = highlighted;
    updateRow.call(row);
    assert.equal(row.newBadgeMC._visible, true);
    assert.equal(row.newBadgeMC.badgeTF.formattedText, 'NEW');
    assert.equal(row.newBadgeMC.badgeTF.format.font, '$Font2_cond_NOT_GAMERNAME');
    assert.ok(row.labelMC._x + row.itemTextLeft.textWidth <= row.newBadgeMC._x - 6);
    assert.ok(row.newBadgeMC._x + 30 <= (count > 1 ? row.labelMC._x + row.valueIndicatorMC._x - 6 : 288));
    assert.ok(!row.itemTextLeft.text.includes('['), 'Metadata is not visible in row labels');
  }
  row._showBlips = false;
  updateRow.call(row);
  assert.equal(row.newBadgeMC._x, 258, 'Hidden cycling controls release their space');
  rowData[0] = '[CUSTOM2] Test Blip';
  updateRow.call(row);
  assert.equal(row.newBadgeMC._visible, false, 'Reused rows must clear the previous badge');
  assert.equal(row.itemTextLeft.text, 'Test Blip');
  rowData[0] = '[CUSTOM2] [new] Test Blip';
  updateRow.call(row);
  assert.equal(row.newBadgeMC._visible, true, 'Renaming a live slot restores the badge');
}
function column() {
  const viewContainer = {};
  return { details: {}, model: { getCurrentView: () => ({ viewContainer }) }, scrollBase: {}, updateScroll() {} };
}
const page = { column0: column(), column1: column(), column2: {}, inFullscreenMode: true, dx: 0, dy: 430 };
const setDisplayConfig = method(pageSource, 'setDisplayConfig');
for (const [width, height, top, left] of [[1920, 1080, 0.02, 0.02], [3440, 1440, 0.05, 0.05], [1280, 720, 0, 0]]) {
  setDisplayConfig.call(page, width, height, top, 1 - top, left, 1 - left, true);
  for (const mapColumn of [page.column0, page.column1]) {
    assert.equal(mapColumn.details._x, Math.round(left * 1280));
    assert.equal(mapColumn.details._y, Math.round(top * 720), 'Area title follows the top safe margin');
    assert.equal(mapColumn.model.getCurrentView().viewContainer._x, Math.round((1 - left) * 1280));
    assert.equal(mapColumn.model.getCurrentView().viewContainer._y, Math.round(top * 720));
  }
}
page.inFullscreenMode = false;
setDisplayConfig.call(page, 1920, 1080, 0.02, 0.98, 0.02, 0.98, true);
assert.equal(page.column1.details._y, page.dy, 'Preserve the normal page layout when leaving fullscreen');
assert.equal(page.column1.model.getCurrentView().viewContainer._x, 868);
console.log('PASS: grouping, native IDs, navigation, layout, cycling, You, dynamic tags, heading formatting, live area title, hidden distance scale, safe-zone placement.');
