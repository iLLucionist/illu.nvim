--[[
sidepanes_integration_smoke
Purpose: Verify illu.nvim consumes the pinned GitHub-installed sidepanes.nvim plugin.
Does: Checks the loaded module path, a few personal commands and mappings, help resolution, and Sidepanes health.
Architecture: Keeps plugin behavior coverage in sidepanes.nvim and tests only this config's lazy.nvim integration boundary.
]]

local expected_root = vim.env.SIDEPANES_EXPECTED_RUNTIME_PATH

assert(expected_root and expected_root ~= "", "SIDEPANES_EXPECTED_RUNTIME_PATH is required")

expected_root = vim.fs.normalize(expected_root)

local function normalize(path)
    return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function assert_command(name)
    assert(vim.api.nvim_get_commands({})[name], "missing command: " .. name)
end

local function assert_global_map(mode, lhs)
    local map = vim.fn.maparg(lhs, mode, false, true)

    assert(map and map.lhs and map.lhs ~= "", "missing global map " .. lhs .. " in " .. mode)
end

local function assert_no_sidepanes_health_warnings()
    vim.cmd("silent checkhealth sidepanes")

    local report = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

    assert(report:find("sidepanes.nvim loaded", 1, true), "health did not load sidepanes:\n" .. report)
    assert(
        report:find("built-in sidepanes.markdown_reflow module found", 1, true),
        "health did not find built-in markdown_reflow:\n" .. report
    )
    assert(not report:find("ERROR", 1, true), "health reported an error:\n" .. report)
    assert(not report:find("WARNING", 1, true), "health reported a warning:\n" .. report)
end

local sidepanes = require("sidepanes")
local setup_source = debug.getinfo(sidepanes.setup, "S").source:gsub("^@", "")
local loaded_path = normalize(setup_source)
local expected_init = normalize(expected_root .. "/lua/sidepanes/init.lua")

assert(loaded_path == expected_init, ("sidepanes loaded from %s, expected %s"):format(loaded_path, expected_init))
assert(not vim.loop.fs_stat(vim.fn.stdpath("config") .. "/lua/sidepanes"), "local lua/sidepanes fallback still exists")

assert_command("Sidepanes")
assert_command("SidepanesAsk")
assert_command("SidepanesIPython")
assert_command("MarkdownReflow")

assert_global_map("n", "<leader>pp")
assert_global_map("n", "<leader>mR")
assert_global_map("x", "<leader>pa")
assert_global_map("x", "<leader>pl")

local config = sidepanes.get_config()

assert(config.width == 100, "personal Sidepanes width config changed")
assert(config.external_reflow_cmd[1] == "mdfmt", "personal Markdown reflow command changed")
assert(#config.tools.codex.presets == 12, "personal Codex preset count changed")
assert(#config.tools.claude.presets == 5, "personal Claude preset count changed")

vim.cmd("silent help sidepanes")

local help_path = normalize(vim.api.nvim_buf_get_name(0))
local expected_help = normalize(expected_root .. "/doc/sidepanes.txt")

assert(help_path == expected_help, ("sidepanes help opened %s, expected %s"):format(help_path, expected_help))

assert_no_sidepanes_health_warnings()

print("sidepanes integration smoke passed")
