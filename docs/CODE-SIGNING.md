# Code signing policy

This project's Windows executables are unsigned today. This page describes how they will
be signed, and what a signature will and will not prove.

## Publisher

Signing is provided through **SignPath Foundation**. Their certificate is issued in the
foundation's name, so a signed `MyBrowser.exe` shows **SignPath Foundation** as the
publisher — not an individual.

> Free code signing provided by SignPath.io, certificate by SignPath Foundation

## Team roles and members

| Role | Who |
| --- | --- |
| Committers and reviewers | [Dr Sohil Momin](https://github.com/drsamonline) — sole maintainer |
| Approvers | [Dr Sohil Momin](https://github.com/drsamonline) |

Every release requires manual approval before it is signed. The signing key is held on
SignPath's hardware security module; it is never present in this repository or in CI logs.

## What is signed

| Artefact | Signed |
| --- | --- |
| `MyBrowser.exe` (x64) | yes, once signing is enabled |
| `MyBrowser_x86.exe` | yes, once signing is enabled |
| `MyBrowser_v*.7z` / `.zip` | no — these are archives; the executable inside carries the signature |
| `SHA256SUMS.txt` | no — it is a text manifest, verified by hash |

## What a signature proves, and what it does not

| Proves | Does not prove |
| --- | --- |
| The binary was built from this repository's source by this repository's workflow | That the code is free of bugs |
| The build was not altered after it left the workflow | That the browser it downloads is trustworthy — that is the vendor's signature |
| The publisher is SignPath Foundation on behalf of this project | Anything about the browser binaries the launcher fetches |

## Verification, without a signature

Every release ships `SHA256SUMS.txt` and a build provenance attestation. Both work today:

```powershell
./build/verify-release.ps1 -Path .\MyBrowser_v3.9.38_x64.7z
```

That checks the published hash and, when the GitHub CLI is installed, the attestation that
records which workflow produced the file.

## Why this repository is eligible

| Condition | Status |
| --- | --- |
| OSI-approved licence, no commercial dual-licensing | GPL-3.0, see [`LICENSE`](../LICENSE) |
| No proprietary components | the bundled 7-Zip binaries are LGPL-2.1, see [`licenses/`](../licenses/) |
| Actively maintained | see [`CHANGELOG.md`](../CHANGELOG.md) |
| Already released | see [releases](https://github.com/drsamonline/MyChrome/releases) |
| Documented | [`README.md`](../README.md) and [`SUPPORT.md`](../SUPPORT.md) |

## Lineage, declared

The AutoIt source derives from [`cnjackchen/my-chrome`](https://github.com/cnjackchen/my-chrome)
(GPL-3.0), recovered from a compiled binary and then substantially changed. That lineage is
stated here and in [`NOTICE`](../NOTICE) so it is visible to anyone assessing eligibility.
