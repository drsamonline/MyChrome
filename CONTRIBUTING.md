# Contributing

The project is small and the rules are short. The important one: **nothing ships that the
gates have not passed.**

## Build

```powershell
./build/build.ps1          # downloads the AutoIt SDK on first run, compiles both binaries
```

Output lands in `dist/`: `MyBrowser.exe` (x64), `MyBrowser_x86.exe`, `.7z` and `.zip` for
each, and `SHA256SUMS.txt`.

## Run the gates before you push

```powershell
./build/check-docs.ps1     # version, roadmap counts, changelog, links, release log
./build/smoke.ps1          # every source, both binaries, first run, proxy faults
./build/smoke.ps1 -Deep    # also downloads and unpacks the real browser packages (~1.5 GB)
```

CI runs exactly these. `-Deep` runs on the primary runner only; the second runner keeps
the fast set.

## Changing the version

The version lives in four places and the build refuses to compile if they disagree:

| File | What to change |
| --- | --- |
| `src/MyBrowser.au3` | `Global Const $APPVERSION = "x.y.z"` |
| `resources/en-US.ini` | `Version=` under `[Lang]` |
| `resources/zh-TW.ini` | `Version=` under `[Lang]` (UTF-16, keep the BOM) |
| `update.txt` | `latest=`, `url=`, `url_x64=` |

The `sha256=` lines in `update.txt` are written by CI from the published asset — do not
fill them by hand.

Then update the documents:

| File | What to change |
| --- | --- |
| `README.md` | the three asset filenames and the "What's new" section |
| `CHANGELOG.md` | a new `## x.y.z` section |
| `ROADMAP.md` | the progress line and the release log row |
| `docs/index.html` | the version, the download links and the changelog block |
| `bucket/mybrowser.json`, `manifests/…` | **nothing** — CI rewrites these on the tag |

`check-docs.ps1` fails if the README, the landing page or the release log lag behind.

## Release

```powershell
git tag -a vx.y.z -m "MyBrowser x.y.z"
git push origin refs/tags/vx.y.z
```

The tag build compiles, runs every gate on two Windows generations, attests provenance,
attaches the assets, and commits the refreshed Scoop and winget manifests with
`[skip ci]`.

Two files are added by hand afterwards: `MyBrowser_vx.y.z_source.7z` on the release, and
the `gh-pages` push that publishes `docs/`.

## Code layout

| Path | Contents |
| --- | --- |
| `src/MyBrowser.au3` | the application |
| `src/include/udf.au3` | inlined WinHTTP, WinAPI and accessibility helpers |
| `src/include/helpers.au3` | process, path, version, shortcut and profile helpers |
| `resources/` | the two language files, compiled into the binary |
| `build/` | build, smoke, documentation gate, manifest update |
| `docs/` | architecture, translating, landing page |

## Style

- AutoIt in this file uses spaces inside parentheses — `MsgBox ( 64 , "MyBrowser" , ... )`.
  Match the surrounding code.
- User-visible strings go through `LANG ( "Section" , "Key" , "default" )` and into both
  language files. `docs/TRANSLATING.md` lists every key.
- Log what went wrong with `_LOG`, and tell the user with `_SHOWERROR` — which also puts
  the log tail on the clipboard.
- Never add a flag that disables a sandbox or a certificate check.

## Commits

One line, present tense, saying what changed and why it matters:

```
3.9.14: cancel waits for the download worker before cleanup
```

Version-prefixed for releases, plain otherwise. No emoji.

## Reporting a bug

`SUPPORT.md` has the checklist. In short: the version, what you expected, what happened,
and the log — `MyBrowser.log` sits next to the executable.
