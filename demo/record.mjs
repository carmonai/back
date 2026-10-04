// Records the demo without extra tools: headless Edge (or Chrome) over the DevTools protocol opens the demo
// console, shows the design for a few seconds, runs every step, and saves a frame every 400 ms to the
// directory given as the first argument. make_video.py turns the frames into an animated WebP.
// Run with serve.py up: node record.mjs <frames-dir>
// Phone-sized: WIDTH=412 HEIGHT=860 SCALE=2 node record.mjs <frames-dir>   (CSS pixels; frames are SCALE times larger)
import { spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const BROWSER = process.env.BROWSER_PATH || "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe";
const PORT = 9333;
const [WIDTH, HEIGHT, SCALE] = [process.env.WIDTH || 1280, process.env.HEIGHT || 800, process.env.SCALE || 1].map(Number);
const out = process.argv[2];
mkdirSync(out, { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));

const browser = spawn(BROWSER, ["--headless=new", `--remote-debugging-port=${PORT}`, "--no-first-run",
  "--user-data-dir=" + mkdtempSync(join(tmpdir(), "carmonai-demo-")), "about:blank"], { stdio: "ignore" });
let page;
for (let i = 0; i < 100 && !page; i++) {
  try { page = (await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json()).find(t => t.type === "page"); } catch {}
  if (!page) await sleep(200);
}
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(r => { ws.onopen = r; });
let next = 0;
const waiting = new Map();
ws.onmessage = e => {
  const m = JSON.parse(e.data);
  if (waiting.has(m.id)) { waiting.get(m.id)(m.result); waiting.delete(m.id); }
};
const send = (method, params = {}) => new Promise(r => { const id = ++next; waiting.set(id, r); ws.send(JSON.stringify({ id, method, params })); });
const run = expression => send("Runtime.evaluate", { expression, awaitPromise: false });

let frame = 0;
const shoot = async (count = 1) => {
  for (let i = 0; i < count; i++) {
    const { data } = await send("Page.captureScreenshot", { format: "jpeg", quality: 72 });
    writeFileSync(join(out, String(frame++).padStart(4, "0") + ".jpg"), Buffer.from(data, "base64"));
    await sleep(400);
  }
};

await send("Emulation.setDeviceMetricsOverride", { width: WIDTH, height: HEIGHT, deviceScaleFactor: SCALE, mobile: WIDTH < 640 });
await send("Page.navigate", { url: "http://localhost:3000/" });
await sleep(1500);

// The design first: the diagram and its four rules, with the narration bar saying what to look at.
const intro = [
  "<b>How it's built</b> — one Java service per job, each with its own Postgres schema; only the gateway is public.",
  "<b>The gateway</b> decides who you are (JWT or API key) and sets the identity headers the services trust.",
  "<b>Chat never touches a database</b>: Valkey and in-memory counters admit it, the engine streams it, money follows from usage.",
  "<b>Privacy by design</b>: logs and usage keep ids and counts, never prompts, answers, emails or keys. Now, the workflow ↓",
];
await run(`window.scrollTo(0, document.querySelector("h2").offsetTop - 90)`);   // the design section
for (const line of intro) {
  await run(`document.getElementById("say").innerHTML = ${JSON.stringify(line)}`);
  await shoot(9);
}
await run("runAll()");
for (;;) {
  await shoot();
  const { result } = await send("Runtime.evaluate", { expression: "window.done === true", returnByValue: true });
  if (result.value) break;
}
await shoot(8);
ws.close();
browser.kill();
console.log(`${frame} frames in ${out}`);
