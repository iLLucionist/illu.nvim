#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PLUGIN_DIR="${SIDEPANES_RUNTIME_PATH:-${HOME}/.local/share/nvim/lazy/sidepanes.nvim}"
TMP_ROOT="${TMPDIR:-/tmp}"
TMP_ROOT="${TMP_ROOT%/}"

if [ ! -d "$PLUGIN_DIR/lua/sidepanes" ]; then
    PLUGIN_DIR="$ROOT_DIR"
fi

printf 'sidepanes runtime: %s\n' "$PLUGIN_DIR"

run_nvim() {
    name="$1"
    shift

    XDG_CACHE_HOME="${TMP_ROOT}/illu-nvim-cache-${name}" \
        XDG_STATE_HOME="${TMP_ROOT}/illu-nvim-state-${name}" \
        SIDEPANES_RUNTIME_PATH="$PLUGIN_DIR" \
        nvim --headless "$@"
}

run_nvim sidepanes-regression \
    -u NONE \
    -c "luafile $ROOT_DIR/tests/sidepanes_regression.lua" \
    -c 'qa!'

run_nvim sidepanes-audit-smoke \
    -u "$ROOT_DIR/init.lua" \
    -c "luafile $ROOT_DIR/tests/sidepanes_audit_smoke.lua" \
    -c 'qa!'

run_nvim sidepanes-checkhealth-smoke \
    -u "$ROOT_DIR/init.lua" \
    -c "luafile $ROOT_DIR/tests/sidepanes_checkhealth_smoke.lua" \
    -c 'qa!'

run_nvim sidepanes-real-cli-smoke \
    -u NONE \
    -c "luafile $ROOT_DIR/tests/sidepanes_real_cli_smoke.lua" \
    -c 'qa!'

printf '%s\n' 'sidepanes checks passed'
