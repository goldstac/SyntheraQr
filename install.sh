#!/usr/bin/env bash
# SyntheraQr CLI installer — https://syntheraqr.netlify.app/install
# Usage:  curl -fsSL https://syntheraqr.netlify.app/install | bash
set -euo pipefail

REPO="goldstac/synthera-qr-cli"
VERSION="${1:-latest}"

if [ "$VERSION" = "latest" ]; then
  URL_BASE="https://github.com/${REPO}/releases/latest/download"
else
  URL_BASE="https://github.com/${REPO}/releases/download/${VERSION}"
fi

case "$(uname -s)" in
  Linux) OS_NAME="linux" ;;
  Darwin) OS_NAME="macos" ;;
  *) echo "error: unsupported OS ($(uname -s)); supported: Linux, macOS" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  x86_64|amd64) ARCH_NAME="x86_64" ;;
  aarch64|arm64) ARCH_NAME="aarch64" ;;
  *) echo "error: unsupported architecture ($(uname -m))" >&2; exit 1 ;;
esac

BIN="syntheraqr-${OS_NAME}-${ARCH_NAME}"
DEST="${SYNTHERAQR_DEST:-$HOME/.local/bin}"

install_binary() {
  local tmp url
  tmp="$(mktemp -d)"
  url="${URL_BASE}/${BIN}"
  echo "Downloading ${url}"
  if curl -fsSL "$url" -o "$tmp/syntheraqr"; then
    chmod +x "$tmp/syntheraqr"
    if ! "$tmp/syntheraqr" --version >/dev/null 2>&1; then
      echo "warning: downloaded binary failed to run; falling back to source build"
      rm -rf "$tmp"
      return 1
    fi
    mkdir -p "$DEST"
    install -m 755 "$tmp/syntheraqr" "$DEST/syntheraqr"
    rm -rf "$tmp"
    return 0
  fi
  echo "no prebuilt binary for ${OS_NAME}-${ARCH_NAME}; building from source"
  rm -rf "$tmp"
  return 1
}

build_from_source() {
  if ! command -v cargo >/dev/null 2>&1; then
    echo "error: no prebuilt binary for ${OS_NAME}-${ARCH_NAME} and cargo is not installed" >&2
    echo "install Rust from https://rustup.rs and re-run, or download a binary from" >&2
    echo "https://github.com/${REPO}/releases" >&2
    exit 1
  fi
  local tmp
  tmp="$(mktemp -d)"
  echo "Cloning ${REPO}..."
  git clone --depth 1 "https://github.com/${REPO}.git" "$tmp/syntheraqr"
  (cd "$tmp/syntheraqr" && cargo build --release)
  mkdir -p "$DEST"
  install -m 755 "$tmp/syntheraqr/target/release/syntheraqr" "$DEST/syntheraqr"
  rm -rf "$tmp"
}

if ! install_binary; then
  build_from_source
fi

echo "Installed syntheraqr to ${DEST}/syntheraqr"
if ! printf ':%s:' "$PATH" | grep -q ":${DEST}:"; then
  echo "Note: ${DEST} is not in your PATH. Add it with:"
  echo "  export PATH=\"${DEST}:\$PATH\""
  echo "(append that line to your ~/.bashrc or ~/.zshrc)"
fi
echo "Run 'syntheraqr --help' to get started."