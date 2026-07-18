--[[
sidepanes.commands
Purpose: Register user commands that expose the sidepanes public API.
Does: Creates Sidepanes-prefixed commands for switching, asking, focusing, zooming, and controlling Codex, Claude, and IPython panes.
Architecture: Keeps command registration out of init.lua while receiving the facade table as its API surface.
]]

local M = {}

local default_names = {
    toggle = "SidepanesToggle",
    pick = "SidepanesPick",
    headings = "SidepanesHeadings",
    switch = "SidepanesSwitch",
    tool = "SidepanesTool",
    codex = "SidepanesCodex",
    claude = "SidepanesClaude",
    ipython = "SidepanesIPython",
    ipython_restart = "SidepanesIPythonRestart",
    ipython_clear = "SidepanesIPythonClear",
    focus = "SidepanesFocus",
    zoom = "SidepanesZoom",
    ask = "SidepanesAsk",
    ask_codex = "SidepanesAskCodex",
    ask_claude = "SidepanesAskClaude",
}

--- Register a user command unless its configured name is disabled.
local function command(name, callback, opts)
    if not name then
        return
    end

    opts = opts or {}
    opts.force = true
    vim.api.nvim_create_user_command(name, callback, opts)
end

--- Return command names from a boolean or table setup value.
local function command_names(config)
    if not config then
        return nil
    end

    if config == true then
        return default_names
    end

    if type(config) ~= "table" then
        return nil
    end

    return vim.tbl_deep_extend("force", default_names, config)
end

--- Build current-buffer range options for ask commands.
local function range_opts(opts)
    return {
        bufnr = vim.api.nvim_get_current_buf(),
        line1 = opts.line1,
        line2 = opts.line2,
    }
end

--- Register configured sidepanes user commands.
function M.setup(api, config)
    local names = command_names(config)

    if not names then
        return
    end

    command(names.toggle, function(opts)
        api.toggle(opts.args)
    end, { nargs = "?", complete = "file" })

    command(names.pick, function()
        api.pick()
    end, {})

    command(names.headings, function()
        api.pick_headings()
    end, {})

    command(names.switch, function()
        api.switch_picker()
    end, {})

    command(names.tool, function(opts)
        local parts = vim.split(opts.args or "", "%s+", { trimempty = true })

        if not parts[1] then
            api.switch_picker()
            return
        end

        api.open_terminal(parts[1], parts[2])
    end, { nargs = "*" })

    command(names.codex, function(opts)
        local preset = opts.args ~= "" and opts.args or nil

        api.open_terminal("codex", preset)
    end, { nargs = "?" })

    command(names.claude, function(opts)
        local preset = opts.args ~= "" and opts.args or nil

        api.open_terminal("claude", preset)
    end, { nargs = "?" })

    command(names.ipython, function()
        api.open_ipython({
            bufnr = vim.api.nvim_get_current_buf(),
            focus = true,
        })
    end, {})

    command(names.ipython_restart, function()
        api.restart_ipython({
            bufnr = vim.api.nvim_get_current_buf(),
            focus = true,
        })
    end, {})

    command(names.ipython_clear, function()
        api.clear_ipython({
            bufnr = vim.api.nvim_get_current_buf(),
        })
    end, {})

    command(names.focus, function()
        api.focus_toggle()
    end, {})

    command(names.zoom, function()
        api.toggle_zoom()
    end, {})

    command(names.ask, function(opts)
        api.ask_picker(range_opts(opts))
    end, { range = true })

    command(names.ask_codex, function(opts)
        local preset = opts.args ~= "" and opts.args or nil

        api.ask("codex", preset, range_opts(opts))
    end, { nargs = "?", range = true })

    command(names.ask_claude, function(opts)
        local preset = opts.args ~= "" and opts.args or nil

        api.ask("claude", preset, range_opts(opts))
    end, { nargs = "?", range = true })
end

return M
