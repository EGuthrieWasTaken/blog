# guthrieec.dev

Source and deployment config for my academic blog at
[www.guthrieec.dev](https://www.guthrieec.dev). The whole stack is free and
open source: [Hugo](https://gohugo.io/) (static site), stock
[nginx](https://nginx.org/), a self-hosted
[Shiny Server](https://posit.co/products/open-source/shiny-server/) for
interactive figures, and [Listmonk](https://listmonk.app/) for email
subscriptions. No CDNs, no third-party trackers or analytics — KaTeX, fonts,
and everything else are self-hosted.

## Repo layout

```
.
├── hugo.toml                 Hugo site config
├── archetypes/                default.md used by `hugo new`
├── layouts/                   custom layouts (no third-party theme)
│   ├── _default/              baseof, home, list, single, rss.xml
│   ├── partials/              head, header, footer, math (KaTeX loader), subscribe
│   └── shortcodes/             shiny.html, subscribe.html
├── static/                    self-hosted assets
│   ├── css/style.css          small stylesheet, incl. dark mode
│   ├── js/katex-init.js       KaTeX auto-render init
│   └── katex/                 self-hosted KaTeX 0.19.0 (css/js/fonts)
├── content/                    generated Markdown -- COMMITTED (ox-hugo output;
│   │                           the build container has no Emacs)
│   └── LICENSE                 CC BY-SA 4.0 -- covers post prose (content/ + content-org/)
├── content-org/                Org-mode sources for content/ (edited in Emacs)
├── .dir-locals.el              ox-hugo directory-local settings
├── build.sh                    builds the site and publishes it atomically
├── shiny-apps/                 one subdirectory per Shiny app (bind-mounted,
│                               never baked into the Shiny image)
├── docker/
│   ├── compose.yaml             the entire stack: blog, hugo, shiny, listmonk(-db)
│   ├── .env.example              template for docker/.env (never committed)
│   ├── nginx/default.conf        www.guthrieec.dev + lists.guthrieec.dev
│   └── shiny/                    Dockerfile (rocker/shiny-verse + plotly), shiny-server.conf
└── .github/
    ├── workflows/ci.yml           compose config / nginx -t / hugo build
    ├── workflows/shiny-image.yml   builds & publishes the Shiny image to GHCR
    └── dependabot.yml
```

## Local development

Requires [Hugo](https://gohugo.io/) (extended) and, for writing posts,
[Emacs](https://www.gnu.org/software/emacs/) with
[ox-hugo](https://github.com/kaushalmodi/ox-hugo).

```sh
hugo server -D
```

### Writing posts (Org mode -> ox-hugo -> Markdown)

1. Write/edit a post under `content-org/posts/*.org`. `.dir-locals.el`
   points `org-hugo-base-dir` at the repo root automatically (it locates
   `hugo.toml`), and sets the default export section to `posts`.
2. Export: `M-x org-hugo-export-wim-to-md` (or save, if
   `org-hugo-auto-export-mode` is active) writes the corresponding file
   under `content/posts/`.
3. **Commit both** the `.org` source and the exported `.md` file -- the
   build container has no Emacs, so `content/` must already contain the
   Markdown `build.sh`/CI will build from.

See `content-org/posts/hello-world.org` /
`content/posts/hello-world.md` for a worked example covering front matter,
math, an embedded Shiny app, and the subscribe form.

#### Math

Write inline math as `\(...\)` and display math as `\[...\]` or `$$...$$`,
and set `math: true` in the post's front matter (ox-hugo:
`#+hugo_custom_front_matter: :math true`) so the page loads KaTeX. Avoid
bare `$...$` -- see "KaTeX rendering" below for why.

#### Embedding a Shiny app

```
{{< shiny app="example" height="650" >}}
```

Renders an iframe to `<shinyBaseURL>/<app>/`. Add new apps under
`shiny-apps/` -- see `shiny-apps/README.md`.

#### Subscribe form

```
{{< subscribe >}}
```

Renders a plain-HTML (no JS) form posting to Listmonk. List UUID(s) come
from `params.listmonkListUUIDs` in `hugo.toml`.

### KaTeX rendering: why client-side auto-render, not Hugo's passthrough alone

Hugo's Goldmark **passthrough** extension (enabled in `hugo.toml`) keeps
Goldmark from mangling LaTeX source (e.g. turning `a_b` or `*x*` inside math
into HTML) as it parses Markdown -- but Hugo has no server-side KaTeX
renderer; math still has to be rendered in the browser. So this site pairs
passthrough with self-hosted KaTeX + the
[auto-render](https://katex.org/docs/autorender.html) extension
(`static/js/katex-init.js`), loaded only on pages with `math: true` in
front matter.

Passthrough is configured for `\(...\)`, `\[...\]`, and `$$...$$` only --
bare `$...$` is deliberately left out, per Hugo's own documentation: it
breaks plain-text dollar amounts and isn't reliable with prose containing
`$`. Since Org/ox-hugo preserves whatever delimiter you type, just write
math with `\(...\)` / `\[...\]` / `$$...$$` in your `.org` source and it'll
pass straight through unmangled either way.

## unRAID deployment

1. **Clone the repo** to `REPO_DIR` (e.g. `/mnt/user/appdata/blog/repo`):
   ```sh
   git clone https://github.com/<github-user>/blog.git /mnt/user/appdata/blog/repo
   ```
2. **Create the shared Docker network** (match whatever network your
   `cloudflared` container already uses):
   ```sh
   docker network create blog-net
   ```
3. **Configure environment:**
   ```sh
   cp docker/.env.example docker/.env
   # edit docker/.env: REPO_DIR, APPDATA_DIR, BLOG_PUBLIC, DOCKER_NETWORK,
   # LISTMONK_ADMIN_BIND, LISTMONK_DB_PASSWORD, LISTMONK_ADMIN_*, GITHUB_OWNER
   ```
4. **Build the site at least once** so `blog` has something to serve:
   ```sh
   ./build.sh
   ```
5. **Add the stack in Compose Manager**, pointing it at
   `REPO_DIR/docker/compose.yaml` and `REPO_DIR/docker/.env`. Compose
   Manager keeps its own project files on the flash drive, which is why
   every path in `compose.yaml` is driven by `REPO_DIR`/`APPDATA_DIR`/
   `BLOG_PUBLIC` rather than being relative.
6. **Bring the stack up:**
   ```sh
   docker compose -f docker/compose.yaml --env-file docker/.env up -d
   ```
   You don't need to run everything at once, e.g.:
   ```sh
   docker compose -f docker/compose.yaml --env-file docker/.env up -d blog shiny
   ```
7. **First-run Listmonk install** (one-shot, idempotent -- safe to re-run
   after upgrades):
   ```sh
   docker compose -f docker/compose.yaml --env-file docker/.env \
     --profile setup run --rm listmonk-setup
   ```
   Then start the long-running service: `docker compose ... up -d listmonk`.
   In the admin UI (reachable only via `LISTMONK_ADMIN_BIND`, e.g.
   `http://<unraid-ip>:9000/admin`), set **Settings -> General -> Root URL**
   to `https://lists.guthrieec.dev`, create a list, and configure SMTP
   under **Settings -> SMTP** (SMTP credentials are never stored in this
   repo). Put the list's UUID into `params.listmonkListUUIDs` in
   `hugo.toml` and rebuild.

### Cloudflare Tunnel public hostnames

Configured directly in the Cloudflare dashboard/`cloudflared` config, not
in this repo:

| Public hostname       | Origin                   |
|------------------------|---------------------------|
| `www.guthrieec.dev`    | `http://blog:80`          |
| `guthrieec.dev`        | `http://blog:80`          |
| `lists.guthrieec.dev`  | `http://blog:80`          |
| `shiny.guthrieec.dev`  | `http://shiny:3838`       |

`lists.guthrieec.dev` points at `blog`, not `listmonk` directly --
`docker/nginx/default.conf` allowlists only Listmonk's public paths and
404s everything else, including `/admin` and `/api`.

### Updating

```sh
cd /mnt/user/appdata/blog/repo
git pull
./build.sh
docker compose -f docker/compose.yaml --env-file docker/.env pull
docker compose -f docker/compose.yaml --env-file docker/.env up -d
```

### Shiny file-permission gotcha

`rocker/shiny-verse` runs app processes as a `shiny` user with **uid/gid
997** inside the container. Since `shiny-apps/` is bind-mounted read-only
from the repo and logs are bind-mounted read-write from
`APPDATA_DIR/shiny-logs`, that log directory on the unRAID host must be
writable by uid/gid 997 (e.g. `chown -R 997:997
/mnt/user/appdata/blog/shiny-logs`), or Shiny Server will fail to start/log
with a permission error. The read-only app mount doesn't need this, since
nothing writes to it.

## Security notes

- Open-source Shiny Server has **no built-in authentication**. Anyone who
  can reach `shiny.guthrieec.dev` can use the apps there. Consider a
  Cloudflare rate-limiting rule on that hostname if abuse becomes a
  concern.
- No secrets are ever committed to this repo -- `docker/.env` is gitignored;
  only `.env.example` (with placeholder values) is tracked.
- The Listmonk **admin UI/API is LAN-only**, bound via `LISTMONK_ADMIN_BIND`
  in `.env`. nginx's `lists.guthrieec.dev` server block only proxies
  Listmonk's public, unauthenticated paths and returns 404 for everything
  else, so `/admin` and `/api` are unreachable through the public tunnel
  even if `LISTMONK_ADMIN_BIND` were accidentally widened.
- SMTP credentials live only in the Listmonk admin UI's database, never in
  this repo or `.env`.

## License

This repo uses two licenses, since GPLv3 is a software license and doesn't
fit prose well:

- **Code** -- Hugo templates/shortcodes/config, `build.sh`, Docker/nginx
  config, Shiny app code, CI -- is licensed under the **GNU General Public
  License v3.0**. See [`LICENSE`](LICENSE).
- **Post prose** -- everything under [`content/`](content/) and
  [`content-org/`](content-org/) -- is licensed under
  **Creative Commons Attribution-ShareAlike 4.0 International**. See
  [`content/LICENSE`](content/LICENSE).

GitHub's own license detector only reads the root `LICENSE` file, so the
repo sidebar will show GPLv3 only -- that's just a UI limitation, not a
statement that it covers the posts too.
