// Run the generated Nim JavaScript against a minimal browser mock.
// This catches JavaScript interop mistakes that `nim js` alone cannot detect.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const js = fs.readFileSync('dist/clock.js', 'utf8');
const callbacks = [];
const listeners = {};
const operations = [];

const ctx = {
  setTransform: (...args) => operations.push(['transform', ...args]),
  fillRect: (...args) => operations.push(['fillRect', ...args]),
  beginPath: () => operations.push(['beginPath']),
  arc: (...args) => operations.push(['arc', ...args]),
  fill: () => operations.push(['fill']),
  stroke: () => operations.push(['stroke']),
};
const canvas = { style: {}, width: 0, height: 0, getContext: () => ctx };
const digital = { textContent: '--:--' };
const date = { textContent: '' };
const elements = { 'clock-canvas': canvas, 'digital-time': digital, 'date-text': date };

const document = {
  hidden: false,
  getElementById: id => elements[id] ?? null,
  addEventListener: (name, handler) => { listeners['document:' + name] = handler; },
};
const window = {
  innerWidth: 800,
  innerHeight: 600,
  devicePixelRatio: 2,
  matchMedia: () => ({ matches: false }),
  requestAnimationFrame: cb => { callbacks.push(cb); return callbacks.length; },
  cancelAnimationFrame: () => {},
  addEventListener: (name, handler) => { listeners['window:' + name] = handler; },
};

vm.runInNewContext(js, { window, document, console, Date, Math }, {
  filename: 'dist/clock.js',
  timeout: 5000,
});

assert.equal(canvas.width, 1600, 'HiDPI backing width');
assert.equal(canvas.height, 1200, 'HiDPI backing height');
assert.equal(typeof callbacks[0], 'function', 'animation callback exists');
assert.equal(typeof listeners['window:resize'], 'function', 'resize listener exists');
assert.equal(typeof listeners['document:visibilitychange'], 'function', 'visibility listener exists');

callbacks.shift()(16);
assert.match(digital.textContent, /^\d{2}:\d{2}$/, 'current time is rendered');
assert.match(date.textContent, /^\d{4}年\d{1,2}月\d{1,2}日[日月火水木金土]曜日$/, 'Japanese date uses no weekday space');
assert.ok(operations.some(([op]) => op === 'arc'), 'Canvas arcs were drawn');
assert.ok(operations.some(([op]) => op === 'stroke'), 'Canvas rings were stroked');

console.log('Browser smoke test passed: clock canvas, labels and lifecycle.');
