# Blurly landing page

This standalone static site lives in `dist/`. It uses existing Blurly store
screenshots, two app captures for the before/after comparison, and a generated
editorial hero photograph. The comparison images show actual app output; the
hero is illustrative photography.

## Run locally

From the repository root:

```sh
cd website/dist
python3 -m http.server 4173 --bind 127.0.0.1
```

Open <http://127.0.0.1:4173/>. The privacy policy is at
<http://127.0.0.1:4173/privacy.html>. Press `Ctrl+C` in the terminal to stop
the server. If port `4173` is in use, replace it with another free port in the
command and URL. No build step or JavaScript package installation is needed.

## Deploy with Vercel

The Vercel project root is `website/`. `vercel.json` selects the `dist/`
folder as the published output and the Other framework preset.

### Deploy the local files now

```sh
cd website
vercel login
vercel --prod
```

The Vercel CLI is already installed on this development machine. On another
machine, run `npm install -g vercel` first if the `vercel` command is missing.
Run `vercel login` interactively; the existing login on this machine has
expired.

Choose your Vercel account and create a new project when prompted. Run these
commands from `website/`, not the Flutter repository root. The first deployment
gives you a public `*.vercel.app` URL. Check the home page, comparison slider,
Google Play links, and `/privacy.html` on that URL.

### Connect GitHub for future updates

Commit and push the `website/` files, then import the `Topzee001/blurly`
repository in Vercel. Set **Root Directory** to `website`. Confirm the
**Framework Preset** is `Other`, **Output Directory** is `dist`, and the
**Build Command** is blank. Select the branch you want to publish to
production; Vercel normally uses `main` when that branch exists. Pushes to
other branches get preview deployments.

If you already created the project with the CLI, run `vercel git connect` from
`website/` after pushing the files to GitHub. This connects that same project
to the repository instead of creating a second project. Keep the Vercel
project root set to `website`.

The Sites project identity and static directory are in `.openai/hosting.json`.
Site publication uses an isolated checkout; this directory remains ordinary
source inside the Flutter repository.
