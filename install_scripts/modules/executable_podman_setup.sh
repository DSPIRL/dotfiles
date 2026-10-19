#!/usr/bin/env bash

set -Eeuo pipefail

readonly minimumSubids=65536
readonly sysctlFile="/etc/sysctl.d/99-podman-rootless.conf"
targetUser="${PODMAN_USER:-${SUDO_USER:-$(id -un)}}"

log() {
    printf '[podman] %s\n' "$*"
}

die() {
    printf '[podman] Error: %s\n' "$*" >&2
    exit 1
}

run_root() {
    if ((EUID == 0)); then
        "$@"
    else
        sudo -- "$@"
    fi
}

if [[ "$(uname -s)" != "Linux" ]]; then
    die "Podman setup is only supported on Linux."
fi

if ! command -v getent >/dev/null 2>&1; then
    die "getent is required to resolve the target user."
fi

passwdEntry="$(getent passwd "${targetUser}" || true)"
if [[ -z "${passwdEntry}" ]]; then
    die "Target user does not exist: ${targetUser}"
fi

IFS=: read -r _ _ targetUid _ _ targetHome _ <<<"${passwdEntry}"
if [[ ! "${targetUid}" =~ ^[0-9]+$ ]] || ((targetUid < 1000)); then
    die "Rootless Podman requires a regular target user; got ${targetUser} (${targetUid:-invalid})."
fi
readonly targetUser targetUid targetHome

run_as_target() {
    if ((EUID == targetUid)); then
        "$@"
    elif ((EUID == 0)); then
        runuser -u "${targetUser}" -- env \
            HOME="${targetHome}" XDG_RUNTIME_DIR="/run/user/${targetUid}" "$@"
    else
        sudo -u "${targetUser}" env \
            HOME="${targetHome}" XDG_RUNTIME_DIR="/run/user/${targetUid}" "$@"
    fi
}

for dependency in podman crun conmon pasta; do
    command -v "${dependency}" >/dev/null 2>&1 \
        || die "${dependency} is required to reproduce this machine's Podman setup."
done
[[ -x /usr/lib/podman/netavark ]] \
    || die "netavark is required to reproduce this machine's Podman network backend."
[[ -x /usr/lib/podman/aardvark-dns ]] \
    || die "aardvark-dns is required by the netavark network backend."

ensure_user_namespaces() {
    local currentValue

    if ! currentValue="$(sysctl -n kernel.unprivileged_userns_clone 2>/dev/null)"; then
        log "kernel.unprivileged_userns_clone is not exposed by this kernel; no sysctl change is needed."
        return
    fi
    if [[ "${currentValue}" == "1" ]]; then
        log "Unprivileged user namespaces are enabled."
        return
    fi

    if run_root test -e "${sysctlFile}" && \
        ! run_root grep -q '^# Managed by executable_podman_setup.sh$' "${sysctlFile}"; then
        die "Refusing to overwrite unmanaged file ${sysctlFile}."
    fi

    printf '%s\n' \
        '# Managed by executable_podman_setup.sh' \
        'kernel.unprivileged_userns_clone = 1' \
        | run_root tee "${sysctlFile}" >/dev/null
    run_root sysctl --system >/dev/null

    [[ "$(sysctl -n kernel.unprivileged_userns_clone)" == "1" ]] \
        || die "Failed to enable unprivileged user namespaces."
    log "Enabled unprivileged user namespaces through ${sysctlFile}."
}

has_sufficient_subids() {
    local file="$1"

    [[ -r "${file}" ]] && awk -F: -v user="${targetUser}" -v minimum="${minimumSubids}" '
        $1 == user && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ && $3 >= minimum { found = 1 }
        END { exit(found ? 0 : 1) }
    ' "${file}"
}

next_subid_range() {
    local file="$1"

    awk -F: -v width="${minimumSubids}" '
        $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ && $3 > 0 {
            starts[++count] = $2
            ends[count] = $2 + $3 - 1
        }
        END {
            candidate = 100000
            do {
                moved = 0
                candidate_end = candidate + width - 1
                for (i = 1; i <= count; i++) {
                    if (candidate <= ends[i] && candidate_end >= starts[i]) {
                        candidate = ends[i] + 1
                        moved = 1
                    }
                }
            } while (moved)
            printf "%d-%d\n", candidate, candidate + width - 1
        }
    ' "${file}"
}

subidsChanged=0
ensure_subids() {
    local file="$1"
    local usermodOption="$2"
    local label="$3"
    local range

    run_root touch "${file}"
    if has_sufficient_subids "${file}"; then
        log "${targetUser} already has at least ${minimumSubids} subordinate ${label}s."
        return
    fi

    range="$(next_subid_range "${file}")"
    run_root usermod "${usermodOption}" "${range}" "${targetUser}"
    has_sufficient_subids "${file}" \
        || die "Failed to allocate subordinate ${label}s for ${targetUser}."
    subidsChanged=1
    log "Allocated subordinate ${label} range ${range} to ${targetUser}."
}

ensure_user_namespaces
ensure_subids /etc/subuid --add-subuids UID
ensure_subids /etc/subgid --add-subgids GID

if [[ ! -d "/run/user/${targetUid}" ]]; then
    die "The user runtime directory is unavailable. Log in as ${targetUser} and rerun this module."
fi

if ((subidsChanged)); then
    run_as_target podman system migrate
fi

run_as_target systemctl --user enable --now podman.socket
run_as_target podman info >/dev/null

[[ "$(run_as_target podman info --format '{{.Host.Security.Rootless}}')" == "true" ]] \
    || die "Podman is not running rootless."
[[ "$(run_as_target podman info --format '{{.Host.OCIRuntime.Name}}')" == "crun" ]] \
    || die "Podman did not select crun as its OCI runtime."
[[ "$(run_as_target podman info --format '{{.Host.NetworkBackend}}')" == "netavark" ]] \
    || die "Podman did not select netavark as its network backend."
[[ "$(run_as_target podman info --format '{{.Host.RootlessNetworkCmd}}')" == "pasta" ]] \
    || die "Podman did not select pasta for rootless networking."
[[ "$(run_as_target podman info --format '{{.Store.GraphDriverName}}')" == "overlay" ]] \
    || die "Podman did not select overlay storage."

socketPath="/run/user/${targetUid}/podman/podman.sock"
[[ -S "${socketPath}" ]] || die "Podman socket was not created at ${socketPath}."

log "Rootless Podman is ready for ${targetUser}."
log "Socket: unix://${socketPath}"
