// Cloudflare Worker: a free mirror for MyBrowser release downloads.
//
// Why: GitHub release downloads are slow or blocked on some networks. A Worker adds no
// storage - it proxies to the release it is asked for - and the free tier is 100,000
// requests a day.
//
// Deploy:
//   1. npm i -g wrangler
//   2. wrangler login
//   3. wrangler deploy docs/mirror-worker.js --name mybrowser-mirror
//   4. note the URL it prints, e.g. https://mybrowser-mirror.<you>.workers.dev
//
// Usage:
//   https://mybrowser-mirror.<you>.workers.dev/v3.9.38/MyBrowser_v3.9.38_x64.7z
//   -> https://github.com/drsamonline/MyChrome/releases/download/v3.9.38/MyBrowser_v3.9.38_x64.7z
//
// Then put those URLs in update.txt as url_mirror= and url_x64_mirror=.
// The launcher checks the SHA256 from the same file, so a tampered mirror is refused.

const REPO = 'drsamonline/MyChrome';

// Only these names are proxied. Anything else is a 404, so the Worker cannot be used as
// an open proxy.
const ALLOWED = /^\/v(\d+\.\d+\.\d+)\/(MyBrowser_v\d+\.\d+\.\d+(_x64)?(_source)?\.(7z|zip)|SHA256SUMS\.txt)$/;

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const match = url.pathname.match(ALLOWED);

    if (!match) {
      return new Response('Not found\n', { status: 404 });
    }

    const version = match[1];
    const name = match[2];
    const target = `https://github.com/${REPO}/releases/download/v${version}/${name}`;

    const upstream = await fetch(target, {
      method: request.method === 'HEAD' ? 'HEAD' : 'GET',
      headers: { 'User-Agent': 'MyBrowser-mirror' },
      redirect: 'follow',
    });

    if (!upstream.ok) {
      return new Response(`Upstream returned ${upstream.status}\n`, { status: 502 });
    }

    // Stream it through: the archives are a few megabytes and Cloudflare handles the range
    // requests the segmented downloader sends.
    const headers = new Headers();
    for (const h of ['content-type', 'content-length', 'accept-ranges', 'content-range', 'etag']) {
      const v = upstream.headers.get(h);
      if (v) headers.set(h, v);
    }
    headers.set('cache-control', 'public, max-age=3600');
    headers.set('x-mirror', 'mybrowser-worker');

    return new Response(upstream.body, { status: upstream.status, headers });
  },
};
