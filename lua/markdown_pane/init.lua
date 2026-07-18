local defaults = require("markdown_pane.defaults")
local entries = require("markdown_pane.entries")
local heading = require("markdown_pane.heading")
local maps = require("markdown_pane.maps")
local picker = require("markdown_pane.picker")
local question = require("markdown_pane.question")
local selection = require("markdown_pane.selection")
local terminal = require("markdown_pane.terminal")
local util = require("markdown_pane.util")

local M = {
    winid = nil,
    bufnr = nil,
    source = nil,
    wrap_enabled = nil,
    active_mode = "markdown",
    active_terminal_key = nil,
    last_terminal_key = nil,
    last_coding_agent_terminal_key = nil,
    last_tool_terminal_keys = {},
    last_focus_win = nil,
    zoomed = false,
    markdown_view = nil,
    terminals = {},
    question_buffers = {},
    config = vim.deepcopy(defaults.config),
}

local sticky_heading_group = vim.api.nvim_create_augroup("MarkdownPaneStickyHeading", { clear = true })
local focus_group = vim.api.nvim_create_augroup("MarkdownPaneFocus", { clear = true })
local shutdown_group = vim.api.nvim_create_augroup("MarkdownPaneShutdown", { clear = true })

local valid_win = util.valid_win
local valid_buf = util.valid_buf
local resolve_path = util.resolve_path
local project_root = util.project_root
local project_root_for_path = util.project_root_for_path
local root_label = util.root_label
local statusline_escape = heading.statusline_escape
local truncate_display = heading.truncate_display
local active_heading = heading.active_heading

--- Show a numbered/lettered picker and pass the selected entry to a callback.
local function numbered_select(prompt, entries, callback)
    picker.numbered_select(prompt, entries, callback, M)
end

--- Return whether a buffer belongs to the pane or one of its terminals.
local function is_pane_buf(bufnr)
    if not valid_buf(bufnr) then
        return false
    end

    if bufnr == M.bufnr then
        return true
    end

    for _, ctx in pairs(M.terminals or {}) do
        if bufnr == ctx.bufnr then
            return true
        end
    end

    return false
end

--- Remember the most recent normal window outside the pane.
local function record_focus_win(winid)
    winid = winid or vim.api.nvim_get_current_win()

    if not valid_win(winid) or winid == M.winid then
        return
    end

    local config = vim.api.nvim_win_get_config(winid)

    if config.relative and config.relative ~= "" then
        return
    end

    if is_pane_buf(vim.api.nvim_win_get_buf(winid)) then
        return
    end

    M.last_focus_win = winid
end

--- Find the pane terminal context for a buffer.
local function terminal_context_for_buf(bufnr)
    return terminal.context_for_buf(M, bufnr)
end

--- Return whether a terminal context still has a live job and buffer.
local function terminal_is_running(ctx)
    return terminal.is_running(ctx)
end

--- Return whether a tool is one of the conversational coding agents.
local function is_coding_agent_tool(tool_name)
    return terminal.is_coding_agent_tool(tool_name)
end

--- Remember the latest active terminal and per-tool coding-agent terminal.
local function remember_terminal_context(ctx)
    terminal.remember_context(M, ctx)
end

--- Build a picker entry representing an already-running terminal context.
local function entry_for_terminal_context(ctx)
    return terminal.entry_for_context(M, ctx)
end

--- Find the best running terminal context for a tool and optional root.
local function terminal_context_for_tool(tool_name, root)
    return terminal.context_for_tool(M, tool_name, root)
end

--- Find the most recently used running Codex or Claude context.
local function last_coding_agent_context(root)
    return terminal.last_coding_agent_context(M, root)
end

--- Resolve the default markdown file for the current working tree.
local function default_path()
    if vim.bo.filetype == "markdown" then
        local current = vim.api.nvim_buf_get_name(0)

        if current ~= "" then
            return current
        end
    end

    local readme = vim.fn.getcwd() .. "/README.md"

    if vim.fn.filereadable(readme) == 1 then
        return readme
    end

    return nil
end

--- Return the user-selected wrap state or configured wrap default.
local function preferred_wrap()
    if M.wrap_enabled == nil then
        return M.config.wrap
    end

    return M.wrap_enabled
end

--- Return the wrap state after considering zoom mode.
local function effective_wrap()
    return preferred_wrap()
end

--- Compute the pane width for normal or zoomed layout.
local function pane_width()
    if not M.zoomed then
        return M.config.width
    end

    local reserved = math.max(1, tonumber(vim.o.winminwidth) or 1)
    local separator = 1
    local max_width = vim.o.columns - reserved - separator

    return math.max(M.config.width, max_width)
end

--- Compute the text reflow width available inside the pane.
local function pane_text_width(winid)
    winid = winid or M.winid

    if not valid_win(winid) then
        return nil
    end

    local width = vim.api.nvim_win_get_width(winid)

    if vim.api.nvim_get_option_value("number", { win = winid }) then
        width = width - vim.api.nvim_get_option_value("numberwidth", { win = winid })
    end

    local text_width = math.max(20, width - M.config.reflow_margin)

    if M.zoomed and M.config.zoom_text_width and M.config.zoom_text_width > 0 then
        return math.min(text_width, M.config.zoom_text_width)
    end

    return text_width
end

--- Save the markdown pane cursor and scroll view for later restoration.
local function save_markdown_view()
    if not valid_win(M.winid) or not valid_buf(M.bufnr) then
        return
    end

    if vim.api.nvim_win_get_buf(M.winid) ~= M.bufnr then
        return
    end

    local ok, view = pcall(vim.api.nvim_win_call, M.winid, vim.fn.winsaveview)

    if ok then
        M.markdown_view = {
            source = M.source,
            view = view,
        }
    end
end

--- Restore the saved markdown cursor and scroll view when possible.
local function restore_markdown_view()
    if not valid_win(M.winid) or not M.markdown_view then
        return
    end

    if M.markdown_view.source ~= M.source then
        return
    end

    pcall(vim.api.nvim_win_call, M.winid, function()
        vim.fn.winrestview(M.markdown_view.view)
    end)
end

--- Build the winbar title for the active terminal pane.
local function terminal_winbar_title()
    local ctx = M.active_terminal_key and M.terminals[M.active_terminal_key] or nil

    if not ctx then
        return "Pane"
    end

    return ctx.tool_label .. ": " .. ctx.preset_label .. " - " .. root_label(ctx.root)
end

--- Refresh the pane winbar for markdown heading or terminal identity.
local function update_sticky_heading()
    if not valid_win(M.winid) then
        return
    end

    if not M.config.sticky_heading then
        vim.api.nvim_set_option_value("winbar", "", { win = M.winid })
        return
    end

    if M.active_mode ~= "markdown" then
        local max_width = math.max(10, vim.api.nvim_win_get_width(M.winid) - 4)
        local title = terminal_winbar_title()

        if M.zoomed then
            title = title .. " [zoom]"
        end

        local label = truncate_display(title, max_width)

        vim.api.nvim_set_option_value("winbar", "%#WinBar# " .. statusline_escape(label) .. " %*", { win = M.winid })
        return
    end

    local level, title = active_heading(M.winid)

    if not title then
        title = M.source and vim.fn.fnamemodify(M.source, ":t") or "Markdown Pane"
    else
        title = string.rep("#", level) .. " " .. title
    end

    title = "Markdown: " .. title

    if M.zoomed then
        title = title .. " [zoom]"
    end

    local max_width = math.max(10, vim.api.nvim_win_get_width(M.winid) - 4)
    local label = truncate_display(title, max_width)

    vim.api.nvim_set_option_value("winbar", "%#WinBar# " .. statusline_escape(label) .. " %*", { win = M.winid })
end

--- Install autocmds that keep the sticky heading current.
local function setup_sticky_heading_autocmds()
    vim.api.nvim_create_autocmd({ "WinScrolled", "WinResized", "BufWinEnter", "CursorMoved" }, {
        group = sticky_heading_group,
        callback = function()
            if M.is_open() then
                update_sticky_heading()
            end
        end,
    })
end

--- Create or return the markdown viewer buffer.
local function ensure_buf()
    if valid_buf(M.bufnr) then
        return M.bufnr
    end

    M.bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(M.bufnr, "Markdown Pane")
    vim.api.nvim_set_option_value("buftype", "", { buf = M.bufnr })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = M.bufnr })
    vim.api.nvim_set_option_value("swapfile", false, { buf = M.bufnr })
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = M.bufnr })

    return M.bufnr
end

local render_markview
local setup_pane_maps

--- Apply pane-local window options for markdown or terminal mode.
local function set_window_options(winid, mode)
    mode = mode or M.active_mode

    local wrap = effective_wrap()

    vim.api.nvim_set_option_value("winfixwidth", true, { win = winid })
    vim.api.nvim_set_option_value("number", mode == "markdown", { win = winid })
    vim.api.nvim_set_option_value("relativenumber", false, { win = winid })
    vim.api.nvim_set_option_value("wrap", mode == "markdown" and wrap or false, { win = winid })
    vim.api.nvim_set_option_value("linebreak", mode == "markdown" and wrap or false, { win = winid })
    vim.api.nvim_set_option_value("breakindent", mode == "markdown" and wrap or false, { win = winid })
    vim.api.nvim_set_option_value("showbreak", "  ", { win = winid })
    vim.api.nvim_set_option_value("cursorline", mode == "markdown", { win = winid })
    vim.api.nvim_set_option_value("signcolumn", "no", { win = winid })
    vim.api.nvim_set_option_value("foldcolumn", "0", { win = winid })
    vim.api.nvim_set_option_value("colorcolumn", "", { win = winid })
    vim.api.nvim_set_option_value("conceallevel", mode == "markdown" and 3 or 0, { win = winid })
    vim.api.nvim_set_option_value("concealcursor", mode == "markdown" and "nvic" or "", { win = winid })
    update_sticky_heading()
end

--- Re-render markview decorations for a markdown buffer.
render_markview = function(bufnr)
    local ok, markview = pcall(require, "markview")

    if not ok then
        return
    end

    pcall(markview.clear, bufnr)
    pcall(markview.render, bufnr, { enable = true, hybrid_mode = false })
end

--- Reflow the markdown pane buffer using configured internal or external formatting.
local function reflow_pane_buffer(bufnr, opts)
    opts = opts or {}
    bufnr = bufnr or M.bufnr

    if not M.config.auto_reflow or not valid_buf(bufnr) then
        return
    end

    local ok, markdown_reflow = pcall(require, "markdown_reflow")

    if not ok then
        return
    end

    local readonly = vim.api.nvim_get_option_value("readonly", { buf = bufnr })
    local modifiable = vim.api.nvim_get_option_value("modifiable", { buf = bufnr })

    vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    markdown_reflow.reflow_buffer(bufnr, {
        width = pane_text_width(),
        force = true,
        external_reflow_cmd = M.config.external_reflow_cmd,
        external_reflow_fallback = M.config.external_reflow_fallback,
        external_reflow_protect_tables = M.config.external_reflow_protect_tables,
        notify = opts.notify == true,
    })
    vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
    vim.api.nvim_set_option_value("readonly", readonly, { buf = bufnr })
    vim.api.nvim_set_option_value("modifiable", modifiable, { buf = bufnr })
end

--- Re-apply wrap settings and refresh markdown rendering if needed.
local function apply_wrap_state()
    if not valid_win(M.winid) or not valid_buf(M.bufnr) then
        return
    end

    local before = vim.wo[M.winid].wrap

    set_window_options(M.winid)

    if before ~= vim.wo[M.winid].wrap then
        render_markview(M.bufnr)
    end
end

--- Resolve the project root associated with a pane buffer.
local function pane_root(bufnr)
    local terminal_ctx = terminal_context_for_buf(bufnr)

    if terminal_ctx then
        return terminal_ctx.root
    end

    if bufnr == M.bufnr and M.source then
        return project_root_for_path(M.source)
    end

    return project_root(bufnr)
end

--- Install pane-local mappings on a markdown or terminal pane buffer.
setup_pane_maps = function(bufnr)
    maps.setup(bufnr, {
        ask_current_coding_agent = M.ask_current_coding_agent,
        ask_last_coding_agent = M.ask_last_coding_agent,
        markdown_bufnr = function()
            return M.bufnr
        end,
        open_terminal = M.open_terminal,
        pane_root = pane_root,
        show_markdown = M.show_markdown,
        toggle_markdown_agent = M.toggle_markdown_agent,
        toggle_wrap = M.toggle_wrap,
        wrap_toggle_key = function()
            return M.config.wrap_toggle_key
        end,
    })
end

--- Create or reuse the side pane window for a buffer and mode.
local function ensure_win(bufnr, mode, opts)
    opts = opts or {}
    bufnr = bufnr or ensure_buf()
    mode = mode or M.active_mode

    if valid_win(M.winid) then
        if valid_buf(bufnr) and vim.api.nvim_win_get_buf(M.winid) ~= bufnr then
            vim.api.nvim_win_set_buf(M.winid, bufnr)
        end

        vim.api.nvim_win_set_width(M.winid, pane_width())
        set_window_options(M.winid, mode)

        if opts.focus then
            local previous = vim.api.nvim_get_current_win()

            if previous ~= M.winid and valid_win(previous) then
                M.last_focus_win = previous
            end

            vim.api.nvim_set_current_win(M.winid)
        end

        return M.winid
    end

    local previous = vim.api.nvim_get_current_win()

    vim.cmd("botright vertical " .. pane_width() .. "split")
    M.winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.winid, bufnr)
    vim.api.nvim_win_set_width(M.winid, pane_width())
    set_window_options(M.winid, mode)
    update_sticky_heading()

    if mode == "markdown" then
        render_markview(bufnr)
    end

    if opts.focus then
        if valid_win(previous) and previous ~= M.winid then
            M.last_focus_win = previous
        end

        vim.api.nvim_set_current_win(M.winid)
    elseif valid_win(previous) then
        vim.api.nvim_set_current_win(previous)
    end

    return M.winid
end

--- Load markdown file contents into the pane buffer.
local function load_file(path)
    local bufnr = ensure_buf()
    local ok, lines = pcall(vim.fn.readfile, path)

    if not ok then
        vim.notify("Could not read markdown file: " .. path, vim.log.levels.ERROR)
        return false
    end

    M.source = path

    render_markview(bufnr)
    vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
    pcall(vim.treesitter.start, bufnr, "markdown")

    reflow_pane_buffer(bufnr)

    vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
    vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    render_markview(bufnr)
    update_sticky_heading()

    return true
end

--- Toggle wrapping in the markdown viewer pane.
function M.toggle_wrap()
    M.wrap_enabled = not preferred_wrap()
    apply_wrap_state()
end

--- Open a markdown file in the pane without stealing focus.
function M.open(path)
    path = resolve_path(path) or default_path()

    if not path then
        M.pick()
        return
    end

    if vim.fn.filereadable(path) ~= 1 then
        vim.notify("Markdown file not readable: " .. path, vim.log.levels.ERROR)
        return
    end

    local previous = vim.api.nvim_get_current_win()
    local should_restore_view = M.source == path and M.markdown_view and M.markdown_view.source == path

    M.active_mode = "markdown"
    M.active_terminal_key = nil

    local winid = ensure_win(ensure_buf(), "markdown")

    if not load_file(path) then
        return
    end

    set_window_options(winid, "markdown")
    update_sticky_heading()
    render_markview(M.bufnr)

    vim.api.nvim_win_call(winid, function()
        if should_restore_view then
            restore_markdown_view()
        else
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
            vim.cmd("normal! zt")
        end
    end)
    setup_pane_maps(M.bufnr)

    if valid_win(previous) then
        vim.api.nvim_set_current_win(previous)
    end
end

--- Switch the pane back to the markdown viewer.
function M.show_markdown()
    if not valid_buf(M.bufnr) then
        M.open(M.source)

        if M.config.focus_on_switch and valid_win(M.winid) then
            local previous = vim.api.nvim_get_current_win()

            if previous ~= M.winid and valid_win(previous) then
                M.last_focus_win = previous
            end

            vim.api.nvim_set_current_win(M.winid)
        end

        return
    end

    local previous = vim.api.nvim_get_current_win()

    if M.active_terminal_key then
        remember_terminal_context(M.terminals[M.active_terminal_key])
    end

    M.active_mode = "markdown"
    M.active_terminal_key = nil

    local winid = ensure_win(M.bufnr, "markdown", { focus = M.config.focus_on_switch })

    set_window_options(winid, "markdown")
    update_sticky_heading()
    render_markview(M.bufnr)
    restore_markdown_view()
    setup_pane_maps(M.bufnr)

    if not M.config.focus_on_switch and valid_win(previous) then
        vim.api.nvim_set_current_win(previous)
    end
end

--- Close the pane window while preserving buffers and state.
function M.close()
    if valid_win(M.winid) then
        if M.active_mode == "markdown" then
            save_markdown_view()
        end

        vim.api.nvim_win_close(M.winid, true)
    end

    M.winid = nil
end

--- Toggle the pane, optionally opening a specific markdown file.
function M.toggle(path)
    if path and path ~= "" then
        M.open(path)
    elseif valid_win(M.winid) then
        M.close()
    else
        M.open(M.source)
    end
end

--- Return whether the pane window is currently open.
function M.is_open()
    return valid_win(M.winid)
end

--- Toggle focus between the pane and the last normal window.
function M.focus_toggle()
    local current = vim.api.nvim_get_current_win()

    if valid_win(M.winid) and current == M.winid then
        if valid_win(M.last_focus_win) then
            vim.api.nvim_set_current_win(M.last_focus_win)
        else
            vim.cmd("wincmd p")
        end

        return
    end

    if valid_win(current) then
        M.last_focus_win = current
    end

    if valid_win(M.winid) then
        vim.api.nvim_set_current_win(M.winid)
        return
    end

    M.open(M.source)

    if valid_win(M.winid) then
        vim.api.nvim_set_current_win(M.winid)
    end
end

--- Toggle the pane between normal width and zoom width.
function M.toggle_zoom()
    M.zoomed = not M.zoomed

    if not valid_win(M.winid) then
        return
    end

    local previous = vim.api.nvim_get_current_win()

    if M.zoomed and previous ~= M.winid and valid_win(previous) then
        M.last_focus_win = previous
    end

    if M.active_mode == "markdown" then
        save_markdown_view()
    end

    pcall(vim.api.nvim_win_set_width, M.winid, pane_width())
    set_window_options(M.winid, M.active_mode == "markdown" and "markdown" or "terminal")

    if M.active_mode == "markdown" and valid_buf(M.bufnr) then
        reflow_pane_buffer(M.bufnr)
        render_markview(M.bufnr)
        restore_markdown_view()
    end

    update_sticky_heading()

    if M.zoomed then
        vim.api.nvim_set_current_win(M.winid)
    end

    vim.notify("Pane zoom " .. (M.zoomed and "on" or "off"), vim.log.levels.INFO)
end

--- Return the current text width used for markdown reflow.
function M.text_width()
    return pane_text_width()
end

--- Merge user configuration and install pane autocmds.
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    vim.api.nvim_clear_autocmds({ group = focus_group })
    vim.api.nvim_create_autocmd("WinEnter", {
        group = focus_group,
        callback = function()
            record_focus_win()
        end,
    })

    vim.api.nvim_clear_autocmds({ group = shutdown_group })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = shutdown_group,
        callback = function()
            if M.config.shutdown_on_exit then
                M.shutdown_terminals()
            end
        end,
    })
end

--- Resolve a configured preset by name, label, or default position.
local function preset_by_name(tool, preset_name)
    return entries.preset_by_name(tool, preset_name)
end

--- Build quick picker entries for Codex, Claude, and optionally IPython.
local function tool_shortcut_entries(root, opts)
    return entries.tool_shortcut_entries(M, root, opts)
end

--- Build numbered picker entries for configured terminal presets.
local function terminal_entries(root, start_index, opts)
    return entries.terminal_entries(M, root, start_index, opts)
end

--- Capture text, file, root, and snippet language for a send/ask action.
local function selection_context(opts)
    return selection.context(opts, {
        pane_bufnr = M.bufnr,
        source = M.source,
        terminal_context_for_buf = terminal_context_for_buf,
    })
end

--- Build terminal module callbacks that still belong to pane/window state.
local function terminal_deps()
    return {
        ensure_win = ensure_win,
        pane_root = pane_root,
        save_markdown_view = save_markdown_view,
        selection_context = selection_context,
        setup_pane_maps = setup_pane_maps,
        update_sticky_heading = update_sticky_heading,
    }
end

--- Open or focus a pane terminal, reusing an existing session when possible.
function M.open_terminal(tool_name, preset_name, opts)
    return terminal.open(M, terminal_deps(), tool_name, preset_name, opts)
end

--- Show the most recently used coding-agent terminal.
function M.show_last_agent(opts)
    terminal.show_last_agent(M, terminal_deps(), opts)
end

--- Toggle between markdown view and the last coding-agent terminal.
function M.toggle_markdown_agent()
    if M.active_mode == "markdown" then
        M.show_last_agent({ focus = true })
    else
        M.show_markdown()
    end
end

--- Switch the pane to markdown or a selected terminal entry.
function M.switch(entry)
    if entry == "markdown" or (type(entry) == "table" and entry.kind == "markdown") then
        M.show_markdown()
        return
    end

    if type(entry) == "string" then
        M.open_terminal(entry)
        return
    end

    if type(entry) == "table" and entry.kind == "terminal" then
        M.open_terminal(entry.tool_name, entry.preset_name, { focus = M.config.focus_on_switch })
    end
end

--- Show the pane switcher picker.
function M.switch_picker()
    local bufnr = vim.api.nvim_get_current_buf()
    local terminal_ctx = terminal_context_for_buf(bufnr)
    local root = terminal_ctx and terminal_ctx.root or pane_root(bufnr)
    local entries = {
        {
            kind = "markdown",
            index = 0,
            key = "0",
            label = "Markdown Viewer",
        },
    }

    vim.list_extend(entries, tool_shortcut_entries(root))
    vim.list_extend(entries, terminal_entries(root, 1, { preset_tools_only = true }))

    numbered_select("Switch pane", entries, function(choice)
        if choice then
            M.switch(choice)
        end
    end)
end

--- Send an ask prompt, switching model first when needed.
local function send_prompt_to_terminal(ctx, entry, prompt, started)
    terminal.send_prompt(M, ctx, entry, prompt, started)
end

--- Open or focus the IPython pane terminal.
function M.open_ipython(opts)
    return terminal.open_ipython(M, terminal_deps(), opts)
end

--- Send the current line or selection to IPython.
function M.send_ipython(opts)
    terminal.send_ipython(M, terminal_deps(), opts)
end

--- Clear the running IPython terminal screen.
function M.clear_ipython(opts)
    terminal.clear_ipython(M, terminal_deps(), opts)
end

--- Restart the IPython pane terminal for the current root.
function M.restart_ipython(opts)
    return terminal.restart_ipython(M, terminal_deps(), opts)
end

--- Shut down all pane-owned terminal sessions.
function M.shutdown_terminals(opts)
    terminal.shutdown_terminals(M, opts)
end

--- Build question-editor callbacks that still belong to pane/window state.
local function question_deps()
    return {
        entry_for_terminal_context = entry_for_terminal_context,
        is_coding_agent_tool = is_coding_agent_tool,
        last_coding_agent_context = last_coding_agent_context,
        numbered_select = numbered_select,
        open_terminal = M.open_terminal,
        preset_by_name = preset_by_name,
        selection_context = selection_context,
        send_prompt_to_terminal = send_prompt_to_terminal,
        set_window_options = set_window_options,
        statusline_escape = statusline_escape,
        terminal_context_for_tool = terminal_context_for_tool,
        terminal_entries = terminal_entries,
        tool_shortcut_entries = tool_shortcut_entries,
        update_sticky_heading = update_sticky_heading,
    }
end

--- Cancel and close a question editor buffer.
function M.cancel_question(bufnr)
    question.cancel(M, bufnr)
end

--- Finish a question editor, sending only after a write.
function M.finish_question(bufnr)
    question.finish(M, bufnr)
end

--- Mark a question editor as written and update its cached prompt.
function M.write_question(bufnr)
    question.write(M, bufnr)
end

--- Open the target picker from inside a question editor.
function M.change_question_target(bufnr)
    question.change_target(M, bufnr)
end

--- Ask a specific picker entry using a captured or fresh context.
function M.ask_with_entry(entry, opts)
    question.ask_with_entry(M, question_deps(), entry, opts)
end

--- Capture selection and ask via the target picker.
function M.ask_picker(opts)
    question.ask_picker(M, question_deps(), opts)
end

--- Ask the most recently used Codex or Claude terminal.
function M.ask_last_coding_agent(opts)
    question.ask_last_coding_agent(M, question_deps(), opts)
end

--- Ask the current/default terminal for a specific coding agent.
function M.ask_current_coding_agent(tool_name, opts)
    question.ask_current_coding_agent(M, question_deps(), tool_name, opts)
end

--- Ask a specific tool and optional preset.
function M.ask(tool_name, preset_name, opts)
    question.ask(M, question_deps(), tool_name, preset_name, opts)
end

--- Pick a markdown document and open it in the pane.
function M.pick()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local finder

    if vim.fn.executable("rg") == 1 then
        finder = finders.new_oneshot_job({
            "rg",
            "--files",
            "-g",
            "*.md",
            "-g",
            "*.markdown",
        }, {
            entry_maker = function(entry)
                local path = resolve_path(entry)

                return {
                    value = path,
                    display = entry,
                    ordinal = entry,
                }
            end,
        })
    else
        local files = vim.fn.globpath(vim.fn.getcwd(), "**/*.md", false, true)

        vim.list_extend(files, vim.fn.globpath(vim.fn.getcwd(), "**/*.markdown", false, true))

        finder = finders.new_table({
            results = files,
            entry_maker = function(entry)
                return {
                    value = resolve_path(entry),
                    display = vim.fn.fnamemodify(entry, ":."),
                    ordinal = entry,
                }
            end,
        })
    end

    pickers.new({}, {
        prompt_title = "Markdown Pane",
        finder = finder,
        sorter = conf.file_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()

                actions.close(prompt_bufnr)

                if selection and selection.value then
                    M.open(selection.value)
                end
            end)

            return true
        end,
    }):find()
end

setup_sticky_heading_autocmds()

return M
