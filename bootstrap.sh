#!/bin/sh

# Prepare a new Mac: install Homebrew if necessary, apply dotfile symlinks, and
# install the declarative package list in Brewfile.

set -eu

repository_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! xcode-select -p >/dev/null 2>&1; then
  printf '%s\n' 'Apple Command Line Tools are required. Run: xcode-select --install' >&2
  exit 1
fi

if command -v brew >/dev/null 2>&1; then
  brew_bin=$(command -v brew)
elif [ "$(uname -m)" = "arm64" ]; then
  brew_bin=/opt/homebrew/bin/brew
else
  brew_bin=/usr/local/bin/brew
fi

if [ ! -x "$brew_bin" ]; then
  printf '%s\n' 'Installing Homebrew...'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ ! -x "$brew_bin" ]; then
  printf '%s\n' 'Homebrew installation did not complete.' >&2
  exit 1
fi

eval "$("$brew_bin" shellenv)"

"$repository_dir/install.sh"

# Load the network-share agent immediately. It will also start automatically
# at future logins and retry quietly whenever the NAS is temporarily offline.
network_share_agent="$HOME/Library/LaunchAgents/de.sascha.mount-network-shares.plist"
if [ -f "$network_share_agent" ]; then
  launchctl bootout "gui/$(id -u)" "$network_share_agent" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$network_share_agent"
  launchctl kickstart -k "gui/$(id -u)/de.sascha.mount-network-shares"
fi

if [ -f "$repository_dir/Brewfile" ]; then
  brew bundle --file="$repository_dir/Brewfile"
fi

# The global mise configuration is linked by install.sh above. Install every
# requested runtime now so Node.js is ready in the next shell.
if command -v mise >/dev/null 2>&1 && [ -f "$HOME/.config/mise/config.toml" ]; then
  mise install
fi

"$repository_dir/macos.sh"

hyperkey_preferences="$repository_dir/preferences/com.knollsoft.Hyperkey.plist"
if [ -f "$hyperkey_preferences" ]; then
  defaults import com.knollsoft.Hyperkey "$hyperkey_preferences"
  printf '%s\n' 'Applied Hyperkey preferences.'
fi

printf '%s\n' 'Bootstrap complete.'
