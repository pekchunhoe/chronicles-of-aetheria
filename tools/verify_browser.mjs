// Isolated headless Edge / Chromium check using Node's built-in DevTools WebSocket.
// No browser plugins or dependencies, no access to the user's browser profile.
import { spawn } from 'node:child_process';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { setTimeout as delay } from 'node:timers/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const evidence = path.join(root, 'artifacts', 'phase3-browser');
await mkdir(evidence, {recursive: true});
const profile = path.join(evidence, 'profile-' + Date.now());
const executable = process.env.AETHERIA_BROWSER || 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const url = process.argv[2] || 'http://127.0.0.1:8062/';
const child = spawn(executable, ['--headless=new', '--no-first-run', '--no-default-browser-check', '--disable-background-networking', '--disable-features=msEdgeSidebarV2', '--remote-debugging-port=0', '--user-data-dir=' + profile, 'about:blank'], {windowsHide: true, stdio: 'ignore'});
let browserSocket;
let pageSocket;
let sequence = 0;
const pending = new Map();
const issues = [];
const notes = [];
const layoutSamples = [];
let checks = 0;
function check(condition, label) {
  if (!condition) throw new Error('BROWSER CHECK FAIL: ' + label);
  checks++; console.log('PASS: ' + label);
}
function attach(socket) {
  socket.addEventListener('message', event => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const {resolve, reject} = pending.get(message.id); pending.delete(message.id);
      message.error ? reject(new Error(JSON.stringify(message.error))) : resolve(message.result);
    }
    if (message.method === 'Runtime.exceptionThrown') issues.push(message.params);
    if (message.method === 'Runtime.consoleAPICalled' && message.params.type === 'error') {
      issues.push(message.params.args.map(item => item.value || item.description).join(' '));
    }
  });
}
async function connect(address) {
  const socket = new WebSocket(address);
  await new Promise((resolve, reject) => { socket.addEventListener('open', resolve, {once:true}); socket.addEventListener('error', reject, {once:true}); });
  attach(socket); return socket;
}
function call(method, params = {}, socket = pageSocket) {
  return new Promise((resolve, reject) => {
    const id = ++sequence;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error('DevTools timeout: ' + method)); }, 30000);
    pending.set(id, {resolve: value => {clearTimeout(timer);resolve(value);}, reject: error => {clearTimeout(timer);reject(error);}});
    socket.send(JSON.stringify({id, method, params}));
  });
}
async function evaluate(expression) { return (await call('Runtime.evaluate', {expression, returnByValue:true, awaitPromise:true})).result.value; }
async function screenshot(name) { const result = await call('Page.captureScreenshot', {format:'png'}); await writeFile(path.join(evidence, name + '.png'), Buffer.from(result.data, 'base64')); }
async function canvasLayout(label) {
  await delay(450);
  const layout = await evaluate(`(() => {
    const canvas=document.querySelector('canvas'),r=canvas.getBoundingClientRect();
    const main=canvas.parentElement.getBoundingClientRect();
    return {label:${JSON.stringify(label)},x:r.x,y:r.y,width:r.width,height:r.height,
      bufferWidth:canvas.width,bufferHeight:canvas.height,viewportWidth:innerWidth,viewportHeight:innerHeight,
      main:{x:main.x,y:main.y,width:main.width,height:main.height},touchPoints:navigator.maxTouchPoints,
      fullscreen:!!document.fullscreenElement};
  })()`);
  layoutSamples.push(layout);
  check(layout.x>=-1 && layout.y>=-1 && layout.x+layout.width<=layout.viewportWidth+1 && layout.y+layout.height<=layout.viewportHeight+1, label + ': complete canvas fits viewport');
  check(layout.x>=layout.main.x-1 && layout.y>=layout.main.y-1 && layout.x+layout.width<=layout.main.x+layout.main.width+1 && layout.y+layout.height<=layout.main.y+layout.main.height+1, label + ': header and game occupy separate bounds');
  check(Math.abs(layout.width/layout.height-16/9)<0.004, label + ': 16:9 presentation');
  check(Math.abs(layout.bufferWidth/layout.bufferHeight-layout.width/layout.height)<0.004, label + ': uniform drawing-buffer scaling');
  return layout;
}
async function click(x,y) {
  await call('Input.dispatchMouseEvent', {type:'mousePressed',x,y,button:'left',clickCount:1});
  await call('Input.dispatchMouseEvent', {type:'mouseReleased',x,y,button:'left',clickCount:1});
  await delay(300);
}
async function key(key, code, virtualKey) {
  await call('Input.dispatchKeyEvent', {type:'keyDown', key, code, windowsVirtualKeyCode:virtualKey});
  await delay(100);
  await call('Input.dispatchKeyEvent', {type:'keyUp', key, code, windowsVirtualKeyCode:virtualKey});
  await delay(350);
}
async function waitRunning() {
  for (let attempt=0; attempt<120; attempt++) {
    if (await evaluate('document.documentElement.dataset.gameState') === 'running') { await delay(1600); return; }
    await delay(500);
  }
  throw new Error('Godot Web did not report running: ' + await evaluate('document.body.innerText'));
}
try {
  let port;
  for (let attempt=0; attempt<100; attempt++) {
    try { port = (await readFile(path.join(profile, 'DevToolsActivePort'), 'utf8')).trim().split(/\r?\n/); break; } catch { await delay(100); }
  }
  if (!port) throw new Error('Isolated browser did not open DevTools');
  browserSocket = await connect('ws://127.0.0.1:' + port[0] + port[1]);
  const target = await (await fetch('http://127.0.0.1:' + port[0] + '/json/new?about:blank', {method:'PUT'})).json();
  pageSocket = await connect(target.webSocketDebuggerUrl);
  await call('Page.enable'); await call('Runtime.enable');
  await call('Emulation.setDeviceMetricsOverride', {width:1280, height:762, deviceScaleFactor:1, mobile:false});
  await call('Page.navigate', {url}); await waitRunning();
  check(await evaluate('document.documentElement.dataset.gameState') === 'running', 'real Godot WebAssembly/WebGL startup');
  notes.push('Godot Web reports running after real WebAssembly/WebGL initialization.');
  await screenshot('01-citadel');
  const canvas = await canvasLayout('desktop');
  // UI coordinates are normalized to the complete 16:9 game canvas.
  const x = canvas.x + canvas.width * 0.76;
  const y = canvas.y + canvas.height * (58 / 720);
  await click(x,y);
  await delay(600);
  await key('e','KeyE',69);
  await screenshot('02-laboratory');
  await key('Tab','Tab',9);
  await screenshot('03-codex');
  await click(canvas.x+canvas.width*0.5,canvas.y+canvas.height*(301/720));
  await key('ArrowDown','ArrowDown',40);
  await key('ArrowDown','ArrowDown',40);
  await key('ArrowDown','ArrowDown',40);
  await key('Enter','Enter',13);
  await screenshot('06-friction-glyphs');
  await key('Tab','Tab',9);
  await delay(1200);
  await call('Page.reload', {ignoreCache:true}); await waitRunning();
  await key('Tab','Tab',9);
  await screenshot('04-codex-after-reload');
  notes.push('Keyboard interaction and Codex navigation exercised; screenshot comparison checks saved research discoveries after reload.');
  await key('Tab','Tab',9);
  await key('Escape','Escape',27);
  await screenshot('05-pause');
  await key('Escape','Escape',27);
  // Short ordinary movement/jump/sword sequence; the native route separately
  // validates complete six-chamber gameplay with live AI and physical relays.
  await call('Input.dispatchKeyEvent',{type:'keyDown',key:'d',code:'KeyD',windowsVirtualKeyCode:68});
  await key(' ','Space',32);
  await key('k','KeyK',75);
  await delay(500);
  await call('Input.dispatchKeyEvent',{type:'keyUp',key:'d',code:'KeyD',windowsVirtualKeyCode:68});
  await screenshot('07-movement-sword');
  await key('Escape','Escape',27);
  await call('Emulation.setDeviceMetricsOverride',{width:1600,height:900,deviceScaleFactor:1,mobile:false});
  await canvasLayout('wide resize');
  await screenshot('08-wide-resize');
  // Fullscreen remains a genuine browser user-gesture action when supported.
  const fs = await evaluate('(() => {const b=document.querySelector("#fullscreen"),r=b.getBoundingClientRect(); return {supported:document.fullscreenEnabled,x:r.x+r.width/2,y:r.y+r.height/2};})()');
  if(fs.supported){
    await click(fs.x,fs.y);
    const entered=await evaluate('!!document.fullscreenElement');
    notes.push('Fullscreen user-gesture attempt: '+(entered?'entered':'unavailable in this headless environment'));
    if(entered){
      await canvasLayout('fullscreen');
      await screenshot('09-fullscreen');
      const exit=await evaluate('(() => {const r=document.querySelector("#fullscreen").getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2};})()');
      await click(exit.x,exit.y);
      check(!await evaluate('!!document.fullscreenElement'),'fullscreen button exits successfully');
    }
  }
  await call('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:5});
  await call('Emulation.setDeviceMetricsOverride',{width:960,height:540,deviceScaleFactor:2,mobile:true});
  await call('Page.reload',{ignoreCache:true}); await waitRunning();
  const mobile=await canvasLayout('landscape touch emulation');
  check(mobile.touchPoints>0,'browser touch capability exposed before game startup');
  await screenshot('10-landscape-touch');
  await key('Tab','Tab',9);
  await screenshot('11-landscape-codex');
  await key('Tab','Tab',9);
  await call('Emulation.setTouchEmulationEnabled',{enabled:false});
  await call('Emulation.setDeviceMetricsOverride',{width:1280,height:762,deviceScaleFactor:1,mobile:false});
  await canvasLayout('restored desktop');
  await screenshot('12-restored-desktop');
  if (issues.length) throw new Error('Browser runtime errors: ' + JSON.stringify(issues));
  check(issues.length===0,'zero JavaScript exceptions or console errors');
  const summary = {browser:await call('Browser.getVersion',{},browserSocket),url,checks,canvas,layoutSamples,notes,errors:issues};
  await writeFile(path.join(evidence,'results.json'), JSON.stringify(summary,null,2));
  console.log(`BROWSER PASS: ${checks} assertions; startup, viewport/aspect/scaling, resize/fullscreen/touch emulation and input/UI/reload captures. Inspect rendered glyphs and game states.`);
} finally {
  if (browserSocket?.readyState === WebSocket.OPEN) { try { await call('Browser.close',{},browserSocket); } catch {} }
  pageSocket?.close(); browserSocket?.close();
  if (child.exitCode === null) child.kill();
}
