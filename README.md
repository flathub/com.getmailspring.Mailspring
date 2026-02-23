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

After that, Mailspring will be installed in your system. You can run it from your favorite app launcher or by running `flatpak run com.getmailspring.Mailspring` in the terminal.
