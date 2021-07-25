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

- `alpine_version`: Alpine version [tag](https://hub.docker.com/_/alpine?tab=tags&page=1&ordering=last_updated).
- `username`: Non-root user username (with [sudo](https://man7.org/linux/man-pages/man8/sudo.8.html) access) (default: `non-root`).
- `uid`: Non-root user ID (default: `1000`).
- `gid`: Non-root user group ID (default: `1000`).

## Test

Images tested via bash script:

```shell
bash test.sh agogpixel/foundation:<tag>
```

## Extend

Important filesystem paths and order of execution:

1. `/usr/local/bin/entrypoint.sh`: Determine if container is running as a daemon, and sources the contents of `/usr/local/share/entrypoint.d/*.sh`.
2. `/usr/local/share/entrypoint.d/`: Additional entrypoint scripts that reside here will be sourced by the shell.
3. `/usr/local/bin/run-container.sh`: Executed via [tini](https://github.com/krallin/tini) (which is PID 1) when container running as a daemon. Starts `runit` init system lifecycle.
4. `/etc/runit/init.d/`: One time initialization executables located here are executed as part of the `runit` _booting_ stage (stage 1).
5. `/etc/service/`: Location of the collection of services managed during the `runit` _running_ stage (stage 2).
6. `/etc/runit/term.d/`: One time termination executables located here are executed as part of the `runit` _shutting down_ stage (stage 3).

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

ln -s /etc/sv/exampled /etc/service/exampled

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
