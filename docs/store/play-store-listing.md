# Blurly Google Play Listing

Use this as the working copy for the Play Console store listing.

## App Details

- App name: Blurly
- Package name: `com.topzee.blurly`
- Default language: English (United States)
- App or game: App
- Free or paid: Free
- Contains ads: No
- App category suggestion: Photography
- Tags suggestion: Photo editor, Background blur, Portrait editor

## Short Description

On-device background blur for portraits and quick photo edits.

## Full Description

Blurly is a simple on-device photo editor for blurring image backgrounds.

Pick a photo, take a portrait, or share an image directly to Blurly from your
Android device. Blurly processes the image locally, keeps the subject clear, and
lets you adjust the blur intensity before saving or sharing the result.

Features:

- Pick photos from your gallery.
- Capture new portraits with the camera.
- Receive photos through Android's share sheet.
- Blur backgrounds locally on your device.
- Use Person mode for portrait background blur.
- Use Bokeh mode for a warmer styled background blur.
- Compare original and blurred previews.
- Adjust blur intensity from 0% to 100%.
- Save processed PNG images to your gallery.
- Share processed images from the app.

Blurly is built for privacy. It works without an account, without ads, and
without uploading your photos to a server. Internet access is used only for app
update checks and downloads.

Note: Blurly currently works best with portraits and people. Non-person object
photos may use a centered subject fallback and may need manual retrying with a
better-framed image.

## What's New

Initial release.

## Graphic Assets

App icon:

- `docs/store/play-store-icon-512.png`
- 512x512 PNG, alpha-capable, under 1024 KB.

Feature graphic:

- `docs/store/feature-graphic-1024x500.png`
- 1024x500 PNG, no alpha.

Phone screenshots:

- `docs/store/screenshots/phone/01-pick-or-shoot.png`
- `docs/store/screenshots/phone/02-compare-original.png`
- `docs/store/screenshots/phone/03-person-background-blur.png`
- `docs/store/screenshots/phone/04-bokeh-style.png`
- `docs/store/screenshots/phone/05-save-and-share.png`
- `docs/store/screenshots/phone/06-share-to-blurly.png`

Each phone screenshot is 1080x1920 PNG with no alpha.

Recommended upload order:

1. `01-pick-or-shoot.png`
2. `03-person-background-blur.png`
3. `04-bokeh-style.png`
4. `05-save-and-share.png`
5. `02-compare-original.png`
6. `06-share-to-blurly.png`

The share-sheet screenshot is useful, but if Play review flags non-app UI, keep
the first five screenshots and remove the sixth.

## Screenshot Alt Text

- Start screen showing options to pick a gallery photo or capture a portrait.
- Original preview screen for comparing the unedited portrait.
- Person mode screen showing a clear subject with a blurred background.
- Bokeh mode screen showing a styled blurred background with intensity controls.
- Blurly editor screen with save and share actions visible.
- Android share flow showing Blurly as a direct image share target.

## Privacy Policy URL

If GitHub Pages is enabled from the `docs/` folder, use:

https://topzee001.github.io/blurly/privacy-policy/

If you use a different GitHub Pages source or custom domain, update the URL in
Play Console accordingly.

## Data Safety Draft Answers

Based on the current on-device photo-processing implementation with Shorebird
app updates:

- Does the app collect or share user data types? No collection by Blurly.
- Does the app transmit user photos off device? No.
- Does the app process photos locally on device? Yes.
- Are photos saved? Only when the user taps Save, to their device/gallery.
- Are photos shared? Only when the user explicitly taps Share or sends an image
  to another app through Android's share sheet.
- Account creation: No.
- Ads: No.
- Analytics: No.
- Crash reporting: No.
- Backend/server for photo processing: No.
- App update service: Yes, Shorebird checks for and downloads app updates.
- Encryption in transit: Yes for Shorebird update traffic.
- Data deletion: No server-side data exists. Users delete saved images from
  their device.

Google Play notes that on-device processing that is not sent off device does not
need to be disclosed as collection, but on-device transfer to another app can be
treated as sharing unless it fits the user-initiated sharing exception. Review
the Play Console wording carefully before submitting.

## Content Rating Notes

Suggested answers, assuming the app remains a general photo utility:

- Violence: No
- Sexual content: No
- Profanity: No
- Controlled substances: No
- User-generated content sharing/social features: No public sharing inside app
- Online purchases: No
- Location sharing: No
- Personal information collection: No

## Permissions Explanation

Use this wording if Play Console asks why permissions are needed:

Blurly uses camera and photo/media permissions so users can choose or capture a
photo, process it locally, and save the edited result. Blurly uses internet
permission only to check for and download app updates through Shorebird. Photos
are not uploaded to a server.
