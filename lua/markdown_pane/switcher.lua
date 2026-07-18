local M = {}

--- Toggle between markdown view and the last coding-agent terminal.
function M.toggle_markdown_agent(state, deps)
    if state.active_mode == "markdown" then
        deps.show_last_agent({ focus = true })
    else
        deps.show_markdown()
    end
end

--- Switch the pane to markdown or a selected terminal entry.
function M.switch(state, deps, entry)
    if entry == "markdown" or (type(entry) == "table" and entry.kind == "markdown") then
        deps.show_markdown()
        return
    end

    if type(entry) == "string" then
        deps.open_terminal(entry)
        return
    end

    if type(entry) == "table" and entry.kind == "terminal" then
        deps.open_terminal(entry.tool_name, entry.preset_name, { focus = state.config.focus_on_switch })
    end
end

--- Build pane switcher entries for the current buffer and root.
function M.entries(state, deps, bufnr)
    local terminal_ctx = deps.terminal_context_for_buf(bufnr)
    local root = terminal_ctx and terminal_ctx.root or deps.pane_root(bufnr)
    local result = {
        {
            kind = "markdown",
            index = 0,
            key = "0",
            label = "Markdown Viewer",
        },
    }

    vim.list_extend(result, deps.tool_shortcut_entries(root))
    vim.list_extend(result, deps.terminal_entries(root, 1, { preset_tools_only = true }))

    return result
end

--- Show the pane switcher picker.
function M.switch_picker(state, deps)
    local bufnr = vim.api.nvim_get_current_buf()
    local result = M.entries(state, deps, bufnr)

    deps.numbered_select("Switch pane", result, function(choice)
        if choice then
            M.switch(state, deps, choice)
        end
    end)
end

return M
