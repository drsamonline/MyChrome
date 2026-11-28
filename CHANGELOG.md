# Changelog

Every release, newest first. Full notes and downloads on the
[releases page](https://github.com/drsamonline/MyChrome/releases).

| Version | Highlights |
|---|---|
| [3.9.34](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.34) | A partial download from another version is discarded. |
| [3.9.33](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.33) | Swap refuses drive roots; closes its own browser first. |
| [3.9.32](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.32) | Firefox launch path quoted; unsafe profile names refused. |
| [3.9.31](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.31) | System proxy, including PAC, for downloads too. |
| [3.9.30](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.30) | The System proxy setting now applies to lookups. |
| [3.9.29](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.29) | TLS 1.2 forced on WinHTTP; failed lookups are logged. |
| [3.9.28](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.28) | `/profile <name>` selects and remembers a profile. |
| [3.9.27](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.27) | Named profiles via `ActiveProfile`. |
| [3.9.26](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.26) | `/update` runs headless; exit codes report the outcome. |
| [3.9.25](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.25) | Self-test report keeps full URLs. |
| [3.9.24](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.24) | Self-update verifies its download; translation guide. |
| [3.9.23](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.23) | Self-test can be pointed at a dead endpoint; verified on windows-2022. |
| [3.9.22](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.22) | Optional non-blocking update notice; first-run behaviour tested. |
| [3.9.21](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.21) | Any language can be added by dropping `Lang\<code>.ini` and setting `Language=<code>`; user files are never overwritten. |
| [3.9.20](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.20) | Cent downloads from the vendor page instead of a link page. |
| [3.9.19](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.19) | App helpers split into `src/include/helpers.au3`; main file down to 5,323 lines. |
| [3.9.18](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.18) | A `.zip` is published next to the `.7z`; winget manifests added. |
| [3.9.17](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.17) | Scoop manifest with real hashes; documentation consistency pass. |
| [3.9.16](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.16) | A missing architecture is logged instead of failing silently. |
| [3.9.15](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.15) | Self-update can fall back to a mirror named in `update.txt` (inert until a host exists). |
| [3.9.14](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.14) | Cancelling an update waits for the download worker before cleaning up. |
| [3.9.13](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.13) | Leftover `~update` / `~updated` folders are removed at startup. |
| [3.9.12](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.12) | Failure dialogs copy the message and the log tail to the clipboard. |
| [3.9.11](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.11) | 1,557 lines of helpers moved to `src/include/udf.au3`. |
| [3.9.10](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.10) | All 222 interface strings live in the language files. |
| [3.9.9](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.9) | Download progress shows time remaining. |
| [3.9.8](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.8) | Edge lookup moved to proxy-aware WinHTTP with a timeout; Edge verified for the first time. |
| [3.9.7](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.7) | Download pages point at the vendors, not a third party. |
| [3.9.6](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.6) | Atomic folder swap with rollback. |
| [3.9.5](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.5) | Vivaldi downloads from its real appcast instead of a link page. |
| [3.9.4](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.4) | "No" skips one release instead of disabling update checks forever. |
| [3.9.3](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.3) | Hardcoded Google API credentials removed. |
| [3.9.2](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.2) | Disk-space guard, temp cleanup, apply pre-flight, portable launch flags, HTTPS-only mirrors. |
| [3.9.1](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.1) | Firefox, Chromium and Brave download sources repaired. |
| [3.9.0](https://github.com/drsamonline/MyChrome/releases/tag/v3.9.0) | Rebuilt from recovered source; Chrome via Chrome for Testing. |

## 3.9.34

- `ResumeVersion` in the ini records which version a partial download belongs to; a mismatch deletes it.

## 3.9.33

- The atomic swap refuses a drive root or a single-level folder.
- The update closes the browser instance this launcher started before falling back to closing by name, and logs how many.

## 3.9.32

- The Firefox launch command quotes the executable path, so a path with spaces works.
- `ActiveProfile` names containing path separators or `..` are refused.

## 3.9.31

- The downloader honours the System proxy; both paths resolve PAC through `GETIEPROXY`.
- The proxy actually used is logged.

## 3.9.30

- Choosing "System" for the proxy now passes the Windows proxy configuration to the lookup; it used to fall through to no proxy.

## 3.9.29

- Every WinHTTP session requests TLS 1.2, fixing lookups on Windows 7/8.1.
- A failed browser lookup writes the browser, channel, platform, proxy and error to `MyBrowser.log`.

## 3.9.28

- `MyBrowser.exe /profile <name>` uses `App\Profiles\<name>` for this run and writes it to the ini.

## 3.9.27

- `ActiveProfile=<name>` keeps the browser data in `App\Profiles\<name>` and wins over `UserDataDir`.

## 3.9.26

- `MyBrowser.exe /update` updates without a desktop; exit 0 updated, 1 not updated, 3 configuration incomplete.
- Every prompt in the update path answers itself in CLI mode.

## 3.9.25

- The self-test report no longer truncates download URLs at 90 characters.

## 3.9.24

- `update.txt` carries `sha256` / `sha256_x64`; the self-updater verifies before unpacking.
- `docs/TRANSLATING.md` lists all 224 interface keys.

## 3.9.23

- `SelfTestProxy` lets CI inject an unreachable endpoint and assert a clean, bounded failure.
- A second CI job runs the same checks on `windows-2022`.

## 3.9.22

- `SilentUpdateCheck=1` shows a tray notification instead of a modal update dialog.
- CI asserts that a first run creates `MyBrowser.ini` with the right `AppVersion`.

## 3.9.21

- Any language can be added by dropping `Lang\<code>.ini` and setting `Language=<code>`; user files are never overwritten.
- Cent added to the self-test — verified resolving 5.3.1184.31.

## 3.9.20

- Cent downloads from the vendor page instead of a link page.
- Vendor SHA256 compared with `certutil` and logged (evidence, not a gate).

## 3.9.19

- App helpers split into `src/include/helpers.au3`; main file down to 5,323 lines.

## 3.9.18

- A `.zip` is published next to the `.7z`; winget manifests added.

## 3.9.17

- Scoop manifest with real hashes; documentation consistency pass.

## 3.9.16

- A missing architecture is logged instead of failing silently.
- `CHANGELOG.md` added.

## 3.9.15

- Self-update can fall back to a mirror named in `update.txt` (inert until a host exists).

## 3.9.14

- Cancelling an update waits for the download worker before cleaning up.

## 3.9.13

- Leftover `~update` / `~updated` folders are removed at startup.
- The build refuses to ship if the version disagrees in source, language files or `update.txt`.

## 3.9.12

- Failure dialogs copy the message and the log tail to the clipboard.
- One instance per installation.

## 3.9.11

- 1,557 lines of helpers moved to `src/include/udf.au3`.
- A wedged resume is discarded after two attempts instead of looping.

## 3.9.10

- All 222 interface strings live in the language files.
- CI asserts the upgrade path from 3.8.50.

## 3.9.9

- Download progress shows time remaining.
- Retries back off 400/800 ms.
- The settings window reopens where it was left.
- Build provenance attestation on tagged builds.

## 3.9.8

- Edge lookup moved to proxy-aware WinHTTP with a timeout; Edge verified for the first time.
- The Edge download URL is fetched over https first.

## 3.9.7

- Download pages point at the vendors, not a third party.
- Brave lookups cached for 24 hours.
- Standalone framing: the contributor list is this project only.

## 3.9.6

- Atomic folder swap with rollback.
- `MyBrowser.exe /selftest` probes every source; CI runs it.
- Firefox version lookup no longer hangs.

## 3.9.5

- Vivaldi downloads from its real appcast instead of a link page.
- 17-browser support matrix; support block.

## 3.9.4

- "No" skips one release instead of disabling update checks forever.
- `MyBrowser.log` added; the unpacked version is asserted.

## 3.9.3

- Hardcoded Google API credentials removed.
- `--no-sandbox` dropped from the defaults; command injection in the injection path fixed.
- Archive integrity test; `SHA256SUMS.txt`; DPI awareness.

## 3.9.2

- Disk-space guard, temp cleanup, apply pre-flight, portable launch flags, HTTPS-only mirrors.

## 3.9.1

- Firefox, Chromium and Brave download sources repaired.
- GPL-3.0 `LICENSE` and `NOTICE` added.

## 3.9.0

- Rebuilt from recovered source; Chrome via Chrome for Testing.
- Source, build and CI published.
