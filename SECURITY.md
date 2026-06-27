# Security Policy

Blurly is a local-first image processing app. It should not upload user images
or processed outputs to a server.

## Supported Versions

Security fixes target the latest `main` branch until the project starts cutting
versioned releases.

## Reporting a Vulnerability

If you find a vulnerability, please do not publish exploit details in a public
issue first.

Use GitHub private vulnerability reporting when it is enabled:

<https://github.com/Topzee001/blurly/security/advisories/new>

If private reporting is unavailable, contact the maintainer privately and
include:

- A clear description of the issue.
- Steps to reproduce.
- Affected platform: Android, iOS, or both.
- Whether private images, local files, or permissions are exposed.
- Suggested fix, if known.

## Security Scope

In scope:

- Accidental image upload or network transfer.
- Unsafe file handling for saved/shared images.
- Permission misuse.
- Crashes caused by malformed image files.
- Dependency vulnerabilities that affect the app.

Out of scope:

- General model-quality issues.
- Expected gallery/camera permission prompts.
- Vulnerabilities in unsupported forks.

## Privacy Expectations

Blurly should process photos on-device. Any future feature that sends images,
masks, telemetry, or model inputs off-device must be documented, optional, and
reviewed carefully before merge.
