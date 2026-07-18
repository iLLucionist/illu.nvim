--[[
sidepanes_audit_smoke
Purpose: Exercise the real personal init.lua Sidepanes surface after setup.
Does: Verifies configured commands, forbidden legacy commands, global mappings, presets, and health output.
Architecture: Complements the focused regression suite with a full-config smoke test that catches wiring regressions.
]]

vim.opt.runtimepath:append("/Users/maximl/.config/nvim/illu.nvim")

local sidepanes = require("sidepanes")

local function assert_command(name)
    assert(vim.api.nvim_get_commands({})[name], "missing command: " .. name)
end

local function assert_no_command(name)
    assert(not vim.api.nvim_get_commands({})[name], "unexpected command: " .. name)
end

local function assert_global_map(mode, lhs)
    local map = vim.fn.maparg(lhs, mode, false, true)

    assert(map and map.lhs and map.lhs ~= "", "missing global map " .. lhs .. " in " .. mode)
    assert(map.callback, "global map has no callback " .. lhs .. " in " .. mode)
end

local function capture_health(fn)
    local original = vim.health
    local reports = {}

    vim.health = {
        start = function(message)
            table.insert(reports, { level = "start", message = message })
        end,
        ok = function(message)
            table.insert(reports, { level = "ok", message = message })
        end,
        warn = function(message)
            table.insert(reports, { level = "warn", message = message })
        end,
        error = function(message)
            table.insert(reports, { level = "error", message = message })
        end,
        info = function(message)
            table.insert(reports, { level = "info", message = message })
        end,
    }

    local ok, err = pcall(fn, reports)

    vim.health = original

    if not ok then
        error(err)
    end

    return reports
end

local function has_report(reports, level, needle)
    for _, report in ipairs(reports) do
        if report.level == level and report.message:find(needle, 1, true) then
            return true
        end
    end

    return false
end

local expected_commands = {
    "Sidepanes",
    "SidepanesToggle",
    "SidepanesPick",
    "SidepanesHeadings",
    "SidepanesSwitch",
    "SidepanesTool",
    "SidepanesCodex",
    "SidepanesClaude",
    "SidepanesIPython",
    "SidepanesIPythonRestart",
    "SidepanesIPythonClear",
    "SidepanesFocus",
    "SidepanesZoom",
    "SidepanesWidth",
    "SidepanesAsk",
    "SidepanesAskCodex",
    "SidepanesAskClaude",
    "MarkdownReflow",
}

local forbidden_commands = {
    "PaneSwitch",
    "PaneTool",
    "PaneCodex",
    "PaneClaude",
    "PaneIPython",
    "PaneIPythonRestart",
    "PaneIPythonClear",
    "PaneFocus",
    "PaneZoom",
    "PaneAsk",
    "PaneAskCodex",
    "PaneAskClaude",
}

local expected_maps = {
    { "n", "<leader>fm" },
    { "n", "<leader>mR" },
    { "n", "<leader>pp" },
    { "n", "<leader>mP" },
    { "n", "<leader>p0" },
    { "n", "<leader>px" },
    { "n", "<leader>pc" },
    { "n", "<leader>pi" },
    { "n", "<leader>pR" },
    { "n", "<leader>pl" },
    { "x", "<leader>pl" },
    { "n", "<leader>pX" },
    { "n", "<leader>pf" },
    { "n", "<leader>pz" },
    { "n", "<leader>ps" },
    { "x", "<leader>pa" },
    { "x", "aa" },
    { "x", "ax" },
    { "x", "ac" },
}

for _, name in ipairs(expected_commands) do
    assert_command(name)
end

for _, name in ipairs(forbidden_commands) do
    assert_no_command(name)
end

for _, item in ipairs(expected_maps) do
    assert_global_map(item[1], item[2])
end

local pane_config = sidepanes.get_config()

assert(pane_config.width == 100, "configured pane width changed")
assert(pane_config.zoom_text_width == 90, "configured zoom text width changed")
assert(pane_config.sticky_relative_width == false, "configured sticky relative width changed")
assert(pane_config.external_reflow_cmd[1] == "mdfmt", "configured external reflow command changed")
assert(#pane_config.tools.codex.presets == 12, "configured Codex preset count changed")
assert(pane_config.tools.codex.presets[1].name == "gpt55_high_fast", "configured Codex default changed")
assert(#pane_config.tools.claude.presets == 5, "configured Claude preset count changed")
assert(pane_config.tools.claude.presets[1].name == "sonnet", "configured Claude default changed")
assert(pane_config.tools.ipython.exit_command == "quit()\r", "configured IPython exit command changed")

local reports = capture_health(function()
    require("sidepanes.health").check({ config = pane_config })
end)

for _, report in ipairs(reports) do
    assert(report.level ~= "error", "health error: " .. report.message)
    assert(report.level ~= "warn", "health warning: " .. report.message)
end

assert(has_report(reports, "ok", "sidepanes.nvim loaded"), "health did not report sidepanes loaded")
assert(has_report(reports, "ok", "Codex presets configured: 12"), "health did not report Codex presets")
assert(has_report(reports, "ok", "Command registered: :SidepanesSwitch"), "health did not report SidepanesSwitch")
assert(has_report(reports, "ok", "Global mapping registered: <leader>pp"), "health did not report global mappings")

print("sidepanes audit smoke passed")
