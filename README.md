# Mailspring Flatpak

Unofficial Flatpak package for Mailspring ([Website](https://getmailspring.com/), [GitHub](https://github.com/Foundry376/Mailspring)).

## Building & Installing

```bash
# User installation
flatpak-builder --force-clean --install-deps-from=flathub --ccache --install --user build-dir com.getmailspring.Mailspring.yml

# System installation
sudo flatpak-builder --force-clean --install-deps-from=flathub --ccache --install build-dir com.getmailspring.Mailspring.yml
```

If your distribution doesn't have `flatpak-builder`, try with `flatpak run org.flatpak.Builder` instead.

After that, Mailspring will be installed in your system. You can run start it from your favorite app launcher or by running `flatpak run com.getmailspring.Mailspring` in the terminal.

## Updating

```bash
# If not already done, clone the repository
git clone git@github.com:Foundry376/Mailspring.git

# Checkout to the version we want to package
cd Mailspring
git pull
git checkout <version>

# Print the commit hash, it is needed in the manifest
git rev-parse HEAD

# generate the generated-sources.json file
# See https://github.com/flatpak/flatpak-builder-tools/blob/master/node/README.md
flatpak-node-generator npm --electron-node-headers -r package-lock.json -o ../generated-sources.json
```

Then in `com.getmailspring.Mailspring.yml`:
* update the `tag` and `commit` fields with the new version and hash
* update the `npm_package_config_node_gyp_nodedir` field with the correct electron version (from `package.json`)
* ensure that the patches are still required and work correctly. Add new patches if necessary.
