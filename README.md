GxIT
====

This tool is a very simple GxIT, with code based on:
 - https://github.com/rstudio/shiny-examples/blob/master/001-hello/app.R
 - https://github.com/rstudio/shiny-examples/blob/master/009-upload/app.R
 - https://github.com/rstudio/shiny-examples/blob/master/010-download/app.R

It is a fork of https://github.com/Lain-inrae/geoc-gxit with the app started by
`shiny::runApp()` instead of `shiny-server` — see [Why not shiny-server?](#why-not-shiny-server).

Requirement
-----------

 - [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
 - [docker](https://docs.docker.com/engine/install/)

Build and test
--------------

```bash
git clone https://github.com/paulzierep/geoc-gxit.git
cd geoc-gxit
make docker      # builds and tags paulzierep/gtn-gxit:latest
make it          # runs it in the foreground
```

Then go to <http://127.0.0.1:8765>.

```bash
make log         # follow the app output while it runs
make d           # run detached instead
make sh          # shell into the running container
make clean       # kill containers, remove the image
```

Use with Galaxy / planemo
-------------------------

The tool XML expects the image `paulzierep/gtn-gxit:latest`, which is exactly
what `make docker` produces. If you change the image name in one place, change
it in all three (`Makefile`, `Dockerfile`, tool XML), or Galaxy will silently
pull a different image from the registry.

Serve the tool with planemo:

```bash
planemo serve interactivetool_tabulator.xml \
  --biocontainers
```

- **The first launch of any tool pulls its image.** While a multi-GB image is
  downloading the job is still queued and there is no entry point yet, so the UI
  shows the same *"No URL available"* message. Pre-pull with
  `docker pull <image>` if you want to tell a download apart from a real failure.


Why not shiny-server?
---------------------

The original image ran `shiny-server`, which needs patching before it works in a
Galaxy container:

- `shiny-server.conf` has a mandatory `run_as` directive, so the server insists
  on running as one fixed user. Galaxy starts a container as the *job owner*,
  whose uid differs per user, and the server has to be able to run as any uid.
- It wants to write to `/var/log/shiny-server` and `/var/lib/shiny-server`,
  which are root-owned and not writable by an arbitrary uid.

`shiny::runApp()` has neither requirement, so the container works unchanged
under root, under uid 999, and under uid 1000:

```bash
CMD Rscript -e "shiny::runApp('/srv/shiny-server', host = '0.0.0.0', port = ${PORT}, launch.browser = FALSE)"
```

Because the app now logs to stdout/stderr instead of a file, `make log` uses
`docker logs -f` rather than tailing a `LOG_PATH` inside the container. The
`LOG_PATH` build argument is gone.

Deploy
------

The image is published as [`paulzierep/gtn-gxit`](https://hub.docker.com/r/paulzierep/gtn-gxit). To push a new build, log in first and then:

```bash
docker login          # Docker Hub user name + an access token, not your account password
make docker
make push_hub USERNAME=paulzierep
```

Or push the tags built by `make docker` directly:

```bash
docker push paulzierep/gtn-gxit:latest
docker push paulzierep/gtn-gxit:1.0.0
```

<details><summary>Unattended push via a .password file</summary>

```bash
printf '%s' '<your-access-token>' > .password
make push_hub USERNAME=paulzierep
rm -f .password
```

`.password` holds a secret and is listed in `.gitignore`.
</details>

<details><summary>Original upstream target</summary>

```bash
make docker
make push_hub USERNAME=<docker-hub-user>   # needs a .password file
```

</details>

Update
------

```bash
git pull --rebase
make docker
```

Run
---

 - `make it` — run docker in interactive mode
 - `make d` — run docker in detached mode
 - `make sh` — connect to the container while it is running
 - `make log` — follow the app output while it is running

