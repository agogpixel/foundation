# agogpixel/foundation

Alpine container with [runit](http://smarden.org/runit/) init system, [rsyslog](https://www.rsyslog.com/) log server, [cron](https://man7.org/linux/man-pages/man8/cron.8.html), & [logrotate](https://man7.org/linux/man-pages/man8/logrotate.8.html). Intended for use as a base container image.

## Usage

- Root user, with daemon: `docker run -d agogpixel/foundation`
- Root user, no daemon: `docker run -it --rm agogpixel/foundation <cmd>`

- Non-root user, with daemon: `docker run -d --user non-root agogpixel/foundation`
- Non-root user, no daemon: `docker run -it --rm --user non-root agogpixel/foundation <cmd>`

## Build

Images built via [docker buildx bake](https://docs.docker.com/engine/reference/commandline/buildx_bake/). See [docker-bake.hcl](./docker-bake.hcl) for details.

### Build Arguments

- `alpine_version`: Alpine version [tag](https://hub.docker.com/_/alpine?tab=tags&page=1&ordering=last_updated).
- `username`: Non-root user username (with [sudo](https://man7.org/linux/man-pages/man8/sudo.8.html) access) (default: `non-root`).
- `uid`: Non-root user ID (default: `1000`).
- `gid`: Non-root user group ID (default: `1000`).

## Test

Images tested via bash script:

```shell
IMAGE=agogpixel/foundation:<tag> bash test.bash
```

## Contributing

Discuss the change you wish to make via issue or email.

## License

Licensed under the [MIT License](./LICENSE).

## Acknowledgments

- [nimmis/docker-alpine-micro](https://github.com/nimmis/docker-alpine-micro)
