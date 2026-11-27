# Support

Free software, maintained in spare time. There is no service level and no guaranteed
response.

## Before filing

| Check | Where |
| --- | --- |
| Is it a known limit? | [`README.md` → Known limits](README.md#known-limits) |
| Is it already planned? | [`ROADMAP.md`](ROADMAP.md) |
| Is it a security issue? | [`SECURITY.md`](SECURITY.md) — private report, not an issue |

## What to include

| Item | How to get it |
| --- | --- |
| Version | settings window title bar |
| Windows version | `winver` |
| Browser and channel | the two dropdowns in settings |
| The log | `MyBrowser.log`, next to the executable |
| The exact error text | copy the dialog, do not paraphrase |

## What is not supported

| Item | Why |
| --- | --- |
| The browsers themselves | report to their vendor |
| The bundled third-party binaries | see `licenses/` |
| GreenChrome / Chrome++ injection | patches the browser, off by default, unsupported on current Chrome |
| Antivirus flagging an unsigned exe | expected until signing is enabled; verify with `SHA256SUMS.txt` |

## Response

| Situation | Expectation |
| --- | --- |
| Reproducible bug | looked at, usually fixed in the next release |
| Feature request | added to `ROADMAP.md` or declined with a reason |
| Question | answered if the docs do not cover it |
