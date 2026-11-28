# Should MyBrowser be rewritten?

This is the decision behind roadmap items L1, L2 and L3. It is written to be argued with,
not to settle the question — the call is the maintainer's.

## What exists today

| Component | Size | Language |
| --- | --- | --- |
| `src/MyBrowser.au3` | 5,755 lines | AutoIt 3 |
| `src/include/udf.au3` | 1,565 lines | AutoIt 3 (inlined WinHTTP, GUI, date, string helpers) |
| `src/include/helpers.au3` | 492 lines | AutoIt 3 |
| `build/*.ps1` | ~1,240 lines | PowerShell |
| Docs, legal, workflows | ~2,000 lines | Markdown, YAML |

The app resolves a browser version from a vendor feed, downloads an archive, unpacks it
beside the executable, and launches it. That is the whole product. Everything else is
robustness around those four steps.

## What AutoIt costs today

| Cost | Detail |
| --- | --- |
| No ARM64 target | x64 runs under Windows emulation; a native build is impossible |
| No taskbar progress | `ITaskbarList3` needs a COM interface AutoIt cannot declare (E10) |
| Testing is end-to-end only | no unit tests; every check is a PowerShell script driving the built exe |
| Language reach | 224 strings through ini files, with no plural rules or RTL support |
| Toolchain age | AutoIt 3 is Windows-only, closed-source, and single-vendor |
| Lineage | the source derives from a GPL-3.0 project recovered from a binary, which complicates signing eligibility |

## The options

### A. Stay on AutoIt, maintenance only (L2)

| | |
| --- | --- |
| Cost | zero — it is what happens if nothing is decided |
| Buys | nothing new; bug fixes and feed updates only |
| Risks | the toolchain ages; E10 stays impossible; the test story stays end-to-end |
| Best when | the app is finished and the maintainer wants to stop building |

### B. Rewrite in Go

| | |
| --- | --- |
| Effort | an estimated 3–4 sessions for parity: feed resolvers, downloader with ranges and resume, archive extraction, atomic swap, CLI |
| Buys | one static binary per architecture (amd64 **and arm64**), real unit tests, `net/http` with TLS and proxy handled by the standard library, cross-compilation in CI for free |
| Loses | the GUI would need a toolkit (Fyne, Walk) or the app becomes CLI-first with a tray |
| Risk | archive extraction for 7z needs a pure-Go library (`github.com/bodgit/sevenzip`) or a bundled 7z binary |
| Notable | would also remove the decompiled-source lineage problem |

### C. Rewrite in Rust

| | |
| --- | --- |
| Effort | same shape as B, plus a steeper learning curve if the maintainer is not already fluent |
| Buys | the same as B, with smaller binaries and no GC |
| Loses | slower iteration; more ceremony for a GUI |
| Risk | higher — this is a tool that shells out and moves files, which is not where Rust's advantages show |

### D. .NET 8 single-file tray app

| | |
| --- | --- |
| Effort | roughly B, in C#, with WinForms or WPF |
| Buys | native Win32 access (taskbar progress, MSAA accessibility — E9 and E10 both become possible), ARM64 publishing, a first-class Windows story |
| Loses | Windows-only, as today; a ~60 MB self-contained binary unless trimmed |
| Risk | lowest of the rewrites — the platform APIs the app already needs are all first-class |

## Side by side

| | A · stay | B · Go | C · Rust | D · .NET |
| --- | --- | --- | --- | --- |
| Effort | none | 3–4 sessions | 4–6 | 3–4 |
| ARM64 | emulated | native | native | native |
| E10 taskbar | impossible | possible | possible | **native** |
| Unit tests | no | yes | yes | yes |
| GUI today | yes | rebuild | rebuild | rebuild |
| Binary size | ~1 MB | ~8 MB | ~4 MB | ~60 MB |
| Lineage issue | stays | gone | gone | gone |

## What carries over regardless

These are the expensive parts and none of them are thrown away:

| Asset | Reusable |
| --- | --- |
| Feed resolvers (9 sources) | yes — the URLs, the JSON shapes, the asset-name patterns are all documented in `docs/ARCHITECTURE.md` |
| Archive layouts | yes — every one was proven in CI and is written down |
| CI gates | yes — version, docs, smoke, attestation, manifests |
| Docs, legal, workflows | yes |
| The bug list from 3.9.29–3.9.41 | yes — each is a test case the rewrite must pass |

## A migration that does not stop shipping

| Phase | What happens |
| --- | --- |
| 1 | Keep the AutoIt build shipping; add the rewrite behind the same CLI contract (`/selftest`, `/update`, `/profile`, `/rollback`, exit codes) |
| 2 | Port the resolvers first — they are pure functions of an HTTP body, and testable without Windows |
| 3 | Port the downloader and the swap; run both binaries in CI against the same fixtures |
| 4 | Switch the release artefacts when the rewrite passes every existing smoke check |
| 5 | Freeze the AutoIt tree as `maintenance/autoit` (L2) |

## The decision, stated plainly

| If | Then |
| --- | --- |
| the app is feature-complete and you want to stop building | **A** — declare maintenance and close L1–L3 |
| you want E9, E10, ARM64 and a real test suite on Windows | **D** — .NET costs the least for what it buys here |
| you want the smallest portable binary and already know Go | **B** |
| you want to learn Rust and accept slower progress | **C** |

Not a recommendation, a reading: **D solves the two roadmap items that are otherwise
impossible** (E9, E10) and closes F4 natively. A and D are the only options that do not
throw away the GUI work already done.

## If nothing is decided

Nothing breaks. The AutoIt build keeps working, feeds keep resolving, and the maintenance
cost is the few hours a year the vendor feeds change shape. That is a legitimate answer.
