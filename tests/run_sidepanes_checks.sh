#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DEFAULT_PLUGIN_DIR="${HOME}/.local/share/nvim/lazy/sidepanes.nvim"
PLUGIN_DIR="${ILLU_SIDEPANES_RUNTIME_PATH:-${DEFAULT_PLUGIN_DIR}}"
TMP_ROOT="${TMPDIR:-/tmp}"
TMP_ROOT="${TMP_ROOT%/}"

if [ ! -d "$PLUGIN_DIR/lua/sidepanes" ]; then
    printf 'missing installed sidepanes.nvim runtime: %s\n' "$PLUGIN_DIR" >&2
    printf 'run :Lazy sync sidepanes.nvim from Neovim, then retry\n' >&2
    exit 1
fi

printf 'sidepanes runtime: %s\n' "$PLUGIN_DIR"

run_nvim() {
    name="$1"
    shift

    XDG_CACHE_HOME="${TMP_ROOT}/illu-nvim-cache-${name}" \
        XDG_STATE_HOME="${TMP_ROOT}/illu-nvim-state-${name}" \
        SIDEPANES_EXPECTED_RUNTIME_PATH="$PLUGIN_DIR" \
        nvim --headless "$@"
}

run_nvim sidepanes-integration-smoke \
    -u "$ROOT_DIR/init.lua" \
    -c "luafile $ROOT_DIR/tests/sidepanes_integration_smoke.lua" \
    -c 'qa!'
