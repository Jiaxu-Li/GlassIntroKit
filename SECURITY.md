# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x | Yes |

Fixes are released for the latest 0.1.x version.

## Reporting a vulnerability

Please report vulnerabilities privately, not in a public issue.

1. Open the repository's **Security** tab on GitHub.
2. Choose **Report a vulnerability**.
3. Describe the problem, the affected version, and steps to reproduce it.

If you cannot use GitHub Security Advisories, contact the maintainer, Jiaxu Li, through their [GitHub profile](https://github.com/Jiaxu-Li) and ask for a private channel. Do not include details in a public message.

## What to expect

- An acknowledgment within a few days.
- An assessment, and questions if more detail is needed.
- A fix and a new release for confirmed issues, with credit to you if you wish.
- Public disclosure after a fix is available.

This is a small project maintained by one person, so response times are best effort.

## What the package does

To help you judge the scope of a report:

- It makes no network requests.
- It stores one Boolean in `UserDefaults` (or in a `GlassIntroStorage` you provide) to record that the welcome has played.
- It runs a Metal shader on the GPU to render the 3D scene. Reports of crashes, hangs, or out-of-bounds behavior in the shader or its host code are in scope.
