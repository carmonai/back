# Demo console

A one-page tour of the whole workflow against the local stack, and the script that films it.

```bash
cd ../docker && docker compose up -d --build --wait   # the CPU stack
cd ../demo && python serve.py                          # http://localhost:3000, then "Run everything"
node record.mjs frames && python make_video.py frames workflow.webp   # the video (headless Edge, Pillow)
WIDTH=412 HEIGHT=860 SCALE=2 node record.mjs frames-phone && node encode.mjs frames-phone workflow-phone.mp4   # phone MP4
```

`encode.mjs` writes a standard MP4 (H.264, duration up front) with headless Edge's WebCodecs and
mp4-muxer (MIT, loaded from jsDelivr): no ffmpeg needed. It runs on a localhost page because WebCodecs
exists only in a secure context.

`serve.py` plays the console on `localhost:3000`, the origin the stack trusts: it serves `index.html` and
forwards `/api/*` to the gateway. Three `/dev/*` helpers stand in for what only the inside network can
do: read Mailpit, grant credit, read a balance. Demo only, never deployed.
