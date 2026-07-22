#!/bin/bash

# The mailsync part of this file is based on https://github.com/Foundry376/Mailspring-Sync/blob/master/build.sh
# It required so many patches to work with our build system that it was easier to just copy it here and modify it.
# The core differences are:
# - Remove usages of sudo, we neither have it nor need it
# - Set install prefixes to /app, /usr is not writable as it is part of the runtime
# - Remove all the weird code related to SASL_PATH, we installed our version to /app, just use that
# - Always build in a dedicated build directory, in-source builds are not reproducible for whatever reason
# Since we already have our own script, we also do this:
# - Include only the Linux code, no need to support MacOS
# - General code cleanups

set -e

# Alias these, to make the code more generic and adaptable to other build systems
SRC_DIR="$FLATPAK_BUILDER_BUILDDIR" # /run/build/Mailspring
DST_DIR="$FLATPAK_DEST"             # /app
PKG_ID="$FLATPAK_ID"                # com.mailspring.Mailspring
NUM_JOBS="$FLATPAK_BUILDER_N_JOBS"  # $(nproc)

export MAKEFLAGS="-j$NUM_JOBS"
export CMAKE_PREFIX_PATH="$DST_DIR"

echo "Building and installing libetpan..."
cd "$SRC_DIR/mailsync/Vendor/libetpan"
./autogen.sh --prefix="$DST_DIR" --with-openssl
make
make install

echo "Building mailcore2..."
cd "$SRC_DIR/mailsync/Vendor/mailcore2"
mkdir -p build
cd build
cmake ..
cmake --build . --target MailCore

echo "Building mailsync..."
cd "$SRC_DIR/mailsync"
mkdir -p build
cd build
cmake ..
cmake --build . --target mailsync
cp ./mailsync "$SRC_DIR/app/mailsync"

echo "Building Mailspring..."
cd "$SRC_DIR"

jq ". + {\"name\": \"${PKG_ID}\"}" app/package.json > app/package.json.tmp && mv app/package.json.tmp app/package.json
jq ". + {\"desktopName\": \"${PKG_ID}.desktop\"}" app/package.json > app/package.json.tmp && mv app/package.json.tmp app/package.json

npm ci --no-audit --no-fund
npm run build -- --skip-installers

echo "Filling in template files..."
for key in name productName desktopName description; do
    sed -i "s|<%= ${key} %>|$(jq -r ".${key}" app/package.json)|g" \
        app/build/resources/linux/Mailspring.desktop.in \
        app/build/resources/linux/mailspring.metainfo.xml.in
done

echo "Installing Mailspring..."
cp -r app/dist/mailspring-linux-* $DST_DIR/share/mailspring && find $DST_DIR/share/mailspring -type d -exec chmod 755 {} \;
install -Dm755 mailspring.sh $DST_DIR/bin/mailspring
install -Dm644 app/build/resources/linux/Mailspring.desktop.in $DST_DIR/share/applications/$PKG_ID.desktop
install -Dm644 app/build/resources/linux/mailspring.metainfo.xml.in $DST_DIR/share/metainfo/$PKG_ID.metainfo.xml
for size in 16 32 64 128 256 512; do
    install -Dm644 "app/build/resources/linux/icons/${size}.png" "$DST_DIR/share/icons/hicolor/${size}x${size}/apps/$PKG_ID.png";
done

echo "Mailspring build & installation complete!"
