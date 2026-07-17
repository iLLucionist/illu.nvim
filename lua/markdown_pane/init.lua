local M = {
    winid = nil,
    bufnr = nil,
    source = nil,
    wrap_enabled = nil,
    config = {
        width = 100,
        wrap = false,
        auto_reflow = true,
        reflow_margin = 8,
        sticky_heading = true,
        wrap_toggle_key = "<leader>mw",
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

local function pane_text_width(winid)
    winid = winid or M.winid

    if not valid_win(winid) then
        return nil
    end

    local width = vim.api.nvim_win_get_width(winid)

    if vim.api.nvim_get_option_value("number", { win = winid }) then
        width = width - vim.api.nvim_get_option_value("numberwidth", { win = winid })
    end

    return math.max(20, width - M.config.reflow_margin)
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

local function update_sticky_heading()
    if not valid_win(M.winid) then
        return
    end

    if not M.config.sticky_heading then
        vim.api.nvim_set_option_value("winbar", "", { win = M.winid })
        return
    end

    local level, title = active_heading(M.winid)

    if not title then
        title = M.source and vim.fn.fnamemodify(M.source, ":t") or "Markdown Pane"
    else
        title = string.rep("#", level) .. " " .. title
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

local function set_window_options(winid)
    local wrap = effective_wrap()

    vim.api.nvim_set_option_value("winfixwidth", true, { win = winid })
    vim.api.nvim_set_option_value("number", true, { win = winid })
    vim.api.nvim_set_option_value("relativenumber", false, { win = winid })
    vim.api.nvim_set_option_value("wrap", wrap, { win = winid })
    vim.api.nvim_set_option_value("linebreak", wrap, { win = winid })
    vim.api.nvim_set_option_value("breakindent", wrap, { win = winid })
    vim.api.nvim_set_option_value("showbreak", "  ", { win = winid })
    vim.api.nvim_set_option_value("cursorline", true, { win = winid })
    vim.api.nvim_set_option_value("signcolumn", "no", { win = winid })
    vim.api.nvim_set_option_value("foldcolumn", "0", { win = winid })
    vim.api.nvim_set_option_value("colorcolumn", "", { win = winid })
    vim.api.nvim_set_option_value("conceallevel", 3, { win = winid })
    vim.api.nvim_set_option_value("concealcursor", "nvic", { win = winid })
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

local function setup_buffer_maps(bufnr)
    vim.keymap.set("n", M.config.wrap_toggle_key, function()
        M.toggle_wrap()
    end, {
        buffer = bufnr,
        desc = "Toggle markdown pane wrap",
        silent = true,
    })
end

local function ensure_win()
    if valid_win(M.winid) then
        set_window_options(M.winid)
        return M.winid
    end

    local previous = vim.api.nvim_get_current_win()
    local bufnr = ensure_buf()

    vim.cmd("botright vertical " .. M.config.width .. "split")
    M.winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.winid, bufnr)
    vim.api.nvim_win_set_width(M.winid, M.config.width)
    set_window_options(M.winid)
    update_sticky_heading()
    render_markview(bufnr)

    if valid_win(previous) then
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

    if M.config.auto_reflow then
        local ok, markdown_reflow = pcall(require, "markdown_reflow")

        if ok then
            markdown_reflow.reflow_buffer(bufnr, {
                width = pane_text_width(),
                force = true,
                notify = false,
            })
        end
    end

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
    local winid = ensure_win()

    if not load_file(path) then
        return
    end

    set_window_options(winid)
    update_sticky_heading()
    render_markview(M.bufnr)

    vim.api.nvim_win_call(winid, function()
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        vim.cmd("normal! zt")
    end)
    setup_buffer_maps(M.bufnr)

    if valid_win(previous) then
        vim.api.nvim_set_current_win(previous)
    end
end

function M.close()
    if valid_win(M.winid) then
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
    return valid_win(M.winid) and valid_buf(M.bufnr)
end

function M.text_width()
    return pane_text_width()
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
