#!/bin/sh

# Link every regular file from home/ into $HOME, preserving existing files in a
# timestamped backup directory. POSIX sh keeps this usable on a clean macOS.

set -eu

repository_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_dir="$repository_dir/home"
dry_run=false
backup_dir=""

usage() {
  printf '%s\n' "Usage: ./install.sh [--dry-run]"
}

case "${1:-}" in
  "") ;;
  --dry-run) dry_run=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 1 ;;
esac

if [ ! -d "$source_dir" ]; then
  printf 'Missing source directory: %s\n' "$source_dir" >&2
  exit 1
fi

ensure_backup_dir() {
  if [ -z "$backup_dir" ]; then
    backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
    if "$dry_run"; then
      printf 'Would create backup directory %s\n' "$backup_dir"
    else
      mkdir -p "$backup_dir"
      printf 'Backup directory: %s\n' "$backup_dir"
    fi
  fi
}

link_file() {
  source_file=$1
  relative_path=${source_file#"$source_dir"/}
  target_file="$HOME/$relative_path"
  target_parent=$(dirname "$target_file")

  # launchd refuses symlinked plists and cannot follow an executable symlink
  # into a TCC-protected Documents folder. Install launchd-owned files as
  # real files instead.
  case "$relative_path" in
    Library/LaunchAgents/*.plist|.local/bin/mount-network-shares)
      if [ -f "$target_file" ] && [ ! -L "$target_file" ] && cmp -s "$source_file" "$target_file"; then
        printf 'Unchanged: %s\n' "$target_file"
        return
      fi

      if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
        if "$dry_run"; then
          printf 'Would replace managed symlink with file: %s\n' "$target_file"
        else
          rm "$target_file"
          cp "$source_file" "$target_file"
          printf 'Installed: %s\n' "$target_file"
        fi
        return
      fi

      if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        ensure_backup_dir
        backup_file="$backup_dir/$relative_path"
        if "$dry_run"; then
          printf 'Would back up %s to %s\n' "$target_file" "$backup_file"
        else
          mkdir -p "$(dirname "$backup_file")"
          mv "$target_file" "$backup_file"
          printf 'Backed up: %s\n' "$target_file"
        fi
      fi

      if "$dry_run"; then
        printf 'Would install %s from %s\n' "$target_file" "$source_file"
      else
        mkdir -p "$target_parent"
        cp "$source_file" "$target_file"
        printf 'Installed: %s\n' "$target_file"
      fi
      return
      ;;
  esac

  if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
    printf 'Unchanged: %s\n' "$target_file"
    return
  fi

  if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    ensure_backup_dir
    backup_file="$backup_dir/$relative_path"
    if "$dry_run"; then
      printf 'Would back up %s to %s\n' "$target_file" "$backup_file"
    else
      mkdir -p "$(dirname "$backup_file")"
      mv "$target_file" "$backup_file"
      printf 'Backed up: %s\n' "$target_file"
    fi
  fi

  if "$dry_run"; then
    printf 'Would link %s -> %s\n' "$target_file" "$source_file"
  else
    mkdir -p "$target_parent"
    ln -s "$source_file" "$target_file"
    printf 'Linked: %s -> %s\n' "$target_file" "$source_file"
  fi
}

find "$source_dir" -type f ! -name '.gitkeep' -print |
  while IFS= read -r source_file; do
    link_file "$source_file"
  done

printf '%s\n' 'Done.'
