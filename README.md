# Jellyfin installer for Tizen OS through Docker

This multi-stage Dockerfile builds jellyfin-web, jellyfin-tizen,
and packages it in a `.wgt` tizen package file, to be installed
on a Tizen TV. A base, reusable image with just tizen-studio is
also built.

Tested with podman and docker.


## QuickStart

```
podman build -t jellyfin-tizen-install .
podman run -it --rm jellyfin-tizen-install 192.168.3.4
```
> [!NOTE]
> You need to know the ip address of the TV set

Add `-v tizen-studio-data:/home/ubuntu/tizen-studio-data` to podman-run to persist
`tizen-studio-data`, especially the author certificate (`.p12`) file.
The certificate is needed if you want to upgrade the application without
uninstalling it first. All of the rest in the Docker images can be rebuilt.

## Samsung TV Dev Mode

Check the [jellyfin-tizen/wiki](https://github.com/jellyfin/jellyfin-tizen/wiki)
