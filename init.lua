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
    { "nvim-treesitter/nvim-treesitter", opts = {
        highlight = { enable = true }
    }, cmd = "TSUpdate" },
    -- Fuzzy finding
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
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
    "hrsh7th/nvim-cmp",
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
    {
        "ray-x/go.nvim",
        -- install required binaries
        build=':lua require("go.install).update_all_sync()',
        ft = {"go", "gomod"}
    },
    "mrcjkb/rustaceanvim",
    "jalvesaq/Nvim-R",
    -- Databases
    "tpope/vim-dadbod",
    "kristijanhusak/vim-dadbod-ui",
    -- Toggle diagnostics
    "WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
    -- REPL
    "hkupty/iron.nvim",
    "nyngwang/NeoZoom.lua"
})

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
map('n', '<leader>tk', ':tabnext<Cr>', { silent = true })
map('n', '<leader>tj', ':tabprev<Cr>', { silent = true })
map('n', '<leader>uu', ':Lazy update<Cr>', { silent = true })
-- Move line up / down
map('n', '<leader>k', 'ddkP', { silent = true })
map('n', '<leader>j', 'ddp', { silent = true })
-- Add blank line above / below
map('n', '<leader>O', 'O<Esc>', { silent = true })
map('n', '<leader>o', 'o<Esc>', { silent = true })


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

-- Relative line numbers
vim.wo.relativenumber = true

-- Color
vim.g.illuColor = 'dark'
vim.opt.termguicolors = true

-- vim.opt.guicursor = ""
require("tokyonight").setup({
    terminal_colors = true,
    styles = {
        -- comments = { fg = "#6e7596" }
        comments = { fg = "#7b83a6" },
    },
    day_brightness = 0.2,
    on_colors = function(colors)
        colors.fg_gutter = colors.dark3
    end
})


-- cmd("colorscheme tokyonight-night")
-- cmd("colorscheme tokyonight-day")
cmd("colorscheme tokyonight-night")

function ToggleColor()
    if vim.g.illuColor == 'light' then
        vim.g.illuColor = 'dark'
        set.background = "dark"
        cmd("colorscheme tokyonight-night")
        cmd("mode")
    else
        vim.g.illuColor = 'light'
        set.background = "light"
        require("vscode").setup({})
        cmd("colorscheme vscode")
        cmd("mode")
    end
end

map('n', '<leader>cc', '<cmd>lua ToggleColor()<CR>', {})

-- Statusline
require("lualine").setup()

-- Tabline


-- Fuzzy finding
local builtin = require('telescope.builtin')
map('n', '<leader>ff', builtin.find_files, {})
map('n', '<leader>fg', builtin.live_grep, {})
map('n', '<leader>fr', builtin.buffers, {})
map('n', '<leader>fh', builtin.help_tags, {})

local fb_actions = require("telescope").extensions.file_browser.actions

require("telescope").setup({
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

require("mason-lspconfig").setup({
    ensure_installed = { "cssls", "quick_lint_js", "tsserver", "pyright", "r_language_server", "sqlls", "yamlls", "html", "marksman", "volar", "svelte", "gopls" }
})

-- Workaround for tsserver --> ts_ls rename
-- https://github.com/neovim/nvim-lspconfig/pull/3232#issuecomment-2331025714
require("mason-lspconfig").setup_handlers({
    function(server_name)
        if server_name == "tsserver" then
            server_name = "ts_ls"
        end
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        require("lspconfig")[server_name].setup({
            capabilities = capabilities,
        })
    end,
})

local lspconfig = require("lspconfig")

lspconfig.cssls.setup({})
lspconfig.quick_lint_js.setup({})

lspconfig.ts_ls.setup({
    filetypes = {
        'typescript',
        'typescriptreact',
        'typescript.tsx'
    }
})

lspconfig.pyright.setup({})
lspconfig.r_language_server.setup({})
lspconfig.sqlls.setup({})
lspconfig.html.setup({})
lspconfig.marksman.setup({})
lspconfig.yamlls.setup({})
lspconfig.svelte.setup({
    on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.js", "*.ts" },
            callback = function(ctx)
                -- Here use ctx.match instead of ctx.file
                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
            end,
        })
    end,
})
lspconfig.gopls.setup({})

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
map('n', '<leader>pi', '<cmd>Glance implementations<CR>')

require('trouble').setup()
map('n', '<leader>xx', '<cmd>TroubleToggle<cr>')
map('n', '<leader>xw', '<cmd>TroubleToggle workspace_diagnostics<cr>')
map('n', '<leader>xd', '<cmd>TroubleToggle document_diagnostics<cr>')
map('n', '<leader>xq', '<cmd>TroubleToggle quickfix<cr>')
map('n', '<leader>xl', '<cmd>TroubleToggle loclist<cr>')
map('n', '<leader>gR', '<cmd>TroubleToggle lsp_references<cr>')


-- Treesitter
require("nvim-treesitter.configs").setup({
    ensure_installed = { "lua", "vim", "vimdoc", "css", "json", "javascript", "latex", "python", "r", "regex", "scss", "yaml", "html", "css", "vue", "svelte", "go", "typescript", "sql" },
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = true
    },
    indent = { enable = true },
    rainbow = {
        enable = true,
        extended_mode = true
    },
    yaml = {
        enable = true
    },
    go = {
        enable = true
    },
    typescript = {
        enable = true
    },
    svelte = {
        enable = true
    },
    sql = {
        enable = true
    },
    python = {
        enable = true
    }
})

-- git
map('n', '<Space>gg', ":LazyGit<CR>")
map('n', '<Space>gc', ":LazyGitConfig<CR>")

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
require("nvim-ts-autotag").setup()
require('Comment').setup()
require("nvim-surround").setup()

-- Tree sidebar files

require("nvim-tree").setup()
map('n', '<leader>ss', '<cmd>NvimTreeToggle<CR>')

-- R specific
vim.g.R_hl_term = 1
vim.g.R_rconsole_width = 120
vim.g.R_assign = 0

map('t', '<C-k>', '<C-\\><C-n>')
map('t', 'jk', '<C-\\><C-n>')
map('t', 'kj', '<C-\\><C-n>')

-- Toggle diagnostics
require('toggle_lsp_diagnostics').init()
map('n', '<Space>dd', ":ToggleDiag<CR>")

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
