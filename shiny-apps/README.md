# Shiny apps

Each subdirectory here is one Shiny application, bind-mounted read-only into
the `shiny` container at `/srv/shiny-server/<name>` (see `docker/compose.yaml`).
Nothing in this directory is baked into the `docker/shiny` image.

Served at `https://shiny.guthrieec.dev/<name>/` and embedded in posts with:

```
{{< shiny app="<name>" height="650" >}}
```

## Adding a new app

1. Create `shiny-apps/<name>/app.R` (or `ui.R` + `server.R`).
2. Any R packages the app needs beyond tidyverse/plotly must be added to
   `docker/shiny/Dockerfile` and the image rebuilt (locally with
   `docker compose build shiny`, or via the `shiny-image.yml` GitHub Actions
   workflow, which publishes to GHCR).
3. Use fixed axis limits / fixed layout dimensions where possible so the
   embedded iframe doesn't jump around as inputs change.
4. Test locally: `docker compose up -d shiny` and visit
   `http://localhost:3838/<name>/` (requires `SHINY_PORT` set in `.env`).
5. Reference it from a post with the `shiny` shortcode shown above.

## Permissions

Shiny Server runs app processes as the `shiny` user (uid/gid defined in the
`rocker/shiny-verse` base image). Since apps are bind-mounted from the
unRAID appdata share rather than copied into the image, that share must be
readable by the `shiny` user's uid/gid -- see the "Shiny file-permission
gotcha" note in the top-level README if apps fail to load with a permission
error in `/var/log/shiny-server`.
