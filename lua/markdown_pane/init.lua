local M = {
    winid = nil,
    bufnr = nil,
    source = nil,
    wrap_enabled = nil,
    active_mode = "markdown",
    active_terminal_key = nil,
    last_terminal_key = nil,
    last_focus_win = nil,
    zoomed = false,
    markdown_view = nil,
    terminals = {},
    question_buffers = {},
    config = {
        width = 100,
        wrap = false,
        auto_reflow = true,
        reflow_margin = 8,
        zoom_text_width = 90,
        sticky_heading = true,
        wrap_toggle_key = "<leader>mw",
        focus_on_switch = true,
        focus_on_ask = true,
        tools = {
            codex = {
                label = "Codex",
                cmd = "codex",
                include_cd_arg = true,
                send_delay_ms = 700,
                switch_command = "/model {model} {effort} {speed}",
                presets = {
                    {
                        name = "gpt55_high_fast",
                        label = "GPT-5.5 / high / fast",
                        model = "gpt-5.5",
                        effort = "high",
                        speed = "fast",
                        args = { "--model", "gpt-5.5", "-c", 'model_reasoning_effort="high"', "-c", 'service_tier="priority"' },
                    },
                    {
                        name = "gpt55_medium_fast",
                        label = "GPT-5.5 / medium / fast",
                        model = "gpt-5.5",
                        effort = "medium",
                        speed = "fast",
                        args = { "--model", "gpt-5.5", "-c", 'model_reasoning_effort="medium"', "-c", 'service_tier="priority"' },
                    },
                    {
                        name = "gpt55_xhigh_fast",
                        label = "GPT-5.5 / extra high / fast",
                        model = "gpt-5.5",
                        effort = "xhigh",
                        speed = "fast",
                        args = { "--model", "gpt-5.5", "-c", 'model_reasoning_effort="xhigh"', "-c", 'service_tier="priority"' },
                    },
                    {
                        name = "gpt55_high_normal",
                        label = "GPT-5.5 / high / normal",
                        model = "gpt-5.5",
                        effort = "high",
                        speed = "normal",
                        args = { "--model", "gpt-5.5", "-c", 'model_reasoning_effort="high"' },
                    },
                    {
                        name = "gpt55_medium_normal",
                        label = "GPT-5.5 / medium / normal",
                        model = "gpt-5.5",
                        effort = "medium",
                        speed = "normal",
                        args = { "--model", "gpt-5.5", "-c", 'model_reasoning_effort="medium"' },
                    },
                    {
                        name = "gpt55_xhigh_normal",
                        label = "GPT-5.5 / extra high / normal",
                        model = "gpt-5.5",
                        effort = "xhigh",
                        speed = "normal",
                        args = { "--model", "gpt-5.5", "-c", 'model_reasoning_effort="xhigh"' },
                    },
                    {
                        name = "gpt56_sol_high_fast",
                        label = "GPT-5.6 Sol / high / fast",
                        model = "gpt-5.6-sol",
                        effort = "high",
                        speed = "fast",
                        args = { "--model", "gpt-5.6-sol", "-c", 'model_reasoning_effort="high"', "-c", 'service_tier="priority"' },
                    },
                    {
                        name = "gpt56_sol_medium_fast",
                        label = "GPT-5.6 Sol / medium / fast",
                        model = "gpt-5.6-sol",
                        effort = "medium",
                        speed = "fast",
                        args = { "--model", "gpt-5.6-sol", "-c", 'model_reasoning_effort="medium"', "-c", 'service_tier="priority"' },
                    },
                    {
                        name = "gpt56_sol_xhigh_fast",
                        label = "GPT-5.6 Sol / extra high / fast",
                        model = "gpt-5.6-sol",
                        effort = "xhigh",
                        speed = "fast",
                        args = { "--model", "gpt-5.6-sol", "-c", 'model_reasoning_effort="xhigh"', "-c", 'service_tier="priority"' },
                    },
                    {
                        name = "gpt56_sol_high_normal",
                        label = "GPT-5.6 Sol / high / normal",
                        model = "gpt-5.6-sol",
                        effort = "high",
                        speed = "normal",
                        args = { "--model", "gpt-5.6-sol", "-c", 'model_reasoning_effort="high"' },
                    },
                    {
                        name = "gpt56_sol_medium_normal",
                        label = "GPT-5.6 Sol / medium / normal",
                        model = "gpt-5.6-sol",
                        effort = "medium",
                        speed = "normal",
                        args = { "--model", "gpt-5.6-sol", "-c", 'model_reasoning_effort="medium"' },
                    },
                    {
                        name = "gpt56_sol_xhigh_normal",
                        label = "GPT-5.6 Sol / extra high / normal",
                        model = "gpt-5.6-sol",
                        effort = "xhigh",
                        speed = "normal",
                        args = { "--model", "gpt-5.6-sol", "-c", 'model_reasoning_effort="xhigh"' },
                    },
                },
            },
            claude = {
                label = "Claude",
                cmd = "claude",
                send_delay_ms = 700,
                switch_command = "/model {model} {effort}",
                presets = {
                    {
                        name = "sonnet",
                        label = "Sonnet / normal",
                        model = "sonnet",
                        effort = "medium",
                        args = { "--model", "sonnet", "--effort", "medium" },
                    },
                    {
                        name = "sonnet_high",
                        label = "Sonnet / high",
                        model = "sonnet",
                        effort = "high",
                        args = { "--model", "sonnet", "--effort", "high" },
                    },
                    {
                        name = "opus_high",
                        label = "Opus / high",
                        model = "opus",
                        effort = "high",
                        args = { "--model", "opus", "--effort", "high" },
                    },
                    {
                        name = "fable_high",
                        label = "Fable / high",
                        model = "fable",
                        effort = "high",
                        args = { "--model", "fable", "--effort", "high" },
                    },
                    {
                        name = "default",
                        label = "Default",
                        args = {},
                    },
                },
            },
        },
    },
}

local sticky_heading_group = vim.api.nvim_create_augroup("MarkdownPaneStickyHeading", { clear = true })

local function trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function valid_win(winid)
    return winid and vim.api.nvim_win_is_valid(winid)
end

local function valid_buf(bufnr)
    return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function is_running(job_id)
    return job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1
end

local function resolve_path(path)
    if not path or path == "" then
        return nil
    end

    local expanded = vim.fn.expand(path)

    if expanded == "" then
        expanded = path
    end

    return vim.fn.fnamemodify(expanded, ":p")
end

local function project_root(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local ok, root

    if vim.fs and vim.fs.root then
        ok, root = pcall(vim.fs.root, bufnr, { ".git" })

        if ok and root then
            return vim.fn.fnamemodify(root, ":p")
        end
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    local start = name ~= "" and vim.fn.fnamemodify(name, ":p:h") or vim.fn.getcwd()

    if vim.fs and vim.fs.find then
        local found = vim.fs.find(".git", { path = start, upward = true })[1]

        if found then
            return vim.fn.fnamemodify(found, ":p:h")
        end
    end

    return vim.fn.fnamemodify(start, ":p")
end

local function project_root_for_path(path)
    if not path or path == "" then
        return project_root()
    end

    local start = vim.fn.fnamemodify(path, ":p:h")

    if vim.fs and vim.fs.find then
        local found = vim.fs.find(".git", { path = start, upward = true })[1]

        if found then
            return vim.fn.fnamemodify(found, ":p:h")
        end
    end

    return vim.fn.fnamemodify(start, ":p")
end

local function relative_path(path, root)
    if not path or path == "" then
        return "[No file name]"
    end

    path = vim.fn.fnamemodify(path, ":p")
    root = root and vim.fn.fnamemodify(root, ":p") or nil

    if root and vim.startswith(path, root) then
        return path:sub(#root + 1)
    end

    return vim.fn.fnamemodify(path, ":.")
end

local function root_label(root)
    local normalized = vim.fn.fnamemodify(root or vim.fn.getcwd(), ":p"):gsub("/$", "")

    return vim.fn.fnamemodify(normalized, ":t")
end

local function terminal_key(tool_name, root)
    return table.concat({
        tool_name,
        vim.fn.fnamemodify(root or vim.fn.getcwd(), ":p"),
    }, "::")
end

local function terminal_context_for_buf(bufnr)
    for _, ctx in pairs(M.terminals) do
        if ctx.bufnr == bufnr then
            return ctx
        end
    end

    return nil
end

local function sanitize_name(text)
    return (text or ""):gsub("[^%w_.-]", "_")
end

local function command_list(tool, preset, root)
    local cmd = tool.cmd or tool.command
    local result = type(cmd) == "table" and vim.deepcopy(cmd) or { cmd }

    if tool.include_cd_arg then
        vim.list_extend(result, { "--cd", root })
    end

    vim.list_extend(result, vim.deepcopy(tool.args or {}))
    vim.list_extend(result, vim.deepcopy(preset.args or {}))

    return result
end

local function executable_exists(cmd)
    return cmd and cmd ~= "" and (cmd:find("/") or vim.fn.executable(cmd) == 1)
end

local function fence_for(text)
    local fence = "```"

    while text:find(fence, 1, true) do
        fence = fence .. "`"
    end

    return fence
end

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

local function preferred_wrap()
    if M.wrap_enabled == nil then
        return M.config.wrap
    end

    return M.wrap_enabled
end

local function effective_wrap()
    return preferred_wrap()
end

local function pane_width()
    if not M.zoomed then
        return M.config.width
    end

    local reserved = math.max(1, tonumber(vim.o.winminwidth) or 1)
    local separator = 1
    local max_width = vim.o.columns - reserved - separator

    return math.max(M.config.width, max_width)
end

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

local function statusline_escape(text)
    return text:gsub("%%", "%%%%")
end

local function truncate_display(text, max_width)
    if vim.fn.strdisplaywidth(text) <= max_width then
        return text
    end

    local ellipsis = "..."
    local chars = vim.fn.strchars(text)

    while chars > 0 do
        local candidate = vim.fn.strcharpart(text, 0, chars) .. ellipsis

        if vim.fn.strdisplaywidth(candidate) <= max_width then
            return candidate
        end

        chars = chars - 1
    end

    return ellipsis
end

local function atx_heading(line)
    local markers, title = line:match("^%s*(#+)%s+(.+)%s*$")

    if not markers or #markers > 6 then
        return nil
    end

    title = trim(title:gsub("%s+#+%s*$", ""))

    if title == "" then
        return nil
    end

    return #markers, title
end

local function setext_heading(title_line, underline_line)
    if not underline_line then
        return nil
    end

    local marker = underline_line:match("^%s*(=+)%s*$")

    if marker then
        marker = "="
    else
        marker = underline_line:match("^%s*(-+)%s*$") and "-"
    end

    if not marker then
        return nil
    end

    local title = trim(title_line)

    if title == "" then
        return nil
    end

    return marker == "=" and 1 or 2, title
end

local function active_heading(winid)
    if not valid_win(winid) then
        return nil
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local topline = vim.api.nvim_win_call(winid, function()
        return vim.fn.line("w0")
    end)
    local last_needed = math.min(line_count, topline + 1)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, last_needed, false)

    for index = math.min(topline, #lines), 1, -1 do
        local level, title = atx_heading(lines[index])

        if level then
            return level, title
        end

        level, title = setext_heading(lines[index], lines[index + 1])

        if level then
            return level, title
        end

        if index > 1 then
            level, title = setext_heading(lines[index - 1], lines[index])

            if level then
                return level, title
            end
        end
    end

    return nil
end

local function terminal_winbar_title()
    local ctx = M.active_terminal_key and M.terminals[M.active_terminal_key] or nil

    if not ctx then
        return "Pane"
    end

    return ctx.tool_label .. ": " .. ctx.preset_label .. " - " .. root_label(ctx.root)
end

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

render_markview = function(bufnr)
    local ok, markview = pcall(require, "markview")

    if not ok then
        return
    end

    pcall(markview.clear, bufnr)
    pcall(markview.render, bufnr, { enable = true, hybrid_mode = false })
end

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
        notify = opts.notify == true,
    })
    vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
    vim.api.nvim_set_option_value("readonly", readonly, { buf = bufnr })
    vim.api.nvim_set_option_value("modifiable", modifiable, { buf = bufnr })
end

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

setup_pane_maps = function(bufnr)
    local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, {
            buffer = bufnr,
            desc = desc,
            silent = true,
        })
    end

    map("<leader>gg", function()
        M.toggle_markdown_agent()
    end, "Toggle markdown/agent pane")

    map("<C-g>", function()
        M.toggle_markdown_agent()
    end, "Toggle markdown/agent pane")

    if bufnr == M.bufnr then
        map(M.config.wrap_toggle_key, function()
            M.toggle_wrap()
        end, "Toggle markdown pane wrap")
    end
end

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

function M.toggle_wrap()
    M.wrap_enabled = not preferred_wrap()
    apply_wrap_state()
end

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
        M.last_terminal_key = M.active_terminal_key
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

function M.close()
    if valid_win(M.winid) then
        if M.active_mode == "markdown" then
            save_markdown_view()
        end

        vim.api.nvim_win_close(M.winid, true)
    end

    M.winid = nil
end

function M.toggle(path)
    if path and path ~= "" then
        M.open(path)
    elseif valid_win(M.winid) then
        M.close()
    else
        M.open(M.source)
    end
end

function M.is_open()
    return valid_win(M.winid)
end

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

function M.toggle_zoom()
    M.zoomed = not M.zoomed

    if not valid_win(M.winid) then
        return
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
    vim.notify("Pane zoom " .. (M.zoomed and "on" or "off"), vim.log.levels.INFO)
end

function M.text_width()
    return pane_text_width()
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

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

local function ordered_tool_names()
    local tools = M.config.tools or {}
    local names = {}
    local seen = {}

    for _, name in ipairs({ "codex", "claude" }) do
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

local function current_or_default_entry(tool_name, root, key)
    local tool = (M.config.tools or {})[tool_name]

    if not tool then
        return nil
    end

    local terminal_ctx = root and M.terminals[terminal_key(tool_name, root)] or nil
    local preset = terminal_ctx and preset_by_name(tool, terminal_ctx.preset_name) or preset_by_name(tool)

    return {
        kind = "terminal",
        shortcut = true,
        tool_name = tool_name,
        preset_name = preset.name,
        key = key,
        label = (tool.label or tool_name) .. " current: " .. (preset.label or preset.name or "Default"),
        running = terminal_ctx and valid_buf(terminal_ctx.bufnr) and is_running(terminal_ctx.job_id),
        current = terminal_ctx ~= nil,
        active = terminal_ctx and M.active_terminal_key == terminal_ctx.key,
    }
end

local function tool_shortcut_entries(root)
    local entries = {}
    local codex = current_or_default_entry("codex", root, "x")
    local claude = current_or_default_entry("claude", root, "c")

    if codex then
        table.insert(entries, codex)
    end

    if claude then
        table.insert(entries, claude)
    end

    return entries
end

local function terminal_entries(root, start_index)
    local entries = {}
    local index = start_index or 1

    for _, tool_name in ipairs(ordered_tool_names()) do
        local tool = M.config.tools[tool_name]

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

    for _, entry in ipairs(entries) do
        entry.index = index
        entry.key = tostring(index)

        if root then
            local key = terminal_key(entry.tool_name, root)
            local ctx = M.terminals[key]

            entry.terminal_key = key
            entry.running = ctx and valid_buf(ctx.bufnr) and is_running(ctx.job_id)
            entry.current = entry.running and ctx.preset_name == entry.preset_name
            entry.active = entry.running and M.active_terminal_key == key
        end

        index = index + 1
    end

    return entries
end

local function numbered_select(prompt, entries, callback)
    if #entries == 0 then
        return
    end

    local width = math.max(40, vim.fn.strdisplaywidth(prompt) + 4)
    local lines = { prompt }
    local active_lines = {}

    for i, entry in ipairs(entries) do
        local prefix = entry.current and "* " or "  "
        local suffix = ""

        if entry.current and entry.active then
            suffix = "  [current session]"
        elseif entry.current then
            suffix = "  [current]"
        elseif entry.running then
            suffix = "  [session]"
        end

        local line = string.format("%s  %s%s%s", entry.key or tostring(entry.index), prefix, entry.label, suffix)

        width = math.max(width, vim.fn.strdisplaywidth(line) + 4)
        table.insert(lines, line)

        if entry.current and not entry.shortcut then
            table.insert(active_lines, #lines - 1)
        end

        if entry.shortcut and entries[i + 1] and not entries[i + 1].shortcut then
            table.insert(lines, "")
        end
    end

    width = math.min(width, math.max(40, vim.o.columns - 8))

    local bufnr = vim.api.nvim_create_buf(false, true)
    local height = #lines
    local winid = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        width = width,
        height = height,
        style = "minimal",
        border = "single",
    })

    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
    vim.api.nvim_buf_add_highlight(bufnr, -1, "Title", 0, 0, -1)

    for _, line_index in ipairs(active_lines) do
        vim.api.nvim_buf_add_highlight(bufnr, -1, "Search", line_index, 0, -1)
    end

    local function close()
        if valid_win(winid) then
            vim.api.nvim_win_close(winid, true)
        end
    end

    local by_key = {}

    for _, entry in ipairs(entries) do
        by_key[entry.key or tostring(entry.index)] = entry
    end

    local function key_state(prefix)
        local exact = by_key[prefix]
        local has_prefix = false
        local has_longer = false

        for key in pairs(by_key) do
            if vim.startswith(key, prefix) then
                has_prefix = true

                if #key > #prefix then
                    has_longer = true
                end
            end
        end

        return exact, has_prefix, has_longer
    end

    local function read_choice()
        local typed = ""

        while true do
            local char = vim.fn.getcharstr()

            if char == "\27" or char == "q" then
                return nil
            end

            typed = typed .. char

            local exact, has_prefix, has_longer = key_state(typed)

            if exact and not has_longer then
                return exact
            end

            if exact and has_longer then
                for _ = 1, 30 do
                    local next_char = vim.fn.getcharstr(0)

                    if next_char and next_char ~= "" then
                        typed = typed .. next_char
                        exact, has_prefix, has_longer = key_state(typed)

                        if exact and not has_longer then
                            return exact
                        end

                        break
                    end

                    vim.cmd("sleep 10m")
                end

                exact = key_state(typed)

                if exact then
                    return exact
                end
            end

            if not has_prefix then
                return nil
            end
        end
    end

    vim.cmd("redraw")

    local choice

    if M._test_next_choice then
        choice = by_key[tostring(M._test_next_choice)]
        M._test_next_choice = nil
    else
        choice = read_choice()
    end

    close()

    if choice then
        callback(choice)
    end
end

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
    M.last_terminal_key = key
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
    M.last_terminal_key = ctx.key
    setup_pane_maps(ctx.bufnr)
    ensure_win(ctx.bufnr, "terminal", { focus = opts.focus == nil and M.config.focus_on_switch or opts.focus })
    update_sticky_heading()

    return ctx, started
end

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

function M.toggle_markdown_agent()
    if M.active_mode == "markdown" then
        M.show_last_agent({ focus = true })
    else
        M.show_markdown()
    end
end

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
    vim.list_extend(entries, terminal_entries(root, 1))

    numbered_select("Switch pane", entries, function(choice)
        if choice then
            M.switch(choice)
        end
    end)
end

local function selection_from_visual(bufnr)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_lnum = start_pos[2]
    local start_col = start_pos[3]
    local end_lnum = end_pos[2]
    local end_col = end_pos[3]

    if start_lnum == 0 or end_lnum == 0 then
        return nil
    end

    if start_lnum > end_lnum or (start_lnum == end_lnum and start_col > end_col) then
        start_lnum, end_lnum = end_lnum, start_lnum
        start_col, end_col = end_col, start_col
    end

    local lines = vim.api.nvim_buf_get_text(bufnr, start_lnum - 1, start_col - 1, end_lnum - 1, end_col, {})

    return {
        text = table.concat(lines, "\n"),
        start_lnum = start_lnum,
        end_lnum = end_lnum,
    }
end

local function selection_from_range(bufnr, line1, line2)
    line1 = line1 or vim.fn.line(".")
    line2 = line2 or line1

    if line1 > line2 then
        line1, line2 = line2, line1
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)

    return {
        text = table.concat(lines, "\n"),
        start_lnum = line1,
        end_lnum = line2,
    }
end

local function markdown_fence_language(bufnr, line)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line, false)
    local open_fence = nil
    local language = nil

    for index = 1, #lines do
        local marker, info = lines[index]:match("^%s*(```+)%s*(.-)%s*$")

        if not marker then
            marker, info = lines[index]:match("^%s*(~~~+)%s*(.-)%s*$")
        end

        if marker then
            if open_fence and marker:sub(1, 1) == open_fence:sub(1, 1) and #marker >= #open_fence then
                open_fence = nil
                language = nil
            else
                open_fence = marker
                info = trim(info or "")

                if info ~= "" then
                    language = info:match("^([^%s,{]+)")
                else
                    language = nil
                end
            end
        end
    end

    return open_fence and language or nil
end

local function selection_context(opts)
    opts = opts or {}

    local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
    local selection = opts.visual and selection_from_visual(bufnr) or selection_from_range(bufnr, opts.line1, opts.line2)

    if not selection or selection.text == "" then
        vim.notify("No selection to send", vim.log.levels.WARN)
        return nil
    end

    local terminal_ctx = terminal_context_for_buf(bufnr)
    local markdown_source = bufnr == M.bufnr and M.source or nil
    local root = terminal_ctx and terminal_ctx.root or (markdown_source and project_root_for_path(markdown_source) or project_root(bufnr))
    local path = markdown_source or vim.api.nvim_buf_get_name(bufnr)

    selection.bufnr = bufnr
    selection.root = root
    selection.file = terminal_ctx and ("Terminal: " .. terminal_ctx.tool_label .. " / " .. terminal_ctx.preset_label) or relative_path(path, root)
    selection.filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    selection.snippet_filetype = selection.filetype

    if selection.filetype == "markdown" then
        selection.snippet_filetype = markdown_fence_language(bufnr, selection.start_lnum) or selection.filetype
    end

    return selection
end

local function format_prompt(context, question)
    local filetype = context.snippet_filetype ~= "" and context.snippet_filetype or nil
    local fence = fence_for(context.text)

    return table.concat({
        "Question:",
        question,
        "",
        "File:",
        context.file,
        "",
        "Selection:",
        "lines " .. context.start_lnum .. "-" .. context.end_lnum,
        "",
        fence .. (filetype and filetype or ""),
        context.text,
        fence,
    }, "\n")
end

local function prompt_template(context)
    return format_prompt(context, "")
end

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
        local entries = tool_shortcut_entries(context.root)

        vim.list_extend(entries, terminal_entries(context.root, 1))

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

function M.cancel_question(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local state = M.question_buffers[bufnr]

    if state and state.cancel then
        state.cancel()
    end
end

function M.finish_question(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local state = M.question_buffers[bufnr]

    if state and state.finish then
        state.finish()
    end
end

function M.write_question(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local state = M.question_buffers[bufnr]

    if state and state.write_prompt then
        state.write_prompt()
    end
end

function M.change_question_target(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local state = M.question_buffers[bufnr]

    if state and state.change_target then
        state.change_target()
    end
end

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

function M.ask_picker(opts)
    opts = opts or {}

    local origin = capture_origin()
    local context = selection_context(opts)

    if not context then
        return
    end

    local entries = tool_shortcut_entries(context.root)

    vim.list_extend(entries, terminal_entries(context.root, 1))

    numbered_select("Ask", entries, function(choice)
        if choice then
            M.ask_with_entry(choice, { context = context, origin = origin })
        end
    end)
end

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
