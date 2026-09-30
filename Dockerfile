# Set image to build upon
FROM rocker/shiny

# set author
MAINTAINER Lain Pavot <lain.pavot@inra.fr>

## we copy the installer and run it before copying the entire project to prevent
## reinstalling everything each time the project has changed

COPY ./gxit/install.R /tmp/

RUN \
        apt-get update                                \
    &&  apt-get install -y --no-install-recommends    \
        fonts-texgyre                                 \
    &&  Rscript /tmp/install.R                        \
    &&  apt-get clean autoclean                       \
    &&  apt-get autoremove --yes                      \
    &&  rm -rf /var/lib/{apt,dpkg,cache,log}/         \
    &&  rm -rf /tmp/*                                 ;


# ------------------------------------------------------------------------------

# The port the app listens on. It must match <port> in the tool XML, since
# Galaxy maps that port on the container.
ARG PORT=8765

ENV PORT=$PORT

# ------------------------------------------------------------------------------

EXPOSE $PORT
COPY ./gxit/app.R /srv/shiny-server/

# Run the app with shiny::runApp() rather than shiny-server: shiny-server has a
# mandatory `run_as` directive which forces the server to be started as a fixed
# user, and it wants to write to root-owned /var/log and /var/lib directories.
# runApp() is happy under any uid, which is what a container needs when it is
# launched by different users (Galaxy runs containers as the job owner).
CMD Rscript -e "shiny::runApp('/srv/shiny-server', host = '0.0.0.0', port = ${PORT}, launch.browser = FALSE)"
