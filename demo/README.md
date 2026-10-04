# Demo console

A one-page tour of the whole workflow against the local stack, and the script that films it.

```bash
cd ../docker && docker compose up -d --build --wait   # the CPU stack
cd ../demo && python serve.py                          # http://localhost:3000, then "Run everything"
node record.mjs frames && python make_video.py frames workflow.webp   # the video (headless Edge, Pillow)
```

`serve.py` plays the console on `localhost:3000`, the origin the stack trusts: it serves `index.html` and
forwards `/api/*` to the gateway. Three `/dev/*` helpers stand in for what only the inside network can
do: read Mailpit, grant credit, read a balance. Demo only, never deployed.
