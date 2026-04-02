#!/bin/bash

set -e

mkdir -p reproducible-check/build

flatpak-builder --force-clean --install-deps-from=flathub --ccache --disable-cache reproducible-check/build/1 com.getmailspring.Mailspring.yml
flatpak-builder --force-clean --install-deps-from=flathub --ccache --disable-cache reproducible-check/build/2 com.getmailspring.Mailspring.yml

diffoscope --markdown reproducible-check/diff.md reproducible-check/build/1 reproducible-check/build/2
