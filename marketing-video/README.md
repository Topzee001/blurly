# Blurly social demo

A 21-second, 1080x1920 portrait demo for Instagram Reels, TikTok, and YouTube
Shorts. It uses real Android app screen recordings and a Blurly-exported result.

## Preview and export

From this directory:

```sh
npm ci
npm run dev
```

Open the Studio URL and select `BlurlySocialDemo`. To export an MP4:

```sh
npx remotion render BlurlySocialDemo out/blurly-social-demo.mp4 --codec h264
```

The video is deliberately silent. Add music licensed within each platform, or
record a personal voiceover. Suggested voiceover, timed to the edit:

- 0-4s: "Here's the same portrait before and after Blurly."
- 4-8s: "I adjust the blur until the background feels right."
- 8-14s: "Then I brush over the areas that need a little more attention."
- 14-18s: "The subject stays sharp while the background softens."
- 18-21s: "Find Blurly on Google Play."

## Posting copy

Instagram Reels: "Same portrait, less distraction. A quick background blur and
a small brush refinement in Blurly. Available on Android. Link in bio.
#Blurly #PhotoEditing #PortraitPhotography"

TikTok: "Watch the background soften. Pick, adjust, refine. Blurly is on
Google Play. #Blurly #PhotoEdit #Portrait"

YouTube Shorts title: "Soften a portrait background on Android | Blurly demo"

YouTube description: "A real Blurly app demo using a sample portrait.
Get Blurly: https://play.google.com/store/apps/details?id=com.topzee.blurly
Learn more: https://blurly-mu.vercel.app/"

## Source notes

`portrait-original.jpg` is the generated illustrative portrait already used on
the Blurly website. `portrait-blurred.png` was saved by Blurly on a connected
Android device from that same portrait. The video clips and brush-preview still
are recordings of the app running on that device. This is a creator-style app
demo, not a customer testimonial; do not present it as one. The app's processing
wait is shortened in the intensity scene and labeled as such on screen.
