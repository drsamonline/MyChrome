# Running a free mirror

GitHub release downloads are slow or blocked on some networks. `update.txt` can name a
mirror, and the self-updater falls back to it when the GitHub download is unusable.

## Option A — Cloudflare Worker (free, no storage)

`docs/mirror-worker.js` proxies a version-and-filename path to the GitHub release. Nothing
is stored, so there is nothing to upload on a new release.

```bash
npm i -g wrangler
wrangler login
wrangler deploy docs/mirror-worker.js --name mybrowser-mirror
```

It prints a URL like `https://mybrowser-mirror.<you>.workers.dev`. Test it:

```bash
curl -I https://mybrowser-mirror.<you>.workers.dev/v3.9.38/MyBrowser_v3.9.38_x64.7z
```

Free tier: 100,000 requests per day, which is far more than this project uses.

## Option B — Cloudflare R2 or Backblaze B2 (free, with storage)

Both give 10 GB free. Upload the `.7z` and `.zip` for each release and make them public.

| Service | Free storage | Free egress |
| --- | --- | --- |
| Cloudflare R2 | 10 GB | yes |
| Backblaze B2 | 10 GB | 1 GB/day |

## Wiring it up

Add two keys to `update.txt` in a pull request:

```ini
url_mirror=https://mybrowser-mirror.<you>.workers.dev/v3.9.38/MyBrowser_v3.9.38.7z
url_x64_mirror=https://mybrowser-mirror.<you>.workers.dev/v3.9.38/MyBrowser_v3.9.38_x64.7z
```

The mirror must serve the **exact same bytes**. The download is checked against the
`sha256` / `sha256_x64` lines in the same file, and a mismatch aborts the update — so a
tampered or stale mirror cannot install anything.

CI rewrites the hash lines on every tag but leaves the URLs alone, so these keys survive
releases.

## What the launcher does

| Order | Attempt |
| --- | --- |
| 1 | the GitHub URL, through WinHTTP (TLS 1.2, your proxy setting) |
| 2 | if the body comes back empty, `InetRead` on the same URL |
| 3 | if the archive fails `7z t`, the mirror, once |
| 4 | if the mirror also fails, the error names the stage and the Win32 code |
