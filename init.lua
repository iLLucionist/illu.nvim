-- For reference: https://github.com/neovim/neovim/blob/master/src/nvim/options.lua
-- lazy.nvim reference: https://github.com/folke/lazy.nvim
-- mason-lspconfig: https://github.com/williamboman/mason-lspconfig.nvim

vim.g.mapleader = " "

-- Disable netrw in favor of nvim tree later on

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPllugin = 1

local set = vim.opt
local map = vim.keymap.set
local cmd = vim.cmd
local config_file = debug.getinfo(1, "S").source:sub(2)
local config_dir = vim.fn.fnamemodify(vim.loop.fs_realpath(config_file) or config_file, ":p:h")

-- Init package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Colorscheme
    "ellisonleao/gruvbox.nvim",
    "folke/tokyonight.nvim",
    "Mofiqul/vscode.nvim",
    "projekt0n/github-nvim-theme",
    { "catppuccin/nvim", name="catppuccin"},
    { "EdenEast/nightfox.nvim" },
    -- Statusline / Tabline
    "nvim-lualine/lualine.nvim",
    "nvim-tree/nvim-web-devicons",
    "lewis6991/gitsigns.nvim",
    "romgrk/barbar.nvim",
    -- LSP
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lsp",
    "neovim/nvim-lspconfig",
    "DNLHC/glance.nvim",
    "folke/trouble.nvim",
    "cuducos/yaml.nvim",
    -- Treesitter
    {
        "neovim-treesitter/nvim-treesitter",
        dependencies = {
            "neovim-treesitter/treesitter-parser-registry",
        },
        lazy = false,
        build = ":TSUpdate"
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        lazy = false
    },
    -- Motion
    "https://codeberg.org/andyg/leap.nvim",
    -- Fuzzy finding
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "nvim-telescope/telescope-project.nvim",
    -- harpoon is just buggy atm, disabled
    -- {
    --     "ThePrimeagen/harpoon",
    --     branch = "harpoon2"
    -- },
    -- Completion
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    {
        "hrsh7th/nvim-cmp",
        commit = "b356f2c"
    },
    -- git
    "kdheepak/lazygit.nvim",
    -- Navigation
    "stevearc/aerial.nvim",
    "nvim-tree/nvim-tree.lua",
    -- Editing
    "windwp/nvim-autopairs",
    "windwp/nvim-ts-autotag",
    "numToStr/Comment.nvim",
    "kylechui/nvim-surround",
    -- Language specific
    "rafaelsq/nvim-goc.lua",
    {
        "ray-x/go.nvim",
        -- install required binaries
        build=':lua require("go.install).update_all_sync()',
        ft = {"go", "gomod"}
    },
    {
        "mrcjkb/rustaceanvim",
        version = "^5",
        lazy = false,
    },
    "R-nvim/R.nvim",
    -- Databases
    "tpope/vim-dadbod",
    "kristijanhusak/vim-dadbod-ui",
    -- Toggle diagnostics
    -- "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
    -- REPL
    "hkupty/iron.nvim",
    "nyngwang/NeoZoom.lua",
    -- TAILWIND
    "luckasRanarison/tailwind-tools.nvim",
    -- Markdown
    {
        "OXY2DEV/markview.nvim",
        lazy = false,
        opts = {
            markdown = {
                block_quotes = { wrap = false },
                headings = { org_indent_wrap = false },
                list_items = { wrap = false },
            },
        },
    }
})
set.rtp:prepend(config_dir)

-- Essential key mappings
map('n', '<Cr>', 'i', { silent = true })
map('i', 'jk', '<Esc>', { silent = true })
map('i', 'kj', '<Esc>', { silent = true })
map('n', '<leader>ww', ':w<Cr>', { silent = true })
map('n', '<leader>qq', ':q<Cr>', { silent = true })
map('n', '<leader>Q', ':q!<Cr>', { silent = true })
map('n', '<leader>wj', ':split<Cr>', { silent = true })
map('n', '<leader>wk', ':vsplit<Cr>', { silent = true })
map('n', '<C-h>', '<C-w>h', { silent = true })
map('n', '<C-j>', '<C-w>j', { silent = true })
map('n', '<C-k>', '<C-w>k', { silent = true })
map('n', '<C-l>', '<C-w>l', { silent = true })
map('n', '<leader>tt', ':tabnew<Cr>', { silent = true })
map('n', '<leader>tl', ':tabnext<Cr>', { silent = true })
map('n', '<leader>th', ':tabprev<Cr>', { silent = true })
map('n', '<leader>uu', ':Lazy update<Cr>', { silent = true })
-- Move line up / down
map('n', '<leader>k', 'ddkP', { silent = true })
map('n', '<leader>j', 'ddp', { silent = true })
-- Add blank line above / below
map('n', '<leader>O', 'O<Esc>', { silent = true })
map('n', '<leader>o', 'o<Esc>', { silent = true })
-- Open terminal
map('n', '<leader>ot', ':vsplit | terminal<CR>', { silent = true })
map('n', '<leader>ht', ':split | terminal<CR>', { silent = true })
map("n", "<leader>tj", "<cmd>belowright split | terminal<cr>")
map("n", "<leader>tsj", function()
    local height = math.floor(vim.o.lines * 0.33)
    vim.cmd("belowright" .. height .. "split | terminal")
    vim.cmd("startinsert")
end)




-- Sane defaults
set.autoread = true
set.nu = true
set.ruler = true
set.showmatch = true
set.mouse = "a"
set.cursorline = true
set.wildmenu = true
set.timeoutlen = 500
set.updatetime = 300
set.splitright = true
set.signcolumn = "yes"
set.backspace = "indent,eol,start"
set.colorcolumn = "+1"
set.encoding = "UTF-8"

-- Swapping
set.swapfile = true
set.backup = false
set.writebackup = false
set.backupcopy = "yes"

-- Tabs and spaces
set.smartindent = true
set.tabstop = 4
set.shiftwidth = 4
set.expandtab = true
set.softtabstop = 4
set.textwidth = 80

-- Search
set.ignorecase = true
set.smartcase = true
set.infercase = true
set.incsearch = true
set.hlsearch = true
set.wrapscan = true
set.showmatch = true
set.matchtime = 1
set.matchpairs:append("<:>")
set.wildignore:append("*.so,*~,*/.git/*,*/.DS_Store,*/tmp/*")

-- Scrolling
set.scrolloff = 8
set.sidescrolloff = 15
set.sidescroll = 1

-- Markview can only fully render wide tables when soft wrapping is disabled.
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt_local.wrap = false
    end,
})

-- Relative line numbers
vim.wo.relativenumber = true

-- Color
vim.g.illuColor = 'dark'
vim.opt.termguicolors = true

local function blend_hex(color, target, alpha)
    local r = math.floor(color / 0x10000) % 0x100
    local g = math.floor(color / 0x100) % 0x100
    local b = color % 0x100
    local tr = math.floor(target / 0x10000) % 0x100
    local tg = math.floor(target / 0x100) % 0x100
    local tb = target % 0x100

    return string.format(
        "#%02x%02x%02x",
        math.floor(r + (tr - r) * alpha + 0.5),
        math.floor(g + (tg - g) * alpha + 0.5),
        math.floor(b + (tb - b) * alpha + 0.5)
    )
end

local function set_markview_code_highlights()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })

    if not normal.bg then
        return
    end

    local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
    local raw = vim.api.nvim_get_hl(0, { name = "@markup.raw", link = false })
    local target = vim.o.background == "dark" and 0xffffff or 0x000000
    local code_bg = blend_hex(normal.bg, target, vim.o.background == "dark" and 0.08 or 0.06)
    local inline_bg = blend_hex(normal.bg, target, vim.o.background == "dark" and 0.12 or 0.06)

    vim.api.nvim_set_hl(0, "MarkviewCode", { bg = code_bg })
    vim.api.nvim_set_hl(0, "MarkviewCodeInfo", { bg = code_bg, fg = comment.fg })
    vim.api.nvim_set_hl(0, "MarkviewCodeFg", { fg = code_bg })
    vim.api.nvim_set_hl(0, "MarkviewInlineCode", { bg = inline_bg, fg = raw.fg or normal.fg })
end

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = set_markview_code_highlights,
})

-- vim.opt.guicursor = ""
-- require("tokyonight").setup({
--     terminal_colors = true,
--     styles = {
--         -- comments = { fg = "#6e7596" }
--         comments = { fg = "#7b83a6" },
--     },
--     day_brightness = 0.2,
--     on_colors = function(colors)
--         colors.fg_gutter = colors.dark3
--     end
-- })


-- cmd("/colorscheme tokyonight-night")
-- cmd("colorscheme tokyonight-day")
-- cmd("colorscheme tokyonight-night")
-- xs
cmd("colorscheme tokyonight-night")
set_markview_code_highlights()



function ToggleColor()
    local themes = {
        light = {
            cursor_normal = { fg = "#ffffff", bg = "#808080"},
            cursor_insert = { fg = "#ffffff", bg = "#808080"},
            cursor_terminal = { fg = "#ffffff", bg = "#ff0000"},
        },
        dark = {
            cursor_normal = { fg = "#000000", bg = "#ffcc00"},
            cursor_insert = { fg = "#000000", bg = "#ffcc00"},
            cursor_terminal = { fg = "#ffffff", bg = "#ff0000"},
        },
    }
    if vim.g.illuColor == 'light' then
        vim.g.illuColor = 'dark'
        set.background = "dark"
        cmd("colorscheme tokyonight-night")
        cmd("mode")
        vim.api.nvim_set_hl(0, "CursorNormal", themes.dark.cursor_normal)
        vim.api.nvim_set_hl(0, "CursorInsert", themes.dark.cursor_insert)
        vim.api.nvim_set_hl(0, "CursorTerminal", themes.dark.cursor_terminal)
        vim.opt.guicursor = "n:block-CursorNormal,t:block-CursorTerminal"
    else
        vim.g.illuColor = 'light'
        set.background = "light"
        cmd("colorscheme dayfox")
        cmd("mode")
        vim.api.nvim_set_hl(0, "CursorNormal", themes.light.cursor_normal)
        vim.api.nvim_set_hl(0, "CursorInsert", themes.light.cursor_insert)
        vim.api.nvim_set_hl(0, "CursorTerminal", themes.dark.cursor_terminal)
        vim.opt.guicursor = "n:block-CursorNormal,t:block-CursorTerminal"
    end
end

map('n', '<leader>cc', '<cmd>lua ToggleColor()<CR>', {})

-- Statusline
require("lualine").setup()

-- Bufferline
require("barbar").setup({
    exclude_name = { "Markdown Pane" },
    icons = {
        buffer_index = true,
    },
})

map("n", "<S-h>", "<cmd>BufferPrevious<CR>", { silent = true })
map("n", "<S-l>", "<cmd>BufferNext<CR>", { silent = true })
map("n", "<leader>bp", "<cmd>BufferPick<CR>", { silent = true })
map("n", "<leader>bq", "<cmd>BufferClose<CR>", { silent = true })

for i = 1, 9 do
    map("n", "<leader>" .. i, "<cmd>BufferGoto " .. i .. "<CR>", { silent = true })
end

map("n", "<leader>0", "<cmd>BufferLast<CR>", { silent = true })


-- Fuzzy finding
local builtin = require('telescope.builtin')
map('n', '<leader>ff', builtin.find_files, {})
map('n', '<leader>fg', builtin.live_grep, {})
map('n', '<leader>fd', builtin.buffers, {})
map('n', '<leader>fh', builtin.help_tags, {})
map('n', '<leader>fp', function() require'telescope'.extensions.project.project{} end, {})

local function markdown_headings()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local entry_display = require("telescope.pickers.entry_display")
    local previewers = require("telescope.previewers")
    local preview_utils = require("telescope.previewers.utils")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local markdown_pane = require("markdown_pane")
    local headings = {}
    local origin_win = vim.api.nvim_get_current_win()
    local pane_visible = markdown_pane.is_open()
    local bufnr = pane_visible and markdown_pane.bufnr or vim.api.nvim_get_current_buf()
    local target_win = pane_visible and markdown_pane.winid or origin_win
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")

    if not ok or not parser then
        vim.notify("No markdown parser available", vim.log.levels.WARN)
        return
    end

    local function heading_level(node)
        for child in node:iter_children() do
            local node_type = child:type()

            if node_type:match("^atx_h%d_marker$") then
                return tonumber(node_type:match("%d")) or 1
            elseif node_type == "setext_h1_underline" then
                return 1
            elseif node_type == "setext_h2_underline" then
                return 2
            end
        end

        return 1
    end

    local function clean_heading_title(text)
        text = text:gsub("%s+", " ")
        text = text:gsub("^%s+", "")
        text = text:gsub("%s+#+%s*$", "")
        text = text:gsub("%s+$", "")

        return text
    end

    local heading_icons = {
        [1] = "󰉫",
        [2] = "󰉬",
        [3] = "󰉭",
        [4] = "󰉮",
        [5] = "󰉯",
        [6] = "󰉰",
    }

    local function visit(node)
        local node_type = node:type()

        if node_type == "atx_heading" or node_type == "setext_heading" then
            local content = node:field("heading_content")[1]

            if content then
                local start_row = node:range()
                local title = clean_heading_title(vim.treesitter.get_node_text(content, bufnr))

                table.insert(headings, {
                    lnum = start_row + 1,
                    level = heading_level(node),
                    title = title,
                })
            end
        end

        for child in node:iter_children() do
            visit(child)
        end
    end

    for _, tree in ipairs(parser:parse()) do
        visit(tree:root())
    end

    table.sort(headings, function(a, b)
        return a.lnum < b.lnum
    end)

    if vim.tbl_isempty(headings) then
        vim.notify("No markdown headings found", vim.log.levels.INFO)
        return
    end

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = 4 },
            { width = 2 },
            { remaining = true },
        },
    })

    pickers.new({}, {
        prompt_title = "Markdown Headings",
        finder = finders.new_table({
            results = headings,
            entry_maker = function(entry)
                local indent = string.rep("  ", entry.level - 1)
                local icon = heading_icons[entry.level] or "󰉫"

                return {
                    value = entry,
                    ordinal = string.format("%d %s", entry.lnum, entry.title),
                    display = function()
                        return displayer({
                            { string.format("%4d", entry.lnum), "LineNr" },
                            { icon, "MarkviewHeading" .. entry.level },
                            indent .. entry.title,
                        })
                    end,
                    lnum = entry.lnum,
                }
            end,
        }),
        previewer = previewers.new_buffer_previewer({
            title = "Markdown preview",
            get_buffer_by_name = function()
                return "markdown_headings_" .. tostring(bufnr)
            end,
            define_preview = function(self, entry)
                if not self.state.bufname then
                    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

                    vim.api.nvim_set_option_value("modifiable", true, { buf = self.state.bufnr })
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
                    vim.api.nvim_set_option_value("filetype", "markdown", { buf = self.state.bufnr })
                    vim.api.nvim_set_option_value("modifiable", false, { buf = self.state.bufnr })
                    preview_utils.highlighter(self.state.bufnr, "markdown")
                end

                if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
                    local line_count = vim.api.nvim_buf_line_count(self.state.bufnr)
                    local target = math.min(entry.value.lnum, line_count)

                    vim.api.nvim_set_option_value("number", true, { win = self.state.winid })
                    vim.api.nvim_set_option_value("relativenumber", false, { win = self.state.winid })
                    vim.api.nvim_set_option_value("cursorline", true, { win = self.state.winid })
                    vim.api.nvim_set_option_value("wrap", false, { win = self.state.winid })
                    vim.api.nvim_win_set_cursor(self.state.winid, { target, 0 })
                    vim.api.nvim_win_call(self.state.winid, function()
                        vim.cmd("normal! zz")
                    end)
                end
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, telescope_map)
            telescope_map("i", "<C-n>", actions.move_selection_next)
            telescope_map("i", "<C-p>", actions.move_selection_previous)
            telescope_map("n", "<C-n>", actions.move_selection_next)
            telescope_map("n", "<C-p>", actions.move_selection_previous)

            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if not selection or not vim.api.nvim_win_is_valid(target_win) then
                    return
                end

                vim.api.nvim_win_call(target_win, function()
                    vim.api.nvim_win_set_cursor(0, { selection.value.lnum, 0 })
                    vim.cmd("normal! zz")
                end)

                if pane_visible and vim.api.nvim_win_is_valid(origin_win) then
                    vim.api.nvim_set_current_win(origin_win)
                end
            end)

            return true
        end,
    }):find()
end

map('n', '<leader>fm', markdown_headings, {})

local markdown_pane = require("markdown_pane")
local markdown_reflow_cmd = { "mdfmt", "--stdin", "--width", "{width}", "--wrap", "always" }

markdown_pane.setup({
    external_reflow_cmd = markdown_reflow_cmd,
    external_reflow_protect_tables = true,
})

vim.api.nvim_create_user_command("MarkdownPaneToggle", function(opts)
    markdown_pane.toggle(opts.args)
end, { nargs = "?", complete = "file" })

vim.api.nvim_create_user_command("MarkdownPanePick", function()
    markdown_pane.pick()
end, {})

vim.api.nvim_create_user_command("PaneSwitch", function()
    markdown_pane.switch_picker()
end, {})

vim.api.nvim_create_user_command("PaneTool", function(opts)
    local parts = vim.split(opts.args or "", "%s+", { trimempty = true })

    if not parts[1] then
        markdown_pane.switch_picker()
        return
    end

    markdown_pane.open_terminal(parts[1], parts[2])
end, { nargs = "*" })

vim.api.nvim_create_user_command("PaneCodex", function(opts)
    local preset = opts.args ~= "" and opts.args or nil
    markdown_pane.open_terminal("codex", preset)
end, { nargs = "?" })

vim.api.nvim_create_user_command("PaneClaude", function(opts)
    local preset = opts.args ~= "" and opts.args or nil
    markdown_pane.open_terminal("claude", preset)
end, { nargs = "?" })

vim.api.nvim_create_user_command("PaneIPython", function()
    markdown_pane.open_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
        focus = true,
    })
end, {})

vim.api.nvim_create_user_command("PaneIPythonRestart", function()
    markdown_pane.restart_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
        focus = true,
    })
end, {})

vim.api.nvim_create_user_command("PaneIPythonClear", function()
    markdown_pane.clear_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
    })
end, {})

vim.api.nvim_create_user_command("PaneFocus", function()
    markdown_pane.focus_toggle()
end, {})

vim.api.nvim_create_user_command("PaneZoom", function()
    markdown_pane.toggle_zoom()
end, {})

vim.api.nvim_create_user_command("PaneAsk", function(opts)
    markdown_pane.ask_picker({
        bufnr = vim.api.nvim_get_current_buf(),
        line1 = opts.line1,
        line2 = opts.line2,
    })
end, { range = true })

vim.api.nvim_create_user_command("PaneAskCodex", function(opts)
    local preset = opts.args ~= "" and opts.args or nil

    markdown_pane.ask("codex", preset, {
        bufnr = vim.api.nvim_get_current_buf(),
        line1 = opts.line1,
        line2 = opts.line2,
    })
end, { nargs = "?", range = true })

vim.api.nvim_create_user_command("PaneAskClaude", function(opts)
    local preset = opts.args ~= "" and opts.args or nil

    markdown_pane.ask("claude", preset, {
        bufnr = vim.api.nvim_get_current_buf(),
        line1 = opts.line1,
        line2 = opts.line2,
    })
end, { nargs = "?", range = true })

map('n', '<leader>pp', function()
    markdown_pane.toggle()
end, {})
map('n', '<leader>mP', function()
    markdown_pane.pick()
end, {})
map('n', '<leader>p0', function()
    markdown_pane.show_markdown()
end, {})
map('n', '<leader>px', function()
    markdown_pane.open_terminal("codex", nil, {
        bufnr = vim.api.nvim_get_current_buf(),
        focus = true,
    })
end, {})
map('n', '<leader>pc', function()
    markdown_pane.open_terminal("claude", nil, {
        bufnr = vim.api.nvim_get_current_buf(),
        focus = true,
    })
end, {})
map('n', '<leader>pi', function()
    markdown_pane.open_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
        focus = true,
    })
end, {})
map('n', '<leader>pR', function()
    markdown_pane.restart_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
        focus = true,
    })
end, {})
map('n', '<leader>pl', function()
    markdown_pane.send_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
        line1 = vim.fn.line("."),
        line2 = vim.fn.line("."),
    })
end, {})
map('x', '<leader>pl', function()
    markdown_pane.send_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
        visual = true,
        visual_mode = vim.fn.mode(1),
    })
end, {})
map('n', '<leader>pX', function()
    markdown_pane.clear_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
    })
end, {})
map('n', '<leader>pf', function()
    markdown_pane.focus_toggle()
end, {})
map('n', '<leader>pz', function()
    markdown_pane.toggle_zoom()
end, {})
map('n', '<leader>ps', function()
    markdown_pane.switch_picker()
end, {})
map('x', '<leader>pa', function()
    markdown_pane.ask_picker({
        bufnr = vim.api.nvim_get_current_buf(),
        visual = true,
        visual_mode = vim.fn.mode(1),
    })
end, {})
map('x', 'aa', function()
    markdown_pane.ask_last_coding_agent({
        bufnr = vim.api.nvim_get_current_buf(),
        visual = true,
        visual_mode = vim.fn.mode(1),
    })
end, { desc = "Ask last coding agent" })
map('x', 'ax', function()
    markdown_pane.ask_current_coding_agent("codex", {
        bufnr = vim.api.nvim_get_current_buf(),
        visual = true,
        visual_mode = vim.fn.mode(1),
    })
end, { desc = "Ask current Codex pane" })
map('x', 'ac', function()
    markdown_pane.ask_current_coding_agent("claude", {
        bufnr = vim.api.nvim_get_current_buf(),
        visual = true,
        visual_mode = vim.fn.mode(1),
    })
end, { desc = "Ask current Claude pane" })

local markdown_reflow = require("markdown_reflow")

markdown_reflow.setup({
    external_reflow_cmd = markdown_reflow_cmd,
    external_reflow_protect_tables = true,
})

vim.api.nvim_create_user_command("MarkdownReflow", function(opts)
    markdown_reflow.reflow_buffer(0, { width = tonumber(opts.args) })
end, { nargs = "?" })

map('n', '<leader>mR', function()
    markdown_reflow.reflow_buffer(0)
end, {})

local fb_actions = require("telescope").extensions.file_browser.actions
local telescope_action_state = require("telescope.actions.state")

local function selected_telescope_text(entry)
    if not entry then
        return nil
    end

    local value = entry.path or entry.filename or entry.value or entry[1] or entry.ordinal

    if type(value) == "table" and value.path then
        value = value.path
    end

    if type(value) ~= "string" or value == "" then
        return nil
    end

    return value
end

local function copy_telescope_selection()
    local text = selected_telescope_text(telescope_action_state.get_selected_entry())

    if not text then
        vim.notify("No Telescope selection to copy", vim.log.levels.WARN)
        return
    end

    vim.fn.setreg('"', text)
    pcall(vim.fn.setreg, "+", text)
    vim.notify("Copied: " .. text, vim.log.levels.INFO)
end

require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<C-y>"] = copy_telescope_selection,
            },
            n = {
                ["<C-y>"] = copy_telescope_selection,
            },
        },
    },
    extensions = {
        file_browser = {
            hijack_netrw = true,
            mappings = {
                ["i"] = {
                    ["<C-r>"] = fb_actions.rename
                }
            }
        }
    }
})

require("telescope").load_extension("file_browser")
map('n', '<leader>fb', '<cmd>Telescope file_browser <CR>', { noremap = true})

-- Completion
local cmp = require("cmp")
local cmp_enabled = true

vim.api.nvim_create_user_command("ToggleAutoComplete", function()
    if cmp_enabled then
        require("cmp").setup.buffer({ enabled = false })
        cmp_enabled = false
    else
        require("cmp").setup.buffer({ enabled = true })
        cmp_enabled = true
    end
end, {})

map('n', '<leader>tc', '<cmd>ToggleAutoComplete<CR>')

cmp.setup({
    mapping = {
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<C-n>"] = cmp.mapping.select_next_item(),
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.close(),
      ["<CR>"] = cmp.mapping.confirm({
         behavior = cmp.ConfirmBehavior.Replace,
         select = true,
      }),
      ["<Tab>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "s" })
    },
    sources = {
        { name = "buffer" },
        { name = "nvim_lsp" },
        { name = "path" }
    }
})

-- LSP
require("mason").setup()

-- Workaround for tsserver --> ts_ls rename
-- https://github.com/neovim/nvim-lspconfig/pull/3232#issuecomment-2331025714
-- require("mason-lspconfig").setup_handlers({
--     function(server_name)
--         if server_name == "tsserver" then
--             server_name = "ts_ls"
--         end
--         local capabilities = require("cmp_nvim_lsp").default_capabilities()
--         require("lspconfig")[server_name].setup({
--             capabilities = capabilities,
--         })
--     end,
-- })

require("mason-lspconfig").setup({
    ensure_installed = { "cssls", "quick_lint_js", "ts_ls", "pyright", "r_language_server", "sqlls", "yamlls", "html", "marksman", "svelte", "gopls", "tailwindcss" }
})


-- CHANGED: Removed deprecated `local lspconfig = require("lspconfig")` pattern
-- The old pattern was: lspconfig.SERVER.setup({})
-- New pattern uses vim.lsp.config() to customize, then vim.lsp.enable() to activate
-- This is the Neovim 0.11+ recommended approach that replaces nvim-lspconfig's framework

-- Basic servers with default configuration
-- CHANGED: Using vim.lsp.enable() instead of lspconfig.SERVER.setup({})
-- These servers use nvim-lspconfig's default configs (from the lsp/ directory)
-- which are automatically discovered by vim.lsp.enable()
vim.lsp.enable('cssls')
vim.lsp.enable('quick_lint_js')
vim.lsp.enable('pyright')
vim.lsp.enable('r_language_server')
vim.lsp.enable('sqlls')
vim.lsp.enable('html')
vim.lsp.enable('marksman')
vim.lsp.enable('yamlls')
vim.lsp.enable('gopls')

-- CHANGED: Added Tailwind CSS LSP support
-- Tailwind LSP provides IntelliSense, linting, and hover documentation for Tailwind classes
vim.lsp.enable('tailwindcss')

-- TypeScript server with custom filetypes
-- CHANGED: Using vim.lsp.config() to customize before enabling
-- First configure the server, then enable it
vim.lsp.config('ts_ls', {
    filetypes = {
        'typescript',
        'typescriptreact',
        'typescript.tsx'
    }
})
vim.lsp.enable('ts_ls')

-- Svelte server with custom on_attach and handlers
-- CHANGED: Using vim.lsp.config() for complex customization
-- on_attach and handlers work the same way, just configured differently
vim.lsp.config('svelte', {
    on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.js", "*.ts" },
            callback = function(ctx)
                -- Here use ctx.match instead of ctx.file
                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
            end,
        })
    end,
    handlers = {
        ["textDocument/definition"] = function(err, result, ctx, config)
            if type(result) == "table" then
                result = { result[1] }
            end
            vim.lsp.handlers["textDocument/definition"](err, result, ctx, config)
        end,
    },
})
vim.lsp.enable('svelte')

map('n', '<space>e', vim.diagnostic.open_float)
map('n', '[d', vim.diagnostic.goto_prev)
map('n', ']d', vim.diagnostic.goto_next)
map('n', '<space>q', vim.diagnostic.setloclist)

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<C-s>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<space>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
        vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<space>f', function()
          vim.lsp.buf.format { async = true }
        end, opts)
    end,
})

local glance = require('glance')
local actions = glance.actions

glance.setup()
map('n', '<leader>pr', '<cmd>Glance references<CR>')
map('n', '<leader>pd', '<cmd>Glance definitions<CR>')
map('n', '<leader>pt', '<cmd>Glance type_definitions<CR>')
map('n', '<leader>pI', '<cmd>Glance implementations<CR>')

require('trouble').setup()
map('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>')
map('n', '<leader>xw', '<cmd>TroubleToggle workspace_diagnostics<cr>')
map('n', '<leader>xd', '<cmd>TroubleToggle document_diagnostics<cr>')
map('n', '<leader>xq', '<cmd>TroubleToggle quickfix<cr>')
map('n', '<leader>xl', '<cmd>TroubleToggle loclist<cr>')
map('n', '<leader>gR', '<cmd>TroubleToggle lsp_references<cr>')


-- Treesitter
local treesitter_parsers = {
    "lua",
    "vim",
    "vimdoc",
    "css",
    -- Query-only dependencies used by HTML and JavaScript-family parsers.
    "ecma",
    "html_tags",
    "jsx",
    "json",
    "javascript",
    "latex",
    "python",
    "r",
    "regex",
    "scss",
    "yaml",
    "html",
    "vue",
    "svelte",
    "go",
    "typescript",
    "sql",
    "markdown",
    "markdown_inline",
    "rnoweb",
}

require("nvim-treesitter").install(treesitter_parsers)

vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "lua",
        "vim",
        "help",
        "css",
        "json",
        "javascript",
        "tex",
        "python",
        "r",
        "scss",
        "yaml",
        "html",
        "vue",
        "svelte",
        "go",
        "typescript",
        "sql",
        "markdown",
        "rnoweb",
    },
    callback = function()
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

require("nvim-treesitter-textobjects").setup({
    move = {
        set_jumps = true,
    },
})

local ts_move = require("nvim-treesitter-textobjects.move")

map({ "n", "x", "o" }, "]a", function()
    ts_move.goto_next_start("@attribute.outer", "textobjects")
end)

map({ "n", "x", "o" }, "]t", function()
    ts_move.goto_next_start("@function.outer", "textobjects")
end)

map({ "n", "x", "o" }, "[a", function()
    ts_move.goto_previous_start("@attribute.outer", "textobjects")
end)

map({ "n", "x", "o" }, "[t", function()
    ts_move.goto_previous_start("@function.outer", "textobjects")
end)

-- git
map('n', '<Space>ggg', ":LazyGit<CR>")
map('n', '<Space>ggc', ":LazyGitConfig<CR>")

-- Code Navigation
require("aerial").setup({
    layout = {
            default_direction = "prefer_right",
    },
    on_attach = function(bufnr)
        map('n', '-', '<cmd>AerialPrev<CR>', {buffer = bufnr})
        map('n', '_', '<cmd>AerialNext<CR>', {buffer = bufnr})
    end
})
map('n', '<leader>aa', '<cmd>AerialToggle!<CR>')

-- Editing

require("yaml_nvim")
require("nvim-autopairs").setup()
-- require("nvim-ts-autotag").setup()
require('Comment').setup()
require("nvim-surround").setup()

-- Tree sidebar files

local function nvim_tree_file_target_picker()
    local ok, markdown_pane = pcall(require, "markdown_pane")
    local pane_winid = ok and markdown_pane.winid or nil
    local pane_bufnr = ok and markdown_pane.bufnr or nil
    local alternate_winid = vim.fn.win_getid(vim.fn.winnr("#"))
    local candidates = {}

    local function usable(winid)
        if not vim.api.nvim_win_is_valid(winid) then
            return false
        end

        if winid == pane_winid then
            return false
        end

        local config = vim.api.nvim_win_get_config(winid)

        if not config.focusable or config.hide or config.external then
            return false
        end

        local bufnr = vim.api.nvim_win_get_buf(winid)

        if bufnr == pane_bufnr then
            return false
        end

        local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

        if vim.tbl_contains({ "nofile", "terminal", "help" }, buftype) then
            return false
        end

        if vim.tbl_contains({ "NvimTree", "notify", "lazy", "qf", "diff", "fugitive", "fugitiveblame" }, filetype) then
            return false
        end

        return true
    end

    if usable(alternate_winid) then
        return alternate_winid
    end

    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if usable(winid) then
            table.insert(candidates, winid)
        end
    end

    return candidates[1] or -1
end

require("nvim-tree").setup({
    actions = {
        open_file = {
            quit_on_open = true,
            window_picker = {
                picker = nvim_tree_file_target_picker,
                exclude = {
                    buftype = { "nofile", "terminal", "help" },
                    filetype = {
                        "notify",
                        "lazy",
                        "qf",
                        "diff",
                        "fugitive",
                        "fugitiveblame",
                    },
                },
            },
        },
    },
})
map('n', '<leader>ss', '<cmd>NvimTreeToggle<CR>')

-- R specific
vim.g.R_hl_term = 1
vim.g.R_rconsole_width = 120
vim.g.R_assign = 0

map('t', '<C-k>', '<C-\\><C-n>')
map('t', 'jk', '<C-\\><C-n>')
map('t', 'kj', '<C-\\><C-n>')

-- Toggle diagnostics
-- require('toggle_lsp_diagnostics').init()
-- map('n', '<Space>dd', ":ToggleDiag<CR>")

-- REPL
local iron = require("iron.core")

iron.setup {
    config = {
        -- Whether a repl should be discarded or not
        scratch_repl = true,
        -- Your repl definitions come here
        repl_definition = {
            python = {
                command = { "ipython" }
            },
            sh = {
                -- Can be a table or a function that
                -- returns a table (see below)
                command = {"zsh"}
            }
        },
        -- How the repl window will be displayed
        -- See below for more information
        -- repl_open_cmd = require('iron.view').right(80),
        repl_open_cmd = "vertical 80 split"
    },
    -- Iron doesn't set keymaps by default anymore.
    -- You can set them here or manually add keymaps to the functions in iron.core
    keymaps = {
        send_motion = "<space>rr",
        visual_send = "<space>rr",
        send_file = "<space>rf",
        send_line = "<space>rl",
        -- send_paragraph = "<space>sp",
        send_until_cursor = "<space>su",
        send_mark = "<space>rsm",
        mark_motion = "<space>rmc",
        mark_visual = "<space>rmc",
        remove_mark = "<space>rmk",
        cr = "<space>rr<cr>",
        interrupt = "<space>r<space>",
        exit = "<space>rq",
        clear = "<space>rx",
    },
    -- If the highlight is on, you can change how it looks
    -- For the available options, check nvim_set_hl
    highlight = {
        italic = false
    },
    ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
}

-- iron also has a list of commands, see :h iron-commands for all available commands
vim.keymap.set('n', '<space>rs', '<cmd>IronRepl<cr>')
vim.keymap.set('n', '<space>rr', '<cmd>IronRestart<cr>')
vim.keymap.set('n', '<space>rf', '<cmd>IronFocus<cr>')
vim.keymap.set('n', '<space>rh', '<cmd>IronHide<cr>')

require("neo-zoom").setup({
    popup = { enabled = false },
winopts = {
    offset = {
        top = nil,
        left = nil,
        width = 1,
        height = 1
    }
}
})

vim.keymap.set('n', '<space>zz', '<cmd>NeoZoomToggle<cr>')

-- Harpoon
-- local harpoon = require('harpoon');
-- harpoon:setup()

-- vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
-- vim.keymap.set("n", "<leader>r", function() harpoon:list():remove() end)
-- vim.keymap.set("n", "<leader>l", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
--
-- vim.keymap.set("n", "<leader>h1", function() harpoon:list():select(1) end)
-- vim.keymap.set("n", "<leader>h2", function() harpoon:list():select(2) end)
-- vim.keymap.set("n", "<leader>h3", function() harpoon:list():select(3) end)
-- vim.keymap.set("n", "<leader>h4", function() harpoon:list():select(4) end)
--
-- -- Toggle previous & next buffers stored within Harpoon list
-- vim.keymap.set("n", "<leader>hj", function() harpoon:list():prev() end)
-- vim.keymap.set("n", "<leader>hk", function() harpoon:list():next() end)

-- Go
local goc = require("nvim-goc")
goc.setup({ verticalSplit = false })

map('n', '<Leader>gcf', goc.Coverage, {silent=true})
map('n', '<Leader>gct', goc.CoverageFunc, {silent=true})
map('n', '<Leader>gcc', goc.ClearCoverage, {silent=true})

vim.api.nvim_create_user_command("ReorderScript", function()
    require("svelte_script_sorter").reorder_script_block(0)
end, {})

-- CHANGED: Commented out tailwind-tools.nvim because it internally uses deprecated require('lspconfig')
-- This was causing the deprecation warning. Instead, using built-in Tailwind LSP above.
-- If you need tailwind-tools features later, wait for the plugin to be updated for Neovim 0.11+
-- require("tailwind-tools").setup({})


-- SVELTE

local function is_line_inside_script(bufnr, line)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local inside_script = false

  for i, content in ipairs(lines) do
    if content:find("<script") then
      inside_script = true
    end
    if content:find("</script>") then
      if i >= line + 1 then
        return inside_script
      end
      inside_script = false
    end
    if i == line + 1 then
      return inside_script
    end
  end

  return false
end

local function delete_lines_with_error_code(error_code)
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)
  local lines_to_delete = {}

  -- Detect filetype (to special-handle Svelte files)
  local filetype = vim.bo.filetype

  -- Collect line numbers matching the error code
  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.code == error_code then
      local should_delete = true

      -- Special logic for Svelte
      if filetype == "svelte" then
        should_delete = is_line_inside_script(bufnr, diagnostic.lnum)
      end

      if should_delete then
        table.insert(lines_to_delete, diagnostic.lnum)
      end
    end
  end

  -- Sort descending to avoid messing up line numbers when deleting
  table.sort(lines_to_delete, function(a, b) return a > b end)

  -- Delete lines
  for _, lnum in ipairs(lines_to_delete) do
    vim.api.nvim_buf_set_lines(bufnr, lnum, lnum + 1, false, {})
  end
end

-- Create a Vim command :DeleteUnusedVars
vim.api.nvim_create_user_command('DeleteUnusedVars', function()
  delete_lines_with_error_code(6133)
end, {})

-- OPTIONAL: Keymap (e.g., <leader>du to "Delete Unused")
vim.keymap.set('n', '<leader>du', function()
  delete_lines_with_error_code(6133)
end, { desc = "Delete unused variables (TS Error 6133)" })

-- LEAP
-- CHANGED: Replaced deprecated add_default_mappings() with the new recommended approach
-- The plugin now requires explicit keybindings using <Plug> mappings
-- See :help leap-mappings for more details
vim.keymap.set({'n', 'x', 'o'}, 's', '<Plug>(leap)')
vim.keymap.set('n', 'S', '<Plug>(leap-from-window)')
