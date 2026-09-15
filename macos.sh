#!/bin/sh

# macOS preferences that should be reproducible on every new Mac.

set -eu

# Enable Tap to Click for the built-in trackpad and an external Magic Trackpad.
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Show the current charge percentage next to the battery icon in the menu bar.
# macOS 26 stores this in Control Center; the older key remains for compatibility
# with previous macOS releases.
defaults write com.apple.controlcenter BatteryShowPercentage -bool true
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Avoid Finder metadata files on shared and removable volumes. Finder still uses
# .DS_Store on local disks for folder-specific view settings.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Keyboard: short delay and fast repeat when a key such as Backspace is held.
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2

# Free Command-Space by disabling the built-in Spotlight shortcut. Raycast owns
# this shortcut after its initial setup.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '{ enabled = 0; value = { parameters = (32, 49, 1048576); type = standard; }; }'

# Hide the Spotlight search icon from the menu bar.
defaults write com.apple.Spotlight MenuItemHidden -bool true

# Hide the Tags section in Finder's sidebar without altering file tags.
defaults write com.apple.finder ShowRecentTags -bool false

# Apply changed per-user settings immediately when macOS provides this helper.
settings_activator=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
if [ -x "$settings_activator" ]; then
  "$settings_activator" -u
fi

killall SystemUIServer 2>/dev/null || true
killall Finder 2>/dev/null || true

# The Brave Launch Services handler is named "browser" by defaultbrowser.
if command -v defaultbrowser >/dev/null 2>&1; then
  defaultbrowser browser
fi

printf '%s\n' 'Applied macOS preferences.'
