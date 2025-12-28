#!/usr/bin/env bash
set -euo pipefail

REPO_HTTPS_DEFAULT="https://github.com/robscodingplace/ansible-workstation.git"
REPO_SSH_DEFAULT="git@github.com:robscodingplace/ansible-workstation.git"
TARGET_DIR_DEFAULT="$HOME/ansible-workstation"

REPO_HTTPS="${REPO_HTTPS:-$REPO_HTTPS_DEFAULT}"
REPO_SSH="${REPO_SSH:-$REPO_SSH_DEFAULT}"
TARGET_DIR="${TARGET_DIR:-$TARGET_DIR_DEFAULT}"

info() { echo "[bootstrap] $*"; }
warn() { echo "[bootstrap] WARN: $*" >&2; }

need_sudo() {
  if [[ "$(id -u)" -ne 0 ]]; then
    sudo -v
  fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_pm() {
  if has_cmd pacman; then echo "pacman"; return; fi
  if has_cmd apt-get; then echo "apt"; return; fi
  if has_cmd dnf; then echo "dnf"; return; fi
  echo "unknown"
}

install_packages() {
  local pm="$1"
  info "Detected package manager: $pm"
  need_sudo

  case "$pm" in
    pacman)
      sudo pacman -Sy --needed --noconfirm git openssh make ansible curl
      ;;
    apt)
      sudo apt-get update -y
      sudo apt-get install -y git openssh-client make ansible curl
      ;;
    dnf)
      sudo dnf install -y git openssh make ansible curl
      ;;
    *)
      warn "Unsupported package manager. Install manually: git, openssh, make, ansible, curl"
      exit 1
      ;;
  esac
}

ensure_ssh_key() {
  # Ensure ~/.ssh exists
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  local keyfile="$HOME/.ssh/id_ed25519"
  if [[ -f "$keyfile" ]]; then
    info "SSH key already exists: $keyfile"
  else
    info "Generating SSH key (ed25519)."
    # -N "" would create no passphrase (not recommended). We'll prompt if TTY.
    if [[ -t 0 ]]; then
      ssh-keygen -t ed25519 -a 64 -C "workstation-$(date +%Y-%m-%d)" -f "$keyfile"
    else
      warn "No TTY detected; generating key with empty passphrase is NOT recommended."
      warn "Re-run interactively to set a passphrase: ssh-keygen -t ed25519 -a 64"
      ssh-keygen -t ed25519 -a 64 -C "workstation-$(date +%Y-%m-%d)" -f "$keyfile" -N ""
    fi
  fi

  info "Your public key (add to GitHub → Settings → SSH and GPG keys):"
  cat "${keyfile}.pub"
  echo
}

clone_repo_https() {
  if [[ -d "$TARGET_DIR/.git" ]]; then
    info "Repo already cloned at: $TARGET_DIR"
    return
  fi

  info "Cloning repo via HTTPS (works even before SSH is configured)..."
  git clone "$REPO_HTTPS" "$TARGET_DIR"
}

switch_remote_to_ssh() {
  info "Optionally switching origin remote to SSH:"
  info "  $REPO_SSH"

  if [[ -d "$TARGET_DIR/.git" ]]; then
    (cd "$TARGET_DIR" && git remote set-url origin "$REPO_SSH")
    info "Origin remote switched to SSH."
  else
    warn "Repo not found at $TARGET_DIR; cannot switch remote."
  fi
}

next_steps() {
  cat <<EOF

[bootstrap] Next steps:

1) Add the printed SSH public key to GitHub:
   GitHub → Settings → SSH and GPG keys → New SSH key

2) Test SSH access:
   ssh -T git@github.com

3) Switch repo remote to SSH (optional):
   cd "$TARGET_DIR"
   git remote -v
   git remote set-url origin "$REPO_SSH"

4) Run your automation:
   cd "$TARGET_DIR"
   make setup   (or: make run)

EOF
}

main() {
  local pm
  pm="$(detect_pm)"
  install_packages "$pm"
  ensure_ssh_key
  next_steps
}

main "$@"
