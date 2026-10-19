#!/usr/bin/env bash

set -Eeuo pipefail

log() {
    printf '[minikube] %s\n' "$*"
}

die() {
    printf '[minikube] Error: %s\n' "$*" >&2
    exit 1
}

command -v minikube >/dev/null 2>&1 \
    || die "Minikube is not installed. Install the minikube package before running this module."
command -v virsh >/dev/null 2>&1 \
    || die "libvirt is not installed. Run the VM host setup before this module."
command -v kubectl >/dev/null 2>&1 \
    || die "kubectl is not installed. Install the kubectl package before running this module."

minikube config set driver kvm2
minikube config set container-runtime docker
minikube config set cpus 2
minikube config set memory 6144
minikube config set disk-size 20000mb
minikube config unset rootless

[[ "$(minikube config get driver)" == "kvm2" ]] \
    || die "Failed to configure the KVM2 driver."
[[ "$(minikube config get container-runtime)" == "docker" ]] \
    || die "Failed to configure the Docker runtime."
[[ "$(minikube config get cpus)" == "2" ]] \
    || die "Failed to configure two CPUs."
[[ "$(minikube config get memory)" == "6144" ]] \
    || die "Failed to configure 6144 MiB of memory."
[[ "$(minikube config get disk-size)" == "20000mb" ]] \
    || die "Failed to configure a 20000 MB disk."

log "Configured Minikube to match this machine: KVM2, Docker, 2 CPUs, 6144 MiB RAM, and a 20000 MB disk."
log "Start a cluster with: minikube start"
