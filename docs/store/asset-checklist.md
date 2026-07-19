# Play Store Asset Checklist

Generated for Blurly on July 18, 2026.

## Required Store Assets

- App icon: `docs/store/play-store-icon-512.png`
  - 512x512
  - PNG
  - Alpha-capable
  - Under 1024 KB

- Phone screenshots: `docs/store/screenshots/phone/`
  - Six files
  - 1080x1920 each
  - PNG
  - No alpha
  - Under 8 MB each

- Feature graphic: `docs/store/feature-graphic-1024x500.png`
  - 1024x500
  - PNG
  - No alpha

## Optional Store Items

- Preview video: not created.
- Tablet screenshots: not created. Add them later if the app is optimized and
  listed for tablet/large-screen promotion.

## GitHub Pages Privacy Policy

Publish `docs/privacy-policy.md` through GitHub Pages.

Suggested GitHub Pages setup:

1. Push the repo to GitHub.
2. Go to repository Settings.
3. Open Pages.
4. Set source to deploy from the `main` branch and `/docs` folder.
5. Use the generated privacy policy URL in Play Console.

Expected URL if the repository is `Topzee001/blurly`:

https://topzee001.github.io/blurly/privacy-policy/

## Final Manual Checks Before Upload

- Replace the privacy contact if you prefer an email instead of GitHub issues.
- Confirm the Play Console developer name matches the entity named in the
  privacy policy.
- Confirm release signing is not using the debug key before uploading an AAB.
- Confirm `shorebird.yaml` exists and is included in `pubspec.yaml` assets
  before building the first Shorebird release.
- Follow `docs/store/shorebird-codemagic.md` for the Codemagic secret,
  keystore, release, and patch setup.
- Confirm the Play Console privacy/data-safety answers mention Shorebird app
  update traffic while keeping photo processing on-device.
- Confirm the app's Data safety answers match the exact build you upload.
