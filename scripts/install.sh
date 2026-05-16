#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

default_prefix() {
    for prefix in /opt/homebrew /usr/local; do
        bin_dir="$prefix/bin"
        case ":$PATH:" in
            *":$bin_dir:"*)
                if [ -d "$bin_dir" ] && [ -w "$bin_dir" ]; then
                    printf '%s\n' "$prefix"
                    return
                fi
                ;;
        esac
    done

    printf '%s\n' "$HOME/.local"
}

PREFIX="${PREFIX:-$(default_prefix)}"
BIN_DIR="$PREFIX/bin"
TARGET="$BIN_DIR/togglenotch"

cd "$REPO_ROOT"

echo "Building togglenotch release binary..."
swift build -c release

mkdir -p "$BIN_DIR"
install -m 755 "$REPO_ROOT/.build/release/togglenotch" "$TARGET"

echo "Installed togglenotch to: $TARGET"
echo "Verify with: $TARGET status"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo "Warning: $BIN_DIR is not in PATH."
        echo "Add this to your shell profile:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac
