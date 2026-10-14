# rocker/shiny-verse already bundles R, Shiny Server, and the tidyverse.
# We only add plotly on top. No blog content or app code is baked in here --
# apps are bind-mounted read-only from ../../shiny-apps at runtime.
FROM rocker/shiny-verse:4.6.1

RUN install2.r --error --skipinstalled remotes \
    && R -e "remotes::install_version('plotly', version = '4.12.1', repos = 'https://cloud.r-project.org')" \
    && rm -rf /tmp/downloaded_packages

COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
