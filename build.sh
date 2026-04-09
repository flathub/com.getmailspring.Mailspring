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

# Faster compilation
export MAKEFLAGS="-j${FLATPAK_BUILDER_N_JOBS:-$(nproc)}"

# Set the prefix to /app, as /usr is not writable in the flatpak sandbox
# Also required to find the modules we built and installed to /app
export CMAKE_PREFIX_PATH="$DST_DIR"

# The oldest version supported by SDK 25.08
export CMAKE_POLICY_VERSION_MINIMUM="3.5"

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
jq ". + {\"desktopName\": \"${PKG_ID}.desktop\"}" app/package.json > app/package.json.tmp && mv app/package.json.tmp app/package.json
npm ci
npm run build

echo "Filling in template files..."
function template_fillin() {
    cd "$SRC_DIR/app"
    name="$1"
    value=$(jq -r ".${name}" package.json)
    sed -i "s|<%= ${name} %>|${value}|g" build/resources/linux/Mailspring.desktop.in build/resources/linux/mailspring.appdata.xml.in
}
template_fillin "name"
template_fillin "productName"
template_fillin "description"

echo "Installing Mailspring..."
cd "$SRC_DIR"
cp -r app/dist/mailspring-linux-* $DST_DIR/share/mailspring && find $DST_DIR/share/mailspring -type d -exec chmod 755 {} \;
install -Dm755 mailspring.sh $DST_DIR/bin/mailspring
install -Dm644 app/build/resources/linux/Mailspring.desktop.in $DST_DIR/share/applications/Mailspring.desktop
install -Dm644 app/build/resources/linux/mailspring.appdata.xml.in $DST_DIR/share/appdata/mailspring.appdata.xml
for size in 16 32 64 128 256 512; do
  [[ -e "app/build/resources/linux/icons/${size}.png" ]] && install -Dm644 "app/build/resources/linux/icons/${size}.png" "$DST_DIR/share/icons/hicolor/${size}x${size}/apps/mailspring.png";
done

echo "Flatpak build complete!"
