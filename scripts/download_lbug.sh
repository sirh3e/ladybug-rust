#!/bin/sh
# Download prebuilt static liblbug into the Rust crate cache.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${1:-$PROJECT_DIR/.cache/lbug-prebuilt.env}"
CACHE_LIB_DIR="${LBUG_TARGET_DIR:-$PROJECT_DIR/.cache/lbug-prebuilt/lib}"
LIB_KIND="${LBUG_LIB_KIND:-static}"
UPSTREAM_SCRIPT="$SCRIPT_DIR/download-liblbug.sh"

# download-liblbug.sh ships beside this one, so a missing one is a broken checkout, not
# something to repair over the network: this used to curl it from the engine's `main`
# branch -- an unpinned, unverified script that it then ran with bash.
if [ ! -f "$UPSTREAM_SCRIPT" ]; then
  echo "Missing $UPSTREAM_SCRIPT; this checkout of the crate is incomplete" >&2
  exit 1
fi

LBUG_TARGET_DIR="$CACHE_LIB_DIR" LBUG_LIB_KIND="$LIB_KIND" bash "$UPSTREAM_SCRIPT"

OS="$(uname -s)"
if [ "$LIB_KIND" = "shared" ]; then
  case "$OS" in
    Darwin)
      LIB_PATH="$CACHE_LIB_DIR/liblbug.dylib"
      ;;
    Linux)
      LIB_PATH="$CACHE_LIB_DIR/liblbug.so"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      LIB_PATH="$CACHE_LIB_DIR/lbug_shared.dll"
      ;;
    *)
      echo "Unsupported OS: $OS" >&2
      exit 1
      ;;
  esac
else
  case "$OS" in
    MINGW*|MSYS*|CYGWIN*)
      LIB_PATH="$CACHE_LIB_DIR/lbug.lib"
      ;;
    *)
      LIB_PATH="$CACHE_LIB_DIR/liblbug.a"
      ;;
  esac
fi

if [ ! -f "$LIB_PATH" ]; then
  echo "Expected precompiled library not found at $LIB_PATH" >&2
  exit 1
fi

mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" <<EOF
LBUG_LIBRARY_DIR=$CACHE_LIB_DIR
LBUG_INCLUDE_DIR=$CACHE_LIB_DIR
EOF

echo "Wrote $ENV_FILE"
echo "Resolved precompiled library: $LIB_PATH"
