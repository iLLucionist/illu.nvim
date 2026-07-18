local defaults = require("markdown_pane.defaults")
local heading = require("markdown_pane.heading")
local picker = require("markdown_pane.picker")
local selection = require("markdown_pane.selection")
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

local trim = util.trim
local valid_win = util.valid_win
local valid_buf = util.valid_buf
local is_running = util.is_running
local resolve_path = util.resolve_path
local project_root = util.project_root
local project_root_for_path = util.project_root_for_path
local relative_path = util.relative_path
local root_label = util.root_label
local terminal_key = util.terminal_key
local sanitize_name = util.sanitize_name
local command_list = util.command_list
local executable_exists = util.executable_exists
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
    for _, ctx in pairs(M.terminals) do
        if ctx.bufnr == bufnr then
            return ctx
        end
    end

    return nil
end

--- Return whether a terminal context still has a live job and buffer.
local function terminal_is_running(ctx)
    return ctx and valid_buf(ctx.bufnr) and is_running(ctx.job_id)
end

--- Return whether a tool is one of the conversational coding agents.
local function is_coding_agent_tool(tool_name)
    return tool_name == "codex" or tool_name == "claude"
end

--- Remember the latest active terminal and per-tool coding-agent terminal.
local function remember_terminal_context(ctx)
    if not ctx then
        return
    end

    M.last_terminal_key = ctx.key

    if is_coding_agent_tool(ctx.tool_name) then
        M.last_coding_agent_terminal_key = ctx.key
        M.last_tool_terminal_keys[ctx.tool_name] = ctx.key
    end
end

--- Build a picker entry representing an already-running terminal context.
local function entry_for_terminal_context(ctx)
    local tool = (M.config.tools or {})[ctx.tool_name] or {}

    return {
        kind = "terminal",
        tool_name = ctx.tool_name,
        preset_name = ctx.preset_name,
        root = ctx.root,
        terminal_key = ctx.key,
        label = (tool.label or ctx.tool_label or ctx.tool_name) .. " current: " .. (ctx.preset_label or ctx.preset_name or "Default"),
        running = true,
        current = true,
        active = M.active_terminal_key == ctx.key,
    }
end

--- Find the best running terminal context for a tool and optional root.
local function terminal_context_for_tool(tool_name, root)
    local last_key = M.last_tool_terminal_keys and M.last_tool_terminal_keys[tool_name] or nil
    local last_ctx = last_key and M.terminals[last_key] or nil

    if last_ctx and last_ctx.tool_name == tool_name and terminal_is_running(last_ctx) then
        return last_ctx
    end

    local root_ctx = root and M.terminals[terminal_key(tool_name, root)] or nil

    if root_ctx and terminal_is_running(root_ctx) then
        return root_ctx
    end

    for _, ctx in pairs(M.terminals or {}) do
        if ctx.tool_name == tool_name and terminal_is_running(ctx) then
            return ctx
        end
    end

    return nil
end

--- Find the most recently used running Codex or Claude context.
local function last_coding_agent_context(root)
    local last_ctx = M.last_coding_agent_terminal_key and M.terminals[M.last_coding_agent_terminal_key] or nil

    if last_ctx and is_coding_agent_tool(last_ctx.tool_name) and terminal_is_running(last_ctx) then
        return last_ctx
    end

    local active_ctx = M.active_terminal_key and M.terminals[M.active_terminal_key] or nil

    if active_ctx and is_coding_agent_tool(active_ctx.tool_name) and terminal_is_running(active_ctx) then
        return active_ctx
    end

    for _, tool_name in ipairs({ "codex", "claude" }) do
        local ctx = terminal_context_for_tool(tool_name, root)

        if ctx then
            return ctx
        end
    end

    return nil
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
    local function map(mode, lhs, rhs, desc, opts)
        opts = opts or {}

        vim.keymap.set(mode, lhs, rhs, {
            buffer = bufnr,
            desc = desc,
            silent = true,
            nowait = opts.nowait,
        })
    end

    local function visual_opts()
        return {
            bufnr = bufnr,
            visual = true,
            visual_mode = vim.fn.mode(1),
        }
    end

    map("n", "<space>0", function()
        M.show_markdown()
    end, "Show markdown pane", { nowait = true })

    map("n", "<space>x", function()
        M.open_terminal("codex", nil, { root = pane_root(bufnr), focus = true })
    end, "Show Codex pane", { nowait = true })

    map("n", "<space>c", function()
        M.open_terminal("claude", nil, { root = pane_root(bufnr), focus = true })
    end, "Show Claude pane", { nowait = true })

    map("n", "<space>i", function()
        M.open_terminal("ipython", nil, { root = pane_root(bufnr), focus = true })
    end, "Show IPython pane", { nowait = true })

    map("n", "<leader>gg", function()
        M.toggle_markdown_agent()
    end, "Toggle markdown/agent pane")

    map("n", "<C-g>", function()
        M.toggle_markdown_agent()
    end, "Toggle markdown/agent pane")

    map("n", "<leader>gi", function()
        M.open_terminal("ipython", nil, { root = pane_root(bufnr), focus = true })
    end, "Show IPython pane")

    map("n", "gf", function()
        require("smart_gf").open()
    end, "Smart go to file from pane")

    map("x", "aa", function()
        M.ask_last_coding_agent(visual_opts())
    end, "Ask last coding agent")

    map("x", "ax", function()
        M.ask_current_coding_agent("codex", visual_opts())
    end, "Ask current Codex pane")

    map("x", "ac", function()
        M.ask_current_coding_agent("claude", visual_opts())
    end, "Ask current Claude pane")

    if bufnr == M.bufnr then
        map("n", M.config.wrap_toggle_key, function()
            M.toggle_wrap()
        end, "Toggle markdown pane wrap")
    end
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
    local presets = tool.presets or {}

    if not preset_name and presets[1] then
        return presets[1]
    end

    for _, preset in ipairs(presets) do
        if preset.name == preset_name or preset.label == preset_name then
            return preset
        end
    end

    return presets[1] or { name = "default", label = "Default", args = {} }
end

--- Return configured tool names in stable picker order.
local function ordered_tool_names()
    local tools = M.config.tools or {}
    local names = {}
    local seen = {}

    for _, name in ipairs({ "codex", "claude", "ipython" }) do
        if tools[name] then
            table.insert(names, name)
            seen[name] = true
        end
    end

    local rest = {}

    for name in pairs(tools) do
        if not seen[name] then
            table.insert(rest, name)
        end
    end

    table.sort(rest)
    vim.list_extend(names, rest)

    return names
end

--- Build the quick x/c/i picker entry for a tool.
local function current_or_default_entry(tool_name, root, key)
    local tool = (M.config.tools or {})[tool_name]

    if not tool then
        return nil
    end

    local terminal_ctx = root and M.terminals[terminal_key(tool_name, root)] or nil
    local running = terminal_is_running(terminal_ctx)
    local preset = running and preset_by_name(tool, terminal_ctx.preset_name) or preset_by_name(tool)

    return {
        kind = "terminal",
        shortcut = true,
        tool_name = tool_name,
        preset_name = preset.name,
        key = key,
        label = (tool.label or tool_name) .. " current: " .. (preset.label or preset.name or "Default"),
        running = running,
        current = running,
        active = running and M.active_terminal_key == terminal_ctx.key,
    }
end

--- Build quick picker entries for Codex, Claude, and optionally IPython.
local function tool_shortcut_entries(root, opts)
    opts = opts or {}

    local entries = {}
    local codex = current_or_default_entry("codex", root, "x")
    local claude = current_or_default_entry("claude", root, "c")
    local ipython = nil

    if not opts.ask_only then
        ipython = current_or_default_entry("ipython", root, "i")
    end

    if codex then
        table.insert(entries, codex)
    end

    if claude then
        table.insert(entries, claude)
    end

    if ipython then
        table.insert(entries, ipython)
    end

    return entries
end

--- Build numbered picker entries for configured terminal presets.
local function terminal_entries(root, start_index, opts)
    opts = opts or {}

    local entries = {}
    local index = start_index or 1

    for _, tool_name in ipairs(ordered_tool_names()) do
        local tool = M.config.tools[tool_name]

        if (not opts.ask_only or tool.ask ~= false) and not (opts.preset_tools_only and tool.ask == false) then
            for _, preset in ipairs(tool.presets or { { name = "default", label = "Default", args = {} } }) do
                table.insert(entries, {
                    kind = "terminal",
                    tool_name = tool_name,
                    preset_name = preset.name,
                    label = (tool.label or tool_name) .. ": " .. (preset.label or preset.name or "Default"),
                    ordinal = (tool.label or tool_name) .. " " .. (preset.label or preset.name or "Default"),
                })
            end
        end
    end

    for _, entry in ipairs(entries) do
        entry.index = index
        entry.key = tostring(index)

        if root then
            local key = terminal_key(entry.tool_name, root)
            local ctx = M.terminals[key]

            entry.terminal_key = key
            entry.session_running = terminal_is_running(ctx)
            entry.current = entry.session_running and ctx.preset_name == entry.preset_name
            entry.running = entry.current
            entry.active = entry.current and M.active_terminal_key == key
        end

        index = index + 1
    end

    return entries
end

--- Start a new pane-owned terminal job for a tool and project root.
local function start_terminal(tool_name, preset_name, root)
    local tool = (M.config.tools or {})[tool_name]

    if not tool then
        vim.notify("Unknown pane tool: " .. tostring(tool_name), vim.log.levels.ERROR)
        return nil
    end

    local preset = preset_by_name(tool, preset_name)
    local key = terminal_key(tool_name, root)
    local existing = M.terminals[key]

    if existing and valid_buf(existing.bufnr) and is_running(existing.job_id) then
        return existing, false
    end

    local cmd = command_list(tool, preset, root)

    if not executable_exists(cmd[1]) then
        vim.notify("Pane tool executable not found: " .. tostring(cmd[1]), vim.log.levels.ERROR)
        return nil
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    local ctx = {
        key = key,
        tool_name = tool_name,
        tool_label = tool.label or tool_name,
        preset_name = preset.name or "default",
        preset_label = preset.label or preset.name or "Default",
        preset = preset,
        root = root,
        bufnr = bufnr,
        job_id = nil,
        send_delay_ms = tool.send_delay_ms or 700,
    }

    pcall(vim.api.nvim_buf_set_name, bufnr, "Pane://" .. sanitize_name(key))
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
    setup_pane_maps(bufnr)

    M.active_mode = tool_name
    M.active_terminal_key = key
    remember_terminal_context(ctx)
    ensure_win(bufnr, "terminal", { focus = false })

    vim.api.nvim_win_call(M.winid, function()
        vim.api.nvim_set_current_buf(bufnr)
        ctx.job_id = vim.fn.termopen(cmd, {
            cwd = root,
            on_exit = function()
                update_sticky_heading()
            end,
        })
    end)

    if not ctx.job_id or ctx.job_id <= 0 then
        vim.notify("Could not start pane tool: " .. table.concat(cmd, " "), vim.log.levels.ERROR)
        return nil
    end

    M.terminals[key] = ctx

    return ctx, true
end

--- Open or focus a pane terminal, reusing an existing session when possible.
function M.open_terminal(tool_name, preset_name, opts)
    opts = opts or {}

    if M.active_mode == "markdown" then
        save_markdown_view()
    end

    local root = opts.root or pane_root(opts.bufnr or vim.api.nvim_get_current_buf())
    local tool = (M.config.tools or {})[tool_name]

    if not tool then
        vim.notify("Unknown pane tool: " .. tostring(tool_name), vim.log.levels.ERROR)
        return nil
    end

    local preset = preset_by_name(tool, preset_name)
    local key = terminal_key(tool_name, root)
    local ctx = M.terminals[key]
    local started = false

    if not (ctx and valid_buf(ctx.bufnr) and is_running(ctx.job_id)) then
        ctx, started = start_terminal(tool_name, preset.name, root)
    end

    if not ctx then
        return nil
    end

    ctx.requested_preset = preset
    M.active_mode = tool_name
    M.active_terminal_key = ctx.key
    remember_terminal_context(ctx)
    setup_pane_maps(ctx.bufnr)
    ensure_win(ctx.bufnr, "terminal", { focus = opts.focus == nil and M.config.focus_on_switch or opts.focus })
    update_sticky_heading()

    return ctx, started
end

--- Show the most recently used coding-agent terminal.
function M.show_last_agent(opts)
    opts = opts or {}

    local ctx = M.last_terminal_key and M.terminals[M.last_terminal_key] or nil

    if ctx and valid_buf(ctx.bufnr) and is_running(ctx.job_id) then
        M.open_terminal(ctx.tool_name, ctx.preset_name, {
            root = ctx.root,
            focus = opts.focus == nil and M.config.focus_on_switch or opts.focus,
        })
        return
    end

    local root = opts.root or pane_root(vim.api.nvim_get_current_buf())
    local tool_name = ctx and ctx.tool_name or "codex"
    local preset_name = ctx and ctx.preset_name or nil

    M.open_terminal(tool_name, preset_name, {
        root = root,
        focus = opts.focus == nil and M.config.focus_on_switch or opts.focus,
    })
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

--- Capture text, file, root, and snippet language for a send/ask action.
local function selection_context(opts)
    return selection.context(opts, {
        pane_bufnr = M.bufnr,
        source = M.source,
        terminal_context_for_buf = terminal_context_for_buf,
    })
end

local format_prompt = selection.format_prompt
local prompt_template = selection.prompt_template

--- Format the in-terminal command that switches a running tool preset.
local function format_switch_command(tool, preset)
    if not tool or not preset then
        return nil
    end

    local template = preset.switch_command or tool.switch_command

    if type(template) == "function" then
        return template(preset, tool)
    end

    if type(template) ~= "string" or template == "" then
        return nil
    end

    local values = {
        model = preset.model or preset.name or "",
        effort = preset.effort or "",
        speed = preset.speed or "normal",
        label = preset.label or preset.name or "",
        name = preset.name or "",
    }

    return (template:gsub("{([%w_]+)}", function(key)
        return values[key] or ""
    end):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Send text to a terminal job using bracketed paste.
local function send_to_terminal(ctx, prompt, started)
    local delay = started and ctx.send_delay_ms or 50

    vim.defer_fn(function()
        if not is_running(ctx.job_id) then
            vim.notify(ctx.tool_label .. " terminal is not running", vim.log.levels.ERROR)
            return
        end

        vim.fn.chansend(ctx.job_id, "\27[200~" .. prompt .. "\27[201~\r")
    end, delay)
end

--- Send an ask prompt, switching model first when needed.
local function send_prompt_to_terminal(ctx, entry, prompt, started)
    local tool = (M.config.tools or {})[ctx.tool_name]
    local preset = tool and preset_by_name(tool, entry and entry.preset_name or ctx.preset_name) or ctx.preset
    local needs_switch = not started and preset and ctx.preset_name ~= preset.name
    local switch_command = needs_switch and format_switch_command(tool, preset) or nil

    if switch_command and switch_command ~= "" then
        vim.defer_fn(function()
            if not is_running(ctx.job_id) then
                vim.notify(ctx.tool_label .. " terminal is not running", vim.log.levels.ERROR)
                return
            end

            vim.fn.chansend(ctx.job_id, switch_command .. "\r")
        end, 50)
    end

    if preset then
        ctx.preset = preset
        ctx.preset_name = preset.name or "default"
        ctx.preset_label = preset.label or preset.name or "Default"
    end

    local prompt_delay = switch_command and 350 or nil

    if prompt_delay then
        vim.defer_fn(function()
            send_to_terminal(ctx, prompt, false)
        end, prompt_delay)
    else
        send_to_terminal(ctx, prompt, started)
    end
end

--- Resolve the project root used for IPython operations.
local function ipython_root(opts)
    opts = opts or {}

    return opts.root or pane_root(opts.bufnr or vim.api.nvim_get_current_buf())
end

--- Open or focus the IPython pane terminal.
function M.open_ipython(opts)
    opts = opts or {}

    return M.open_terminal("ipython", nil, {
        root = ipython_root(opts),
        bufnr = opts.bufnr,
        focus = opts.focus,
    })
end

--- Send the current line or selection to IPython.
function M.send_ipython(opts)
    opts = opts or {}

    local context = selection_context(opts)

    if not context then
        return
    end

    local ctx, started = M.open_terminal("ipython", nil, {
        root = context.root,
        bufnr = context.bufnr,
        focus = opts.focus == true,
    })

    if ctx then
        send_to_terminal(ctx, context.text, started)
    end
end

--- Clear the running IPython terminal screen.
function M.clear_ipython(opts)
    opts = opts or {}

    local root = ipython_root(opts)
    local ctx = M.terminals[terminal_key("ipython", root)]

    if not (ctx and valid_buf(ctx.bufnr) and is_running(ctx.job_id)) then
        vim.notify("No IPython pane running for " .. root_label(root), vim.log.levels.WARN)
        return
    end

    vim.fn.chansend(ctx.job_id, "\12")
end

--- Restart the IPython pane terminal for the current root.
function M.restart_ipython(opts)
    opts = opts or {}

    local root = ipython_root(opts)
    local key = terminal_key("ipython", root)
    local ctx = M.terminals[key]

    if ctx then
        if is_running(ctx.job_id) then
            pcall(vim.fn.jobstop, ctx.job_id)
        end

        if valid_buf(ctx.bufnr) then
            pcall(vim.api.nvim_buf_delete, ctx.bufnr, { force = true })
        end

        M.terminals[key] = nil
    end

    return M.open_terminal("ipython", nil, {
        root = root,
        bufnr = opts.bufnr,
        focus = opts.focus == nil or opts.focus,
    })
end

--- Resolve the polite shutdown command for a terminal context.
local function terminal_shutdown_command(ctx)
    local tool = (M.config.tools or {})[ctx.tool_name]

    if not tool then
        return nil
    end

    local command = tool.shutdown_command or tool.exit_command

    if type(command) == "function" then
        command = command(ctx, tool)
    end

    return command
end

--- Resolve the shutdown timeout for a terminal context.
local function terminal_shutdown_timeout(ctx, opts)
    local tool = (M.config.tools or {})[ctx.tool_name] or {}

    return opts.timeout_ms or tool.shutdown_timeout_ms or M.config.shutdown_timeout_ms or 300
end

--- Gracefully stop one terminal, then force-stop if needed.
local function shutdown_terminal(ctx, opts)
    opts = opts or {}

    if not (ctx and ctx.job_id and is_running(ctx.job_id)) then
        return
    end

    local timeout = terminal_shutdown_timeout(ctx, opts)
    local command = terminal_shutdown_command(ctx)

    if command and command ~= "" then
        pcall(vim.fn.chansend, ctx.job_id, command)
        vim.wait(timeout, function()
            return not is_running(ctx.job_id)
        end, 20)
    end

    if is_running(ctx.job_id) then
        pcall(vim.fn.jobstop, ctx.job_id)
        vim.wait(timeout, function()
            return not is_running(ctx.job_id)
        end, 20)
    end
end

--- Shut down all pane-owned terminal sessions.
function M.shutdown_terminals(opts)
    opts = opts or {}

    for key, ctx in pairs(M.terminals or {}) do
        shutdown_terminal(ctx, opts)

        if not is_running(ctx.job_id) then
            M.terminals[key] = nil
        end
    end
end

--- Capture enough pane/window state to restore after question editing.
local function capture_origin()
    local winid = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = { 1, 0 }
    local view = nil

    pcall(function()
        cursor = vim.api.nvim_win_get_cursor(winid)
    end)

    pcall(function()
        view = vim.fn.winsaveview()
    end)

    return {
        winid = winid,
        bufnr = bufnr,
        cursor = cursor,
        view = view,
        pane_active_mode = M.active_mode,
        pane_active_terminal_key = M.active_terminal_key,
    }
end

--- Restore focus and pane state after closing a question editor.
local function restore_origin(origin)
    if not origin or not valid_win(origin.winid) then
        return
    end

    if origin.winid == M.winid then
        M.active_mode = origin.pane_active_mode
        M.active_terminal_key = origin.pane_active_terminal_key

        if valid_buf(origin.bufnr) then
            if not pcall(vim.api.nvim_win_set_buf, origin.winid, origin.bufnr) then
                pcall(vim.cmd, "hide")
                pcall(vim.api.nvim_win_set_buf, origin.winid, origin.bufnr)
            end
        end

        set_window_options(origin.winid, M.active_mode == "markdown" and "markdown" or "terminal")
        update_sticky_heading()
    elseif valid_buf(origin.bufnr) then
        if not pcall(vim.api.nvim_win_set_buf, origin.winid, origin.bufnr) then
            pcall(vim.cmd, "hide")
            pcall(vim.api.nvim_win_set_buf, origin.winid, origin.bufnr)
        end
    end

    pcall(vim.api.nvim_set_current_win, origin.winid)

    if origin.view then
        pcall(vim.fn.winrestview, origin.view)
    else
        pcall(vim.api.nvim_win_set_cursor, origin.winid, origin.cursor)
    end
end

--- Open the editable ask prompt scratch buffer.
local function open_question_buffer(entry, context, origin)
    origin = origin or capture_origin()

    local scratch = vim.api.nvim_create_buf(false, true)
    local augroup = vim.api.nvim_create_augroup("MarkdownPaneQuestion" .. scratch, { clear = true })
    local scratch_win = nil
    local sent = false
    local state = {
        entry = entry,
        written_prompt = nil,
    }
    local initial_prompt = prompt_template(context)

    pcall(vim.api.nvim_buf_set_name, scratch, "Pane Question://" .. sanitize_name(entry.label))
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = scratch })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = scratch })
    vim.api.nvim_set_option_value("swapfile", false, { buf = scratch })
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = scratch })
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, vim.split(initial_prompt, "\n", { plain = true }))
    vim.api.nvim_set_option_value("modified", false, { buf = scratch })

    local width = math.max(50, math.floor(vim.o.columns * 0.78))
    local height = math.max(12, math.floor(vim.o.lines * 0.72))

    local function target_label()
        return state.entry and state.entry.label or entry.label
    end

    local function update_prompt_chrome()
        if not valid_win(scratch_win) then
            return
        end

        local title = " Question for " .. target_label() .. " "
        local footer = " M/<Tab>: model  :wq send  :w draft  :q cancel  target: " .. target_label() .. " "

        pcall(vim.api.nvim_win_set_config, scratch_win, {
            title = title,
            title_pos = "center",
            footer = footer,
            footer_pos = "center",
        })
        vim.api.nvim_set_option_value("winbar", "%#WinBar# " .. statusline_escape("Question target: " .. target_label()) .. " %*", { win = scratch_win })
    end

    scratch_win = vim.api.nvim_open_win(scratch, true, {
        relative = "editor",
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        width = width,
        height = height,
        style = "minimal",
        border = "single",
        title = " Question for " .. target_label() .. " ",
        title_pos = "center",
        footer = " M/<Tab>: model  :wq send  :w draft  :q cancel  target: " .. target_label() .. " ",
        footer_pos = "center",
    })

    pcall(vim.api.nvim_win_set_cursor, scratch_win, { 2, 0 })
    update_prompt_chrome()

    local function buffer_prompt()
        return trim(table.concat(vim.api.nvim_buf_get_lines(scratch, 0, -1, false), "\n"))
    end

    local function close_scratch()
        if valid_win(scratch_win) then
            pcall(vim.api.nvim_win_close, scratch_win, true)
        end

        if valid_buf(scratch) then
            pcall(vim.api.nvim_buf_delete, scratch, { force = true })
        end
    end

    local function cancel(opts)
        opts = opts or {}

        if sent then
            return
        end

        sent = true
        vim.api.nvim_set_option_value("modified", false, { buf = scratch })
        restore_origin(origin)

        if not opts.from_wipeout then
            close_scratch()
        end
    end

    local function finish(opts)
        opts = opts or {}

        if sent then
            return
        end

        local has_unwritten_changes = valid_buf(scratch) and vim.api.nvim_get_option_value("modified", { buf = scratch })

        if has_unwritten_changes then
            cancel(opts)
            return
        end

        local prompt = state.written_prompt

        if not prompt or prompt == trim(initial_prompt) then
            cancel(opts)
            return
        end

        if prompt == "" then
            vim.notify("Empty prompt; ask cancelled", vim.log.levels.INFO)
            cancel(opts)
            return
        end

        sent = true
        vim.api.nvim_set_option_value("modified", false, { buf = scratch })
        restore_origin(origin)

        local current_entry = state.entry or entry
        local ctx, started = M.open_terminal(current_entry.tool_name, current_entry.preset_name, {
            bufnr = context.bufnr,
            root = current_entry.root or context.root,
            focus = true,
        })

        if ctx then
            send_prompt_to_terminal(ctx, current_entry, prompt, started)
        end

        if not opts.from_wipeout then
            close_scratch()
        end
    end

    local function write_prompt()
        if sent then
            return
        end

        state.written_prompt = buffer_prompt()
        vim.api.nvim_set_option_value("modified", false, { buf = scratch })
    end

    state.cancel = cancel
    state.finish = finish
    state.write_prompt = write_prompt
    M.question_buffers[scratch] = state

    local function change_target()
        local entries = tool_shortcut_entries(context.root, { ask_only = true })

        vim.list_extend(entries, terminal_entries(context.root, 1, { ask_only = true }))

        numbered_select("Question target", entries, function(choice)
            if choice then
                state.entry = choice
                update_prompt_chrome()

                if valid_win(scratch_win) then
                    vim.api.nvim_set_current_win(scratch_win)
                end
            end
        end)
    end

    state.change_target = change_target

    local function commandline_enter()
        local line = trim(vim.fn.getcmdline())

        if line == "q" or line == "q!" or line == "quit" or line == "quit!" then
            return vim.api.nvim_replace_termcodes(
                '<C-u>lua require("markdown_pane").finish_question(' .. scratch .. ')<CR>',
                true,
                false,
                true
            )
        end

        if line == "wq" or line == "wq!" or line == "x" or line == "xit" or line == "exit" then
            return vim.api.nvim_replace_termcodes(
                '<C-u>lua require("markdown_pane").write_question(' .. scratch .. '); require("markdown_pane").finish_question(' .. scratch .. ')<CR>',
                true,
                false,
                true
            )
        end

        return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
    end

    vim.keymap.set("c", "<CR>", commandline_enter, { buffer = scratch, expr = true, silent = true })
    vim.keymap.set("n", "q", finish, { buffer = scratch, silent = true, desc = "Finish pane question" })
    vim.keymap.set("n", "M", function()
        M.change_question_target(scratch)
    end, { buffer = scratch, silent = true, desc = "Change pane question target" })
    vim.keymap.set("n", "<Tab>", function()
        M.change_question_target(scratch)
    end, { buffer = scratch, silent = true, desc = "Change pane question target" })

    vim.api.nvim_create_autocmd("BufWriteCmd", {
        group = augroup,
        buffer = scratch,
        callback = function()
            if sent then
                return
            end

            write_prompt()
            vim.notify("Question written. Quit to send.", vim.log.levels.INFO)
        end,
    })

    vim.api.nvim_create_autocmd("BufWipeout", {
        group = augroup,
        buffer = scratch,
        callback = function()
            if not sent then
                finish({ from_wipeout = true })
            end

            M.question_buffers[scratch] = nil
            pcall(vim.api.nvim_del_augroup_by_id, augroup)
        end,
    })

    vim.cmd("startinsert")
end

--- Cancel and close a question editor buffer.
function M.cancel_question(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local state = M.question_buffers[bufnr]

    if state and state.cancel then
        state.cancel()
    end
end

--- Finish a question editor, sending only after a write.
function M.finish_question(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local state = M.question_buffers[bufnr]

    if state and state.finish then
        state.finish()
    end
end

--- Mark a question editor as written and update its cached prompt.
function M.write_question(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local state = M.question_buffers[bufnr]

    if state and state.write_prompt then
        state.write_prompt()
    end
end

--- Open the target picker from inside a question editor.
function M.change_question_target(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local state = M.question_buffers[bufnr]

    if state and state.change_target then
        state.change_target()
    end
end

--- Open the ask target picker for an already-captured context.
local function open_ask_target_picker(context, origin)
    local entries = tool_shortcut_entries(context.root, { ask_only = true })

    vim.list_extend(entries, terminal_entries(context.root, 1, { ask_only = true }))

    numbered_select("Ask", entries, function(choice)
        if choice then
            M.ask_with_entry(choice, { context = context, origin = origin })
        end
    end)
end

--- Ask a specific picker entry using a captured or fresh context.
function M.ask_with_entry(entry, opts)
    opts = opts or {}

    if not entry or entry.kind ~= "terminal" then
        return
    end

    local context = opts.context or selection_context(opts)

    if not context then
        return
    end

    open_question_buffer(entry, context, opts.origin)
end

--- Capture selection and ask via the target picker.
function M.ask_picker(opts)
    opts = opts or {}

    local origin = capture_origin()
    local context = selection_context(opts)

    if not context then
        return
    end

    open_ask_target_picker(context, origin)
end

--- Ask the most recently used Codex or Claude terminal.
function M.ask_last_coding_agent(opts)
    opts = opts or {}

    local origin = capture_origin()
    local context = selection_context(opts)

    if not context then
        return
    end

    local ctx = last_coding_agent_context(context.root)

    if not ctx then
        open_ask_target_picker(context, origin)
        return
    end

    M.ask_with_entry(entry_for_terminal_context(ctx), { context = context, origin = origin })
end

--- Ask the current/default terminal for a specific coding agent.
function M.ask_current_coding_agent(tool_name, opts)
    opts = opts or {}

    if not is_coding_agent_tool(tool_name) then
        vim.notify("Unknown coding agent pane: " .. tostring(tool_name), vim.log.levels.ERROR)
        return
    end

    local origin = capture_origin()
    local context = selection_context(opts)

    if not context then
        return
    end

    local ctx = terminal_context_for_tool(tool_name, context.root)

    if not ctx then
        open_ask_target_picker(context, origin)
        return
    end

    M.ask_with_entry(entry_for_terminal_context(ctx), { context = context, origin = origin })
end

--- Ask a specific tool and optional preset.
function M.ask(tool_name, preset_name, opts)
    opts = opts or {}

    local tool = (M.config.tools or {})[tool_name]

    if not tool then
        vim.notify("Unknown pane tool: " .. tostring(tool_name), vim.log.levels.ERROR)
        return
    end

    local preset = preset_by_name(tool, preset_name)

    M.ask_with_entry({
        kind = "terminal",
        tool_name = tool_name,
        preset_name = preset.name,
        label = (tool.label or tool_name) .. ": " .. (preset.label or preset.name or "Default"),
    }, opts)
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
