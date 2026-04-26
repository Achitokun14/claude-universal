#!/usr/bin/env bash
# lib/deps.sh — install bundle-runtime prereqs (jq, python3, curl, git, node).
# Never auto-installs the AI CLIs themselves — those are user choices.

# Map bundle-required tools → per-OS package names
deps_pkg_name() {
  local tool="$1"
  case "$PKG:$tool" in
    apt:jq|dnf:jq|pacman:jq|zypper:jq|apk:jq|brew:jq) echo jq ;;
    apt:python3|dnf:python3|zypper:python3) echo python3 ;;
    pacman:python3) echo python ;;
    apk:python3) echo python3 ;;
    brew:python3) echo python@3.12 ;;
    apt:nodejs|dnf:nodejs|zypper:nodejs) echo nodejs ;;
    pacman:nodejs) echo nodejs ;;
    apk:nodejs) echo nodejs ;;
    brew:nodejs) echo node ;;
    apt:curl|dnf:curl|pacman:curl|zypper:curl|apk:curl|brew:curl) echo curl ;;
    apt:git|dnf:git|pacman:git|zypper:git|apk:git|brew:git) echo git ;;
    *) echo "$tool" ;;
  esac
}

deps_install_cmd() {
  local pkgs="$*"
  case "$PKG" in
    apt)    echo "sudo apt-get update -qq && sudo apt-get install -y $pkgs" ;;
    dnf)    echo "sudo dnf install -y $pkgs" ;;
    pacman) echo "sudo pacman -Sy --needed --noconfirm $pkgs" ;;
    zypper) echo "sudo zypper install -y $pkgs" ;;
    apk)    echo "sudo apk add --no-cache $pkgs" ;;
    brew)   echo "brew install $pkgs" ;;
    none)   echo "" ;;
  esac
}

# Compute and install missing prereqs. Honors $SETUP_DRY.
deps_install_missing() {
  local missing=()
  [[ "$HAVE_JQ"   = no ]] && missing+=("$(deps_pkg_name jq)")
  [[ "$HAVE_PY"   = no ]] && missing+=("$(deps_pkg_name python3)")
  [[ "$HAVE_CURL" = no ]] && missing+=("$(deps_pkg_name curl)")
  [[ "$HAVE_GIT"  = no ]] && missing+=("$(deps_pkg_name git)")
  [[ "$HAVE_NODE" = no ]] && missing+=("$(deps_pkg_name nodejs)")

  if [[ ${#missing[@]} -eq 0 ]]; then
    ok "all bundle prereqs present (jq, python3, curl, git, node)"
    return 0
  fi

  if [[ "$PKG" = none ]]; then
    err "no package manager detected. Install manually: ${missing[*]}"
    return 1
  fi

  local cmd
  cmd="$(deps_install_cmd "${missing[@]}")"
  say "missing prereqs: ${missing[*]}"
  hint "will run: $cmd"
  if confirm "  install missing prereqs?"; then
    run "$cmd"
  else
    warn "skipping prereq install — bundle may fail on later steps"
  fi
}
