#!/usr/bin/env bash

set -Eeuo pipefail

log() {
    printf '[minikube] %s\n' "$*"
}

die() {
    printf '[minikube] Error: %s\n' "$*" >&2
    exit 1
}

command -v podman >/dev/null 2>&1 \
    || die "Podman is not installed. Run the Podman setup before this module."
command -v minikube >/dev/null 2>&1 \
    || die "Minikube is not installed. Install the minikube package before running this module."

[[ "$(podman info --format '{{.Host.Security.Rootless}}')" == "true" ]] \
    || die "Podman is not running rootless for the current user."

minikube config set driver podman
minikube config set rootless true
minikube config set container-runtime containerd

[[ "$(minikube config get driver)" == "podman" ]] \
    || die "Failed to configure the Podman driver."
[[ "$(minikube config get rootless)" == "true" ]] \
    || die "Failed to enable rootless mode."
[[ "$(minikube config get container-runtime)" == "containerd" ]] \
    || die "Failed to configure the containerd runtime."

log "Configured Minikube to use rootless Podman with containerd."
log "Start a cluster with: minikube start"
