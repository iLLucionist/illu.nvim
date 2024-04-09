-- For reference: https://github.com/neovim/neovim/blob/master/src/nvim/options.lua
-- lazy.nvim reference: https://github.com/folke/lazy.nvim
-- mason-lspconfig: https://github.com/williamboman/mason-lspconfig.nvim

vim.g.mapleader = " "

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
    -- Editing
    "windwp/nvim-autopairs",
    "windwp/nvim-ts-autotag",
    "numToStr/Comment.nvim",
    "kylechui/nvim-surround",
    "kristijanhusak/vim-dadbod-ui",
    -- Language specific
    {
        "ray-x/go.nvim",
        -- install required binaries
        build=':lua require("go.install).update_all_sync()',
        ft = {"go", "gomod"}
    },
    "mrcjkb/rustaceanvim"
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
map('n', '<leader>tl', ':tabnext<Cr>', { silent = true })
map('n', '<leader>th', ':tabprev<Cr>', { silent = true })
map('n', '<leader>uu', ':Lazy update<Cr>', { silent = true })


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

-- Color
set.background = "dark"
require("tokyonight").setup({
    styles = {
        -- comments = { fg = "#6e7596" }
        comments = { fg = "#7b83a6" }
    }
})
cmd("colorscheme tokyonight-night")

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

local lspconfig = require("lspconfig")
lspconfig.cssls.setup({})
lspconfig.quick_lint_js.setup({})
lspconfig.tsserver.setup({})
lspconfig.pyright.setup({})
lspconfig.r_language_server.setup({})
lspconfig.sqlls.setup({})
lspconfig.html.setup({})
lspconfig.marksman.setup({})
lspconfig.yamlls.setup({})
lspconfig.svelte.setup({})
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
    autotag = {
        enable = true
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
require("nvim-autopairs").setup({})
require("nvim-ts-autotag").setup({})
require('Comment').setup({})
require("nvim-surround").setup({})

-- Language specific

-- require("go").setup({});
