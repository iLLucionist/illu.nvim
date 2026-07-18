#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

run_nvim() {
    name="$1"
    shift

    XDG_CACHE_HOME="/private/tmp/illu-nvim-cache-${name}" \
        XDG_STATE_HOME="/private/tmp/illu-nvim-state-${name}" \
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
