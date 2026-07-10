#!/usr/bin/env bash

# Secure fingerprint setup for Hyprlock on Arch-based systems.
#
# Quick usage:
#   ./executable_fingerprint_setup.sh setup
#       Install dependencies, remove fingerprint authentication from privileged
#       PAM services, restrict fprintd with polkit, verify the rendered Hyprlock
#       configuration, enroll the configured fingers, and audit the result.
#
#   ./executable_fingerprint_setup.sh enroll
#       Enroll missing fingers and verify one scan. Override the defaults with:
#       FPRINT_FINGERS="left-index-finger right-middle-finger" ./executable_fingerprint_setup.sh enroll
#
#   ./executable_fingerprint_setup.sh audit
#       Make no configuration changes; report hardware and security status.
#
#   ./executable_fingerprint_setup.sh clear-storage
#       Permanently erase every template in the reader's on-chip storage,
#       including Windows Hello templates. This requires typing a confirmation
#       containing the expected USB ID. Host records under /var/lib/fprint are
#       intentionally not deleted.
#
# Important security behavior:
#   - Fingerprints unlock Hyprlock through its parallel fprintd integration.
#   - Password fallback and pam_faillock remain enabled.
#   - Fingerprints are removed from sudo and are not enabled for su, polkit
#     privilege prompts, or global PAM authentication.
#   - Verification is limited to the configured active local user.
#   - Enrollment and deletion through fprintd require root authorization.
#
# Configuration environment variables:
#   FPRINT_USER                 Target regular user (default: invoking user)
#   FPRINT_DEVICE_ID            Required USB ID (default: 27c6:6594)
#   FPRINT_FINGERS              Space-separated finger names to enroll
#   FPRINT_SKIP_FIRMWARE_CHECK  Set to 1 to skip fwupd checks during setup

set -Eeuo pipefail

readonly scriptName="${0##*/}"
readonly expectedDeviceId="${FPRINT_DEVICE_ID:-27c6:6594}"
readonly policyFile="/etc/polkit-1/rules.d/49-hyprlock-fingerprint.rules"
readonly stateDir="/var/lib/hyprlock-fingerprint-setup"
readonly backupDir="${stateDir}/backups"

temporaryFiles=()

cleanup() {
    if ((${#temporaryFiles[@]} > 0)); then
        rm -f -- "${temporaryFiles[@]}"
    fi
}
trap cleanup EXIT

log() {
    printf '[fingerprint] %s\n' "$*"
}

warn() {
    printf '[fingerprint] Warning: %s\n' "$*" >&2
}

die() {
    printf '[fingerprint] Error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: ${scriptName} [setup|enroll|audit|clear-storage]

Actions:
  setup          Securely configure fingerprint unlock, then enroll and audit.
  enroll         Enroll missing configured fingers and verify one scan.
  audit          Check hardware, packages, PAM, polkit, enrollment, and sleep.
  clear-storage  Permanently erase every template stored inside the reader.

Environment:
  FPRINT_USER                 Target user (default: SUDO_USER or current user)
  FPRINT_DEVICE_ID            Required USB ID (default: 27c6:6594)
  FPRINT_FINGERS              Space-separated fingers to enroll
                              (default: right-index-finger left-index-finger)
  FPRINT_SKIP_FIRMWARE_CHECK  Set to 1 to skip fwupd metadata/update checks

The setup intentionally enables fingerprints only through Hyprlock's parallel
fprintd support. It does not enable fingerprint authentication for sudo, su,
polkit privilege prompts, or global PAM authentication.

clear-storage also removes Windows Hello templates from the reader, requires
explicit interactive confirmation, and does not delete /var/lib/fprint data.
EOF
}

run_root() {
    if ((EUID == 0)); then
        "$@"
    else
        sudo -- "$@"
    fi
}

run_as_target() {
    if ((EUID == targetUid)); then
        "$@"
    elif ((EUID == 0)); then
        runuser -u "${targetUser}" -- "$@"
    else
        sudo -u "${targetUser}" -- "$@"
    fi
}

action="${1:-setup}"
if (($# > 1)); then
    usage >&2
    exit 2
fi

case "${action}" in
    setup | enroll | audit | clear-storage) ;;
    help | -h | --help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

if [[ "$(uname -s)" != "Linux" ]]; then
    die "Fingerprint setup is only supported on Linux."
fi

if ! command -v getent >/dev/null 2>&1; then
    die "getent is required to resolve the target user."
fi

targetUser="${FPRINT_USER:-${SUDO_USER:-$(id -un)}}"
if [[ ! "${targetUser}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    die "Unsafe or unsupported target username: ${targetUser}"
fi

passwdEntry="$(getent passwd "${targetUser}" || true)"
if [[ -z "${passwdEntry}" ]]; then
    die "Target user does not exist: ${targetUser}"
fi

IFS=: read -r _ _ targetUid _ _ targetHome _ <<<"${passwdEntry}"
if [[ ! "${targetUid}" =~ ^[0-9]+$ ]]; then
    die "Target user has an invalid UID: ${targetUid}"
fi
if ((targetUid == 0)); then
    die "Refusing to enroll fingerprints for root. Set FPRINT_USER to a regular user."
fi
if ((targetUid < 1000)); then
    die "Refusing to enroll fingerprints for system user ${targetUser} (UID ${targetUid})."
fi
if [[ ! -d "${targetHome}" ]]; then
    die "Target user's home directory does not exist: ${targetHome}"
fi

if [[ ! "${expectedDeviceId}" =~ ^[[:xdigit:]]{4}:[[:xdigit:]]{4}$ ]]; then
    die "Invalid FPRINT_DEVICE_ID: ${expectedDeviceId}"
fi

read -r -a enrollFingers <<<"${FPRINT_FINGERS:-right-index-finger left-index-finger}"
if ((${#enrollFingers[@]} == 0)); then
    die "FPRINT_FINGERS must contain at least one finger."
fi

for finger in "${enrollFingers[@]}"; do
    case "${finger}" in
        left-thumb | left-index-finger | left-middle-finger | left-ring-finger | left-little-finger | \
            right-thumb | right-index-finger | right-middle-finger | right-ring-finger | right-little-finger) ;;
        *) die "Unsupported finger name in FPRINT_FINGERS: ${finger}" ;;
    esac
done

readonly targetUser targetUid targetHome
readonly hyprlockConfig="${targetHome}/.config/hypr/hyprlock.conf"

require_arch_packages() {
    if ! command -v pacman >/dev/null 2>&1; then
        die "This module currently supports Arch-based systems with pacman."
    fi
}

install_packages() {
    log "Installing the supported fingerprint, firmware, and Hyprlock packages."
    run_root pacman -S --needed fprintd libfprint usbutils fwupd hyprlock python-gobject
}

require_commands() {
    local commandName
    for commandName in lsusb fprintd-list fprintd-enroll fprintd-verify hyprlock; do
        if ! command -v "${commandName}" >/dev/null 2>&1; then
            die "Required command is missing after package installation: ${commandName}"
        fi
    done
}

ensure_supported_device() {
    local deviceOutput

    if ! lsusb -d "${expectedDeviceId}" >/dev/null 2>&1; then
        die "Expected fingerprint reader ${expectedDeviceId} was not found by lsusb."
    fi

    if ! deviceOutput="$(run_as_target fprintd-list "${targetUser}" 2>&1)"; then
        printf '%s\n' "${deviceOutput}" >&2
        die "fprintd could not access the fingerprint reader."
    fi

    log "Detected ${expectedDeviceId}; fprintd can access the reader."
}

backup_root_file() {
    local sourceFile="$1"
    local backupName="$2"
    local timestamp

    timestamp="$(date +%Y%m%d-%H%M%S)"
    run_root install -d -o root -g root -m 0700 "${backupDir}"
    run_root cp --preserve=all -- "${sourceFile}" "${backupDir}/${backupName}.${timestamp}"
}

harden_sudo_pam() {
    local pamFile="/etc/pam.d/sudo"
    local editedFile stagedFile

    if [[ ! -f "${pamFile}" ]]; then
        die "Expected sudo PAM file does not exist: ${pamFile}"
    fi

    if ! grep -Eq '^[[:space:]]*auth[[:space:]].*pam_fprintd\.so' "${pamFile}"; then
        log "sudo PAM already uses password-only authentication."
        return
    fi

    log "Removing unsafe fingerprint-only authentication from sudo."
    backup_root_file "${pamFile}" sudo

    editedFile="$(mktemp)"
    temporaryFiles+=("${editedFile}")
    awk '!/^[[:space:]]*auth[[:space:]].*pam_fprintd\.so/' "${pamFile}" >"${editedFile}"

    if grep -q 'pam_fprintd\.so' "${editedFile}"; then
        die "Failed to remove pam_fprintd from the staged sudo PAM configuration."
    fi
    if ! grep -Eq '^[[:space:]]*auth[[:space:]]+include[[:space:]]+system-auth' "${editedFile}"; then
        die "Refusing to install a sudo PAM configuration without the system-auth password path."
    fi

    stagedFile="${pamFile}.fingerprint-setup.$$"
    run_root install -o root -g root -m 0644 "${editedFile}" "${stagedFile}"
    run_root mv -f -- "${stagedFile}" "${pamFile}"
}

install_polkit_policy() {
    local ruleFile

    if run_root test -e "${policyFile}" && \
        ! run_root grep -q '^// Managed by executable_fingerprint_setup.sh$' "${policyFile}"; then
        die "Refusing to overwrite an unmanaged polkit rule: ${policyFile}"
    fi

    ruleFile="$(mktemp)"
    temporaryFiles+=("${ruleFile}")
    cat >"${ruleFile}" <<EOF
// Managed by executable_fingerprint_setup.sh
// Fingerprints unlock only the active local Hyprlock session for ${targetUser}.
polkit.addRule(function (action, subject) {
    if (action.id == "net.reactivated.fprint.device.verify") {
        if (subject.user == "${targetUser}" && subject.local && subject.active) {
            return polkit.Result.YES;
        }
        return polkit.Result.NO;
    }

    if (action.id == "net.reactivated.fprint.device.enroll" ||
        action.id == "net.reactivated.fprint.device.setusername") {
        return subject.user == "root" ? polkit.Result.YES : polkit.Result.NO;
    }
});
EOF

    run_root install -d -o root -g polkitd -m 0750 /etc/polkit-1/rules.d
    run_root install -o root -g root -m 0644 "${ruleFile}" "${policyFile}"
    log "Installed a user-restricted fprintd polkit policy for ${targetUser}."
}

hyprlock_category_has_value() {
    local category="$1"
    local key="$2"
    local expectedValue="$3"
    local configFile="$4"

    [[ -f "${configFile}" ]] || return 1

    awk -v category="${category}" -v key="${key}" -v expected="${expectedValue}" '
        function setting_value(line) {
            sub(/^[^=]*=[[:space:]]*/, "", line)
            sub(/[[:space:]]*#.*/, "", line)
            sub(/[[:space:]]+$/, "", line)
            return line
        }
        BEGIN {
            inside = 0
            depth = 0
            last_value = ""
            category_start = "^[[:space:]]*" category "[[:space:]]*\\{"
            setting = "^[[:space:]]*" key "[[:space:]]*="
            direct = "^[[:space:]]*auth:" category ":" key "[[:space:]]*="
        }
        $0 ~ direct {
            last_value = setting_value($0)
        }
        !inside && $0 ~ category_start {
            inside = 1
            depth = 0
        }
        inside && $0 ~ setting {
            last_value = setting_value($0)
        }
        inside {
            line = $0
            opens = gsub(/\{/, "", line)
            closes = gsub(/\}/, "", line)
            depth += opens - closes
            if (depth <= 0) {
                inside = 0
            }
        }
        END {
            exit(last_value == expected ? 0 : 1)
        }
    ' "${configFile}"
}

verify_hyprlock_config() {
    if hyprlock_category_has_value fingerprint enabled true "${hyprlockConfig}"; then
        log "Hyprlock parallel fingerprint authentication is already enabled."
        return
    fi

    die "Hyprlock fingerprint authentication is not enabled in ${hyprlockConfig}. Apply the chezmoi template on a host whose name contains 'laptop', then rerun setup."
}

check_sleep_mode() {
    local sleepModes

    if [[ ! -r /sys/power/mem_sleep ]]; then
        warn "Could not inspect /sys/power/mem_sleep."
        return
    fi

    sleepModes="$(</sys/power/mem_sleep)"
    if [[ "${sleepModes}" == *'[s2idle]'* ]]; then
        log "s2idle is active, as recommended by libfprint upstream."
    else
        warn "s2idle is not active (${sleepModes}); fingerprint resume reliability may suffer."
    fi
}

check_firmware_updates() {
    if [[ "${FPRINT_SKIP_FIRMWARE_CHECK:-0}" == "1" ]]; then
        log "Skipping firmware checks because FPRINT_SKIP_FIRMWARE_CHECK=1."
        return
    fi

    if ! command -v fwupdmgr >/dev/null 2>&1; then
        warn "fwupdmgr is unavailable; firmware status was not checked."
        return
    fi

    log "Refreshing firmware metadata; firmware will not be installed automatically."
    if ! fwupdmgr refresh --force; then
        warn "Firmware metadata refresh failed."
    fi

    log "Checking for firmware updates. Review any updates before installing them."
    fwupdmgr get-updates || true
}

clear_device_storage() {
    local confirmation expectedConfirmation

    if [[ ! -t 0 || ! -t 1 ]]; then
        die "Device storage clearing requires an interactive terminal."
    fi
    if ! command -v lsusb >/dev/null 2>&1; then
        die "lsusb is required. Install the usbutils package first."
    fi
    if ! lsusb -d "${expectedDeviceId}" >/dev/null 2>&1; then
        die "Expected fingerprint reader ${expectedDeviceId} was not found by lsusb."
    fi
    if [[ ! -x /usr/bin/python ]] || \
        ! /usr/bin/python -c 'import gi; gi.require_version("FPrint", "2.0"); from gi.repository import FPrint' >/dev/null 2>&1; then
        die "Python FPrint bindings are unavailable. Install python-gobject and libfprint."
    fi

    expectedConfirmation="CLEAR ${expectedDeviceId}"
    printf '\nThis permanently erases every fingerprint template stored inside reader %s.\n' "${expectedDeviceId}" >&2
    printf 'Windows Hello fingerprints stored on this reader will also be removed.\n' >&2
    printf 'Host-side fprintd records under /var/lib/fprint will not be changed.\n' >&2
    read -r -p "Type '${expectedConfirmation}' to continue: " confirmation
    if [[ "${confirmation}" != "${expectedConfirmation}" ]]; then
        die "Confirmation did not match; sensor storage was not changed."
    fi

    log "Stopping fprintd to obtain exclusive access to the reader."
    run_root systemctl stop fprintd.service

    run_root /usr/bin/python - <<'PY'
import gi

gi.require_version("FPrint", "2.0")
from gi.repository import FPrint

context = FPrint.Context()
devices = context.get_devices()

if len(devices) != 1:
    raise SystemExit(f"Expected exactly one fingerprint reader, found {len(devices)}")

device = devices[0]
if not device.has_feature(FPrint.DeviceFeature.STORAGE_CLEAR):
    raise SystemExit(f"{device.get_name()} does not support clearing on-chip storage")

device.open_sync(None)
try:
    if device.has_feature(FPrint.DeviceFeature.STORAGE_LIST):
        prints = device.list_prints_sync(None)
        print(f"Deleting {len(prints)} on-device fingerprint template(s):")
        for fingerprint in prints:
            print(
                f"  user={fingerprint.get_username()!r} "
                f"description={fingerprint.get_description()!r}"
            )

    device.clear_storage_sync(None)
finally:
    device.close_sync(None)

print("Fingerprint sensor storage cleared")
PY

    log "On-device fingerprint storage was cleared."
    warn "Host-side records in /var/lib/fprint were not deleted. Use fprintd-delete for any users that still have Linux records."
    log "fprintd is D-Bus activated and will start automatically when next needed."
}

enroll_fingers() {
    local finger listOutput enrollOutput

    if [[ ! -t 0 || ! -t 1 ]]; then
        die "Enrollment requires an interactive terminal. Run '${scriptName} enroll' from a terminal."
    fi

    listOutput="$(run_as_target fprintd-list "${targetUser}" 2>&1 || true)"
    for finger in "${enrollFingers[@]}"; do
        if grep -Fq -- "${finger}" <<<"${listOutput}"; then
            log "${finger} is already enrolled for ${targetUser}; skipping it."
            continue
        fi

        log "Enroll ${finger} for ${targetUser} when prompted."
        enrollOutput="$(mktemp)"
        temporaryFiles+=("${enrollOutput}")
        if run_root fprintd-enroll -f "${finger}" "${targetUser}" 2>&1 | tee "${enrollOutput}"; then
            listOutput="$(run_as_target fprintd-list "${targetUser}" 2>&1 || true)"
            continue
        fi

        if grep -Fq 'enroll-duplicate' "${enrollOutput}"; then
            warn "${finger} already exists in sensor storage, possibly for Windows Hello or an older Linux installation."
            warn "Leaving that sensor template untouched and continuing with the next configured finger."
            continue
        fi

        die "Enrollment failed for ${finger}. No fingerprints were deleted."
    done

    listOutput="$(run_as_target fprintd-list "${targetUser}" 2>&1 || true)"
    if [[ -z "${listOutput}" ]] || grep -Fq 'has no fingers enrolled' <<<"${listOutput}"; then
        die "No usable Linux fingerprints were enrolled. Rerun the enroll action with FPRINT_FINGERS set to fingers not already used by Windows or another installation."
    fi

    log "Verify an enrolled fingerprint when prompted."
    if ! run_as_target fprintd-verify "${targetUser}"; then
        die "Fingerprint verification failed. Password unlock remains available."
    fi
}

auditFailures=0

audit_pass() {
    printf '[audit] PASS: %s\n' "$*"
}

audit_fail() {
    printf '[audit] FAIL: %s\n' "$*" >&2
    ((auditFailures += 1))
}

audit_warn() {
    printf '[audit] WARN: %s\n' "$*" >&2
}

audit_setup() {
    local packageName listOutput pamMatches pamService pamFile policyMetadata recentErrors
    local -a restrictedPamServices=(
        sudo sudo-i su su-l polkit-1
        system-auth system-local-login system-login system-remote-login system-services
        login greetd hyprlock
    )

    auditFailures=0
    log "Auditing the fingerprint setup for ${targetUser}."

    for packageName in fprintd libfprint usbutils fwupd hyprlock python-gobject; do
        if pacman -Q "${packageName}" >/dev/null 2>&1; then
            audit_pass "Package installed: ${packageName}"
        else
            audit_fail "Package missing: ${packageName}"
        fi
    done

    if pacman -Qkk fprintd libfprint hyprlock pambase >/dev/null 2>&1; then
        audit_pass "Fingerprint, Hyprlock, and PAM package files pass integrity checks"
    else
        audit_fail "A fingerprint, Hyprlock, or PAM package file failed its integrity check"
    fi

    if command -v lsusb >/dev/null 2>&1 && lsusb -d "${expectedDeviceId}" >/dev/null 2>&1; then
        audit_pass "Expected USB reader is present: ${expectedDeviceId}"
    else
        audit_fail "Expected USB reader is absent: ${expectedDeviceId}"
    fi

    if command -v fprintd-list >/dev/null 2>&1 && \
        listOutput="$(run_as_target fprintd-list "${targetUser}" 2>&1)"; then
        audit_pass "fprintd can access the reader as ${targetUser}"
        if grep -Fq 'has no fingers enrolled' <<<"${listOutput}"; then
            audit_fail "No fingerprints are enrolled for ${targetUser}"
        else
            audit_pass "At least one fingerprint is enrolled for ${targetUser}"
        fi
    else
        audit_fail "fprintd cannot access the reader as ${targetUser}"
    fi

    if hyprlock_category_has_value fingerprint enabled true "${hyprlockConfig}"; then
        audit_pass "Hyprlock parallel fingerprint authentication is enabled"
    else
        audit_fail "Hyprlock parallel fingerprint authentication is not enabled"
    fi

    if hyprlock_category_has_value pam enabled false "${hyprlockConfig}"; then
        audit_fail "Hyprlock password authentication is explicitly disabled"
    elif [[ -f /etc/pam.d/hyprlock ]] && \
        grep -Eq '^[[:space:]]*auth[[:space:]]+include[[:space:]]+' /etc/pam.d/hyprlock; then
        audit_pass "Hyprlock retains its PAM password fallback"
    else
        audit_fail "Hyprlock PAM password fallback could not be verified"
    fi

    pamMatches=""
    for pamService in "${restrictedPamServices[@]}"; do
        if [[ -f "/etc/pam.d/${pamService}" ]]; then
            pamFile="/etc/pam.d/${pamService}"
        elif [[ -f "/usr/lib/pam.d/${pamService}" ]]; then
            pamFile="/usr/lib/pam.d/${pamService}"
        else
            continue
        fi

        if grep -q 'pam_fprintd\.so' "${pamFile}"; then
            pamMatches+="${pamFile}"$'\n'
        fi
    done

    if [[ -z "${pamMatches}" ]]; then
        audit_pass "Fingerprint authentication is absent from privileged and global PAM services"
    else
        pamMatches="${pamMatches%$'\n'}"
        audit_fail "Fingerprint authentication remains in restricted PAM services: ${pamMatches//$'\n'/, }"
    fi

    if grep -q 'pam_faillock\.so' /etc/pam.d/system-auth; then
        audit_pass "PAM password failure lockout remains enabled"
    else
        audit_fail "PAM password failure lockout is not enabled in system-auth"
    fi

    if run_root test -f "${policyFile}" && \
        run_root grep -Fq "subject.user == \"${targetUser}\" && subject.local && subject.active" "${policyFile}" && \
        run_root grep -Fq 'subject.user == "root" ? polkit.Result.YES : polkit.Result.NO' "${policyFile}"; then
        audit_pass "polkit restricts verification to ${targetUser} and enrollment to root"
    else
        audit_fail "Managed user-restricted polkit policy is missing or incorrect"
    fi

    if run_root test -f "${policyFile}"; then
        policyMetadata="$(run_root stat -c '%a %U %G' "${policyFile}")"
        if [[ "${policyMetadata}" == "644 root root" ]]; then
            audit_pass "polkit rule ownership and permissions are secure"
        else
            audit_fail "Unexpected polkit rule metadata: ${policyMetadata}"
        fi
    fi

    if [[ -d /var/lib/fprint ]]; then
        policyMetadata="$(run_root stat -c '%a %U %G' /var/lib/fprint)"
        if [[ "${policyMetadata}" == "700 root root" ]]; then
            audit_pass "Fingerprint storage is root-only"
        else
            audit_fail "Unexpected fingerprint storage metadata: ${policyMetadata}"
        fi
    else
        audit_fail "Fingerprint storage directory does not exist"
    fi

    if [[ -r /sys/power/mem_sleep ]] && [[ "$(</sys/power/mem_sleep)" == *'[s2idle]'* ]]; then
        audit_pass "s2idle is active"
    else
        audit_warn "s2idle is not active or could not be inspected"
    fi

    recentErrors="$(run_root journalctl -u fprintd.service --since '-7 days' -p warning --no-pager -q 2>/dev/null || true)"
    if [[ -n "${recentErrors}" ]]; then
        audit_warn "fprintd logged warnings in the last seven days; inspect 'journalctl -u fprintd.service'"
    else
        audit_pass "fprintd has no recent warning-level journal entries"
    fi

    if ((auditFailures > 0)); then
        printf '[audit] %d check(s) failed.\n' "${auditFailures}" >&2
        return 1
    fi

    printf '[audit] All required security checks passed.\n'
}

require_arch_packages

case "${action}" in
    setup)
        run_root true
        harden_sudo_pam
        install_packages
        require_commands
        ensure_supported_device
        install_polkit_policy
        verify_hyprlock_config
        check_sleep_mode
        check_firmware_updates
        enroll_fingers
        audit_setup
        log "Secure Hyprlock fingerprint setup is complete."
        log "Root backups of changed PAM files are in ${backupDir}."
        ;;
    enroll)
        require_commands
        ensure_supported_device
        if ! run_root test -f "${policyFile}"; then
            die "Run '${scriptName} setup' before enrolling fingerprints."
        fi
        enroll_fingers
        ;;
    audit)
        run_root true
        audit_setup
        ;;
    clear-storage)
        clear_device_storage
        ;;
esac
