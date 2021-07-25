# agogpixel/foundation

Alpine container with [runit](http://smarden.org/runit/) init system, [rsyslog](https://www.rsyslog.com/) log server, [cron](https://man7.org/linux/man-pages/man8/cron.8.html), & [logrotate](https://man7.org/linux/man-pages/man8/logrotate.8.html). Intended for use as a base container image.

## Usage

When no `CMD` is provided, container will run as a daemon.

- Root user, with daemon: `docker run [-d] agogpixel/foundation`
- Root user, no daemon: `docker run -it --rm agogpixel/foundation <cmd>`

- Non-root user, with daemon: `docker run [-d] --user non-root agogpixel/foundation`
- Non-root user, no daemon: `docker run -it --rm --user non-root agogpixel/foundation <cmd>`

## Build

Images built via [docker buildx bake](https://docs.docker.com/engine/reference/commandline/buildx_bake/). See [docker-bake.hcl](./docker-bake.hcl) for details.

### Arguments

- `alpine_version`: Alpine version [tag](https://hub.docker.com/_/alpine?tab=tags&page=1&ordering=last_updated) (default: `latest`).
- `username`: Non-root user username (with [sudo](https://man7.org/linux/man-pages/man8/sudo.8.html) access) (default: `non-root`).
- `uid`: Non-root user ID (default: `1000`).
- `gid`: Non-root user group ID (default: `1000`).
- `entrypoint_path`: Path to entrypoint executable (default: `/usr/local/bin/entrypoint.sh`).
- `entrypointd_path`: Path to entrypoint script directory (default: `/usr/local/share/entrypoint.d`).
- `run_container_path`: Path to run container executable (default: `/usr/local/bin/run-container.sh`).
- `runit_path`: Path to runit configuration directory (default: `/etc/runit`).
- `service_path`: Path to service directory (default: `/etc/service`).

## Test

Images tested via bash script:

```shell
bash test.sh agogpixel/foundation:<tag>
```

## Extend

Important environment variables:

- `FOUNDATION_ALPINE_VERSION`: Alpine version (set by `alpine_version` build arg).
- `FOUNDATION_USERNAME`: Non-root user username (set by `username` build arg).
- `FOUNDATION_UID`: Non-root user ID (set by `uid` build arg).
- `FOUNDATION_GID`: Non-root user group ID (set by `gid` build arg).
- `FOUNDATION_ENTRYPOINT_PATH`: Path to entrypoint executable (set by `entrypoint_path` build arg).
- `FOUNDATION_ENTRYPOINTD_PATH`: Path to entrypoint script directory (set by `entrypointd_path` build arg).
- `FOUNDATION_RUN_CONTAINER_PATH`: Path to run container executable (set by `run_container_path` build arg).
- `FOUNDATION_RUNIT_PATH`: Path to runit configuration directory (set by `runit_path` build arg).
- `FOUNDATION_RUNIT_INITD_PATH`: Path to runit initialization directory (set by `runit_path` build arg).
- `FOUNDATION_RUNIT_TERMD_PATH`: Path to runit termination directory (set by `runit_path` build arg).
- `FOUNDATION_SERVICE_PATH`: Path to service directory (set by `service_path` build arg).

Order of execution:

1. `FOUNDATION_ENTRYPOINT_PATH`: Determine if container is running as a daemon and sources the contents of `${FOUNDATION_ENTRYPOINTD_PATH}/*.sh`.
2. `FOUNDATION_RUN_CONTAINER_PATH`: Executed via [tini](https://github.com/krallin/tini) (which is PID 1) when container running as a daemon. Starts `runit` init system lifecycle.
3. `FOUNDATION_RUNIT_INITD_PATH`: One time initialization executables located here are executed as part of the `runit` _booting_ stage (stage 1).
4. `FOUNDATION_SERVICE_PATH`: Services started & managed during the `runit` _running_ stage (stage 2).
5. `FOUNDATION_RUNIT_TERMD_PATH`: One time termination executables located here are executed as part of the `runit` _shutting down_ stage (stage 3).

### Services

See [runsvdir](http://smarden.org/runit/runsvdir.8.html) for more details on how services are managed.

See [runsv](http://smarden.org/runit/runsv.8.html) for more details on how services are run.

Example setup:

```shell
mkdir -p /etc/sv/exampled

cat >/etc/sv/exampled/run <<-EOF
#!/bin/sh
exec 2>&1
exec /usr/sbin/exampled --foreground
EOF

chmod +x /etc/sv/exampled/run

ln -s /etc/sv/exampled "${FOUNDATION_SERVICE_PATH}"/exampled

# finish is optional.
cat >/etc/sv/exampled/finish <<-EOF
#!/bin/sh
exec 2>&1
exec /bin/echo exampled exited with code $1. Restarting in 1 second...
EOF

chmod +x /etc/sv/exampled/finish
```

### Logging

Additional configuration files for logging with `rsyslog` can be added to `/etc/rsyslog.d/`.

Corresponding log rotation configuration files can be added to `/etc/logrotate.d/`.

## Contributing

Discuss the change you wish to make via issue or email.

## License

Licensed under the [MIT License](./LICENSE).

## Acknowledgments

- [nimmis/docker-alpine-micro](https://github.com/nimmis/docker-alpine-micro)
