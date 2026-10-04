// Frames from record.mjs -> a standard MP4 (H.264) any phone plays, without ffmpeg: headless Edge encodes
// each frame with WebCodecs at its exact time (400 ms each, the last held ~3 s) and mp4-muxer (MIT, from
// jsDelivr) writes the file with its duration up front. (MediaRecorder writes fragmented MP4 with no
// total duration, which players guess differently.)
// Usage: node encode.mjs <frames-dir> <out.mp4>
import { spawn } from "node:child_process";
import { mkdtempSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const BROWSER = process.env.BROWSER_PATH || "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe";
const MUXER = "https://cdn.jsdelivr.net/npm/mp4-muxer@5/build/mp4-muxer.min.js";
const PORT = 9335;
const [dir, outFile] = process.argv.slice(2);
const files = readdirSync(dir).filter(f => f.endsWith(".jpg")).sort();
const sleep = ms => new Promise(r => setTimeout(r, ms));

const browser = spawn(BROWSER, ["--headless=new", `--remote-debugging-port=${PORT}`, "--no-first-run",
  "--user-data-dir=" + mkdtempSync(join(tmpdir(), "carmonai-encode-")), "about:blank"], { stdio: "ignore" });
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
const evaluate = async expression => {
  const result = await new Promise(r => {
    const id = ++next;
    waiting.set(id, r);
    ws.send(JSON.stringify({ id, method: "Runtime.evaluate", params: { expression, awaitPromise: true, returnByValue: true } }));
  });
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text);
  return result.result.value;
};

try {
  // WebCodecs exists only in a secure context: any localhost page will do (the browser's own /json/version).
  await new Promise(r => {
    const id = ++next;
    waiting.set(id, r);
    ws.send(JSON.stringify({ id, method: "Page.navigate", params: { url: `http://127.0.0.1:${PORT}/json/version` } }));
  });
  await sleep(1000);
  await evaluate(`new Promise((ok, no) => { const s = document.createElement("script"); s.src = ${JSON.stringify(MUXER)};
    s.onload = ok; s.onerror = () => no(new Error("mp4-muxer did not load")); document.head.append(s); })`);
  await evaluate(`window.shots = []; window.add = async src => { const img = new Image(); img.src = src; await img.decode(); shots.push(img); }`);
  for (const file of files) {
    await evaluate(`add("data:image/jpeg;base64,${readFileSync(join(dir, file)).toString("base64")}")`);
  }
  const base64 = await evaluate(`(async () => {
    const [width, height] = [shots[0].naturalWidth, shots[0].naturalHeight];
    const muxer = new Mp4Muxer.Muxer({ target: new Mp4Muxer.ArrayBufferTarget(), video: { codec: "avc", width, height }, fastStart: "in-memory" });
    let failure;
    const encoder = new VideoEncoder({ output: (chunk, meta) => muxer.addVideoChunk(chunk, meta), error: e => { failure = e; } });
    const config = { codec: "avc1.640028", width, height, bitrate: 1_000_000, framerate: 3 };
    if (!(await VideoEncoder.isConfigSupported(config)).supported) throw new Error("H.264 encoding not supported here");
    encoder.configure(config);
    const canvas = new OffscreenCanvas(width, height);
    const context = canvas.getContext("2d");
    // 400 ms per frame; the last one repeated for a 3 s hold (the muxer gives the final sample a default length).
    const sequence = shots.concat(Array(7).fill(shots[shots.length - 1]));
    const duration = 400_000;   // microseconds
    for (let i = 0; i < sequence.length; i++) {
      context.drawImage(sequence[i], 0, 0);
      const frame = new VideoFrame(canvas, { timestamp: i * duration, duration });
      encoder.encode(frame, { keyFrame: i % 10 === 0 });
      frame.close();
    }
    await encoder.flush();
    if (failure) throw failure;
    muxer.finalize();
    const bytes = new Uint8Array(muxer.target.buffer);
    let binary = "";
    for (let i = 0; i < bytes.length; i += 0x8000) binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
    return btoa(binary);
  })()`);
  writeFileSync(outFile, Buffer.from(base64, "base64"));
  console.log(`${files.length} frames -> ${outFile}`);
} finally {
  ws.close();
  browser.kill();
}
