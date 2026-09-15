#!/bin/sh
# Explicit opt-in: enables incoming SSH. Run as the intended login user.
set -eu
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH
repository_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
login_user=${1:-${SUDO_USER:-$(id -un)}}
case "$login_user" in ''|root|*[!a-zA-Z0-9_-]*) echo 'Invalid login user' >&2; exit 1;; esac
if [ "$(id -u)" -ne 0 ]; then
  exec sudo /bin/sh "$0" "$login_user"
fi
login_home=$(dscl . -read "/Users/$login_user" NFSHomeDirectory | sed 's/^NFSHomeDirectory: //')
login_group=$(id -gn "$login_user")
[ -d "$login_home" ]
key="$repository_dir/ssh/homelab.pub"
expected='SHA256:DtD2i2zUTf5xmvTp2KxZpNbDuA4gfrmUy52f7AQOslA'
[ "$(awk 'NF {n++} END {print n}' "$key")" = 1 ]
[ "$(ssh-keygen -lf "$key" | awk '{print $2}')" = "$expected" ] || {
  echo 'Homelab public-key fingerprint mismatch; no changes applied.' >&2; exit 1;
}
backup=$(mktemp -d /var/backups/dotfiles-ssh.XXXXXXXX)
chmod 700 "$backup"
cp -p /etc/ssh/sshd_config "$backup/sshd_config"
cp -Rp /etc/ssh/sshd_config.d "$backup/sshd_config.d"
launchctl print-disabled system > "$backup/launchd-before.txt"
systemsetup -getremotelogin > "$backup/remote-login-before.txt" 2>&1 || true
dscl . -read /Groups/com.apple.access_ssh > "$backup/access-ssh-before.txt" 2>&1 || true
for name in authorized_keys homelab.pub; do
  if [ -e "$login_home/.ssh/$name" ] || [ -L "$login_home/.ssh/$name" ]; then
    cp -pP "$login_home/.ssh/$name" "$backup/$name"
    cp -pL "$login_home/.ssh/$name" "$backup/$name.contents"
  else
    touch "$backup/$name.absent"
  fi
done
echo "Backup: $backup"
# Real files: sshd must not depend on symlinks into protected Documents.
[ ! -L "$login_home/.ssh" ] || { echo 'Refusing symlinked .ssh' >&2; exit 1; }
mkdir -p "$login_home/.ssh"
chown "$login_user:$login_group" "$login_home/.ssh"
chmod 700 "$login_home/.ssh"
for name in homelab.pub authorized_keys; do
  temp_key=$(mktemp "$login_home/.ssh/.homelab.XXXXXXXX")
  cat "$key" > "$temp_key"
  chown "$login_user:$login_group" "$temp_key"
  chmod 600 "$temp_key"
  mv -f "$temp_key" "$login_home/.ssh/$name"
done
[ "$(ssh-keygen -lf "$login_home/.ssh/authorized_keys" | awk '{print $2}')" = "$expected" ]
# Generate missing server host keys locally; never copy client private keys.
ssh-keygen -A
target=/etc/ssh/sshd_config.d/000-homelab.conf
candidate="$backup/candidate.conf"
sed "s/@USER@/$login_user/g" "$repository_dir/ssh/000-homelab.conf" > "$candidate"
sshd -t -f "$candidate"
install -o root -g wheel -m 644 "$candidate" "$target"
rollback_config() {
  if [ -f "$backup/sshd_config.d/000-homelab.conf" ]; then
    cp -p "$backup/sshd_config.d/000-homelab.conf" "$target"
  else
    rm -f "$target"
  fi
}
if ! sshd -t; then rollback_config; exit 1; fi
if ! sshd -T -C "user=$login_user,host=localhost,addr=127.0.0.1" > "$backup/effective-after.txt"; then
  rollback_config; exit 1
fi
for setting in 'pubkeyauthentication yes' 'authenticationmethods publickey' \
  'passwordauthentication no' 'kbdinteractiveauthentication no' \
  'permitrootlogin no' "allowusers $login_user" \
  'authorizedkeysfile .ssh/authorized_keys' 'authorizedkeyscommand none' \
  'trustedusercakeys none'; do
  if ! grep -qxF "$setting" "$backup/effective-after.txt"; then
    echo "Unexpected effective setting: $setting; configuration restored." >&2
    rollback_config; exit 1
  fi
done
# Preserve the existing macOS SSH access group, adding this user if needed.
if dscl . -read /Groups/com.apple.access_ssh >/dev/null 2>&1; then
  dseditgroup -o edit -a "$login_user" -t user com.apple.access_ssh
fi
# systemsetup may require Full Disk Access. launchctl enables the same Apple
# service persistently when that API is unavailable; no custom daemon needed.
systemsetup -setremotelogin on || true
if ! launchctl print system/com.openssh.sshd >/dev/null 2>&1; then
  launchctl load -w /System/Library/LaunchDaemons/ssh.plist
fi
launchctl print system/com.openssh.sshd >/dev/null
sshd -t
echo "SSH enabled for $login_user; homelab public key only."
echo "Backup: $backup"
