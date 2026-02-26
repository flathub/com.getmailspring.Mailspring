#!/bin/sh

# TMPDIR must point to XDG_RUNTIME_DIR so that Chromium's shared-memory segments are on a tmpfs that is visible to all processes in the sandbox
export TMPDIR="${XDG_RUNTIME_DIR}/app/${FLATPAK_ID}"

# When Wayland is available we enhance mailspring with IME support.
# When Wayland is absent we explicitly force X11 so Electron does not attempt auto-detection and fall back awkwardly.
EXTRA_ARGS=""
if [[ -e "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY:-wayland-0}" || -e "${WAYLAND_DISPLAY}" ]]; then
    EXTRA_ARGS="--enable-wayland-ime --wayland-text-input-version=3"
else
    EXTRA_ARGS="--ozone-platform=x11"
fi

exec zypak-wrapper /app/share/mailspring/mailspring ${EXTRA_ARGS} "$@"
