--[[
sidepanes_integration_smoke
Purpose: Verify illu.nvim consumes the configured sidepanes.nvim runtime.
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

local function expanded_leader(lhs)
    local leader = vim.g.mapleader or "\\"

    return lhs:gsub("<leader>", leader)
end

local function find_buf_map(bufnr, mode, lhs)
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
        if map.lhs == lhs then
            return map
        end
    end

    return nil
end

local function call_buf_map(bufnr, mode, lhs)
    local map = find_buf_map(bufnr, mode, lhs)

    assert(map and map.callback, "missing buffer map " .. lhs .. " in " .. mode)
    map.callback()
end

local function capture_notify(fn)
    local original = vim.notify
    local messages = {}

    vim.notify = function(message, level, opts)
        table.insert(messages, tostring(message))
        return original(message, level, opts)
    end

    local ok, err = pcall(fn)

    vim.notify = original

    if not ok then
        error(err)
    end

    return table.concat(messages, "\n")
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
assert_command("SidepanesSubmitQuestion")
assert_command("SidepanesIPython")
assert_command("MarkdownReflow")

assert_global_map("n", "<leader>pp")
assert_global_map("n", "<leader>qq")
assert_global_map("n", "<leader>mR")
assert_global_map("n", "<leader>pa")
assert_global_map("x", "<leader>pa")
assert_global_map("x", "<leader>pl")

local config = sidepanes.get_config()

assert(config.width == 100, "personal Sidepanes width config changed")
assert(config.external_reflow_cmd[1] == "mdfmt", "personal Markdown reflow command changed")
assert(config.ask and config.ask.ui == "pane", "personal Sidepanes ask pane opt-in changed")
assert(config.ask.auto_append == true, "personal Sidepanes ask auto_append config changed")
assert(config.ask.model_picker == "before_send", "personal Sidepanes ask model picker timing changed")
assert(config.mappings.pane.headings == "fm", "personal Sidepanes pane heading picker mapping changed")
assert(config.mappings.pane.ask_submit == "<C-CR>", "personal Sidepanes ask submit mapping changed")
assert(config.mappings.pane.ask_send == "qq", "personal Sidepanes ask send mapping changed")
assert(config.mappings.pane.ask_send_alt == "<leader>qq", "personal Sidepanes ask send alt mapping changed")
assert(config.mappings.pane.ask_model_picker == "M", "personal Sidepanes ask model picker mapping changed")
assert(config.mappings.pane.ask_model_picker_alt == "<Tab>", "personal Sidepanes ask model picker alt mapping changed")
assert(#config.tools.codex.presets == 12, "personal Codex preset count changed")
assert(#config.tools.claude.presets == 5, "personal Claude preset count changed")

vim.cmd("silent help sidepanes")

local help_path = normalize(vim.api.nvim_buf_get_name(0))
local expected_help = normalize(expected_root .. "/doc/sidepanes.txt")

assert(help_path == expected_help, ("sidepanes help opened %s, expected %s"):format(help_path, expected_help))

assert_no_sidepanes_health_warnings()

local root = vim.fn.tempname()

vim.fn.mkdir(root .. "/.git", "p")
vim.fn.mkdir(root .. "/docs", "p")
vim.fn.mkdir(root .. "/src", "p")
vim.fn.writefile({ "# Doc" }, root .. "/docs/doc.md")
vim.fn.writefile({ "selected()" }, root .. "/src/origin.lua")

sidepanes.setup({
    commands = true,
    ask = {
        ui = "pane",
        auto_append = true,
        model_picker = "manual",
    },
    mappings = {
        pane = {
            ask_send = "qq",
            ask_send_alt = "<leader>qq",
        },
    },
    tools = {
        codex = {
            label = "Codex",
            cmd = { "sh", "-c", "sleep 10" },
            send_delay_ms = 0,
            presets = {
                { name = "one", label = "One", args = {} },
            },
        },
        claude = false,
        ipython = false,
    },
})

local function open_ask_draft()
    vim.cmd.edit(root .. "/src/origin.lua")
    sidepanes.ask("codex", "one", {
        bufnr = vim.api.nvim_get_current_buf(),
        line1 = 1,
        line2 = 1,
    })

    return sidepanes._state().ask_pane.bufnr
end

sidepanes.open(root .. "/docs/doc.md")
local ask_bufnr = open_ask_draft()

local state = sidepanes._state()
local alt_lhs = expanded_leader("<leader>qq")

assert(find_buf_map(ask_bufnr, "n", "qq"), "personal ask pane qq send map missing")
assert(find_buf_map(ask_bufnr, "n", alt_lhs), "personal ask pane <leader>qq send map missing")

local messages = capture_notify(function()
    call_buf_map(ask_bufnr, "n", "qq")
end)

assert(not messages:find("Write the ask prompt before sending", 1, true), "ask pane qq warned instead of quitting")
assert(sidepanes._state().ask_pane.bufnr == ask_bufnr, "ask pane qq did not preserve modified unwritten draft")
assert(sidepanes._state().active_mode == "markdown", "ask pane qq did not restore previous pane")
require("sidepanes.internal").cancel_ask_pane(ask_bufnr)

ask_bufnr = open_ask_draft()
messages = capture_notify(function()
    call_buf_map(ask_bufnr, "n", alt_lhs)
end)

assert(not messages:find("Write the ask prompt before sending", 1, true), "ask pane <leader>qq warned instead of quitting")
assert(sidepanes._state().ask_pane.bufnr == ask_bufnr, "ask pane <leader>qq did not preserve modified unwritten draft")
assert(sidepanes._state().active_mode == "markdown", "ask pane <leader>qq did not restore previous pane")
require("sidepanes.internal").cancel_ask_pane(ask_bufnr)

ask_bufnr = open_ask_draft()
sidepanes.open_terminal("codex", "one", { root = root, focus = true })
state = sidepanes._state()

local codex_bufnr = vim.api.nvim_win_get_buf(state.winid)

assert(find_buf_map(codex_bufnr, "n", alt_lhs), "Codex pane should guard personal normal <leader>qq")
assert(not find_buf_map(codex_bufnr, "t", alt_lhs), "Codex pane should not own personal terminal-input <leader>qq")
vim.api.nvim_set_current_win(state.winid)
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(alt_lhs, true, false, true), "mx", false)

assert(vim.wait(500, function()
    return sidepanes._state().active_mode == "markdown"
end, 10), "Codex pane personal <leader>qq guard did not return to Markdown")

sidepanes.open_terminal("codex", "one", { root = root, focus = true })
state = sidepanes._state()
codex_bufnr = vim.api.nvim_win_get_buf(state.winid)

messages = capture_notify(function()
    local original_getcmdline = vim.fn.getcmdline
    local original_getcmdtype = vim.fn.getcmdtype
    local enter_map = vim.fn.maparg("<CR>", "c", false, true)

    assert(enter_map.callback, "Sidepanes command-line enter map has no callback")

    vim.fn.getcmdtype = function()
        return ":"
    end
    vim.fn.getcmdline = function()
        return "q"
    end

    local ok, err = pcall(function()
        local mapped = enter_map.callback()

        assert(mapped:find('require%("sidepanes%.internal"%)%.show_markdown', 1, false), mapped)
    end)

    vim.fn.getcmdline = original_getcmdline
    vim.fn.getcmdtype = original_getcmdtype

    if not ok then
        error(err)
    end
end)

assert(not messages:find("Write the ask prompt before sending", 1, true), "Codex pane :q command path triggered ask send")
sidepanes.show_markdown()
assert(sidepanes._state().active_mode == "markdown", "Codex pane :q command path did not return to Markdown")

print("sidepanes integration smoke passed")
