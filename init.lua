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
    {
        "iLLucionist/sidepanes.nvim",
        name = "sidepanes.nvim",
        version = "v0.2.0",
        lazy = false,
    },
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
    exclude_name = { "Sidepanes" },
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

local sidepanes = require("sidepanes")
local markdown_reflow_cmd = { "mdfmt", "--stdin", "--width", "{width}", "--wrap", "always" }

sidepanes.setup({
    layout = {
        width = 100,
        zoom_text_width = 90,
        sticky_relative_width = false,
        width_snap_points = { 60, 70, 80, 90, 100, 110, 120, "1/3", "40%", "1/2", "60%", "2/3", "75%" },
        width_picker_points = { "1/4", "1/3", "2/5", "1/2", "60%", "2/3", "75%", 100, 120 },
    },
    markdown = {
        wrap = false,
        wrap_toggle_key = "<leader>mw",
        sticky_heading = true,
        reflow = {
            enabled = true,
            cmd = markdown_reflow_cmd,
            fallback = true,
            protect_tables = true,
            margin = 8,
        },
    },
    lifecycle = {
        focus_on_switch = true,
        focus_on_ask = true,
        shutdown_on_exit = true,
        shutdown_timeout_ms = 300,
    },
    validation = {
        enabled = true,
    },
    commands = {
        root = "Sidepanes",
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
        width_picker = "SidepanesWidthPick",
        ask = "SidepanesAsk",
        ask_codex = "SidepanesAskCodex",
        ask_claude = "SidepanesAskClaude",
    },
    mappings = {
        global = {
            toggle = "<leader>pp",
            pick = "<leader>mP",
            headings = "<leader>fm",
            markdown = "<leader>p0",
            codex = "<leader>px",
            claude = "<leader>pc",
            ipython = "<leader>pi",
            restart_ipython = "<leader>pR",
            send_ipython = "<leader>pl",
            clear_ipython = "<leader>pX",
            focus = "<leader>pf",
            zoom = "<leader>pz",
            width_previous = "<leader>p-",
            width_next = "<leader>p+",
            width_picker = "<leader>pw",
            sticky_relative_width = "<leader>p%",
            switch = "<leader>ps",
            ask = "<leader>pa",
            ask_last = "aa",
            ask_codex = "ax",
            ask_claude = "ac",
        },
        pane = {
            markdown = "<space>0",
            codex = "<space>x",
            claude = "<space>c",
            ipython = "<space>i",
            toggle_terminal = "<leader>gg",
            toggle_terminal_alt = "<C-g>",
            ipython_alt = "<leader>gi",
            gf = "gf",
            send_ipython = "ll",
            zoom = "zz",
            ask_last = "aa",
            ask_codex = "ax",
            ask_claude = "ac",
        },
    },
    tools = {
        codex = {
            label = "Codex",
            cmd = "codex",
            include_cd_arg = true,
            send_delay_ms = 700,
            switch_command = "/model {model} {effort} {speed}",
            exit_command = "/quit\r",
            models = { "gpt-5.5", "gpt-5.6-sol" },
            efforts = { "high", "medium", "xhigh" },
            speeds = { "fast", "normal" },
            default = { model = "gpt-5.5", effort = "high", speed = "fast" },
        },
        claude = {
            label = "Claude",
            cmd = "claude",
            send_delay_ms = 700,
            switch_command = "/model {model} {effort}",
            exit_command = "/exit\r",
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
        ipython = {
            label = "IPython",
            ask = false,
            cmd = function()
                if vim.env.VIRTUAL_ENV and vim.fn.executable("ipython") == 1 then
                    return { "ipython" }
                end

                if vim.fn.executable("uv") == 1 then
                    return { "uv", "run", "ipython" }
                end

                return { "ipython" }
            end,
            send_delay_ms = 500,
            exit_command = "quit()\r",
            presets = {
                {
                    name = "default",
                    label = "Default",
                    args = {},
                },
            },
        },
    },
})

local markdown_reflow = require("sidepanes.markdown_reflow")

markdown_reflow.setup({
    external_reflow_cmd = markdown_reflow_cmd,
    external_reflow_protect_tables = true,
    commands = true,
    mappings = {
        reflow = "<leader>mR",
    },
})

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

local nvim_tree_file_target_picker = require("sidepanes.integrations.nvim_tree").file_target_picker

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
