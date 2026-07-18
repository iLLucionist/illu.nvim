# illu.nvim
Lua-based config files for neovim

## Sidepanes Configuration

`sidepanes` can still accept the internal tool config shape directly, but setup also supports a friendlier shorthand that expands to the same runtime preset tables:

```lua
require("sidepanes").setup({
  markdown = {
    wrap = true,
    reflow = {
      enabled = true,
      cmd = { "mdfmt", "--stdin", "--width", "{width}", "--wrap", "always" },
      protect_tables = true,
    },
  },
  tools = {
    codex = {
      models = { "gpt-5.5", "gpt-5.6-sol" },
      efforts = { "high", "medium", "xhigh" },
      speeds = { "fast", "normal" },
      default = { model = "gpt-5.5", effort = "high", speed = "fast" },
    },
    claude = {
      enabled = false,
    },
  },
  commands = true,
  mappings = {
    global = {
      toggle = "<leader>pp",
      markdown = "<leader>p0",
      headings = "<leader>fm",
      codex = "<leader>px",
      claude = "<leader>pc",
      ipython = "<leader>pi",
      focus = "<leader>pf",
      zoom = "<leader>pz",
      send_ipython = "<leader>pl",
      ask = "<leader>pa",
    },
    pane = {
      markdown = "<space>0",
      codex = "<space>x",
      claude = "<space>c",
      ipython = "<space>i",
      toggle_agent = "<leader>gg",
      toggle_agent_alt = "<C-g>",
      ipython_alt = "<leader>gi",
      gf = "gf",
      ask_last = "aa",
      ask_codex = "ax",
      ask_claude = "ac",
    },
  },
})
```

For reusable generated tool tables, use `require("sidepanes.presets").codex(...)` or `require("sidepanes.presets").claude(...)`.

Set `commands = true` to register the default `:Sidepanes*` commands. Set `mappings.global` to a table to install global mappings. `mappings.pane` customizes buffer-local pane mappings; set an entry to `false` to disable it.

Run `:checkhealth sidepanes` to inspect external commands, optional dependencies, tool presets, command registration, and mapping configuration.

Sidepanes also runs lightweight setup validation by default. It warns for malformed command/mapping/tool config and for dependencies implied by enabled features, such as `telescope.nvim` for document/headings pickers, the Markdown Treesitter parser for headings, and `smart_gf` for pane-local `gf`. Set `validate = false` to silence setup-time validation. Runtime feature entry points still fail gracefully with a dependency-specific warning when a required dependency is missing.

Standalone Markdown reflow commands and mappings are configured through `markdown_reflow`:

```lua
require("markdown_reflow").setup({
  external_reflow_cmd = { "mdfmt", "--stdin", "--width", "{width}", "--wrap", "always" },
  external_reflow_protect_tables = true,
  commands = true,
  mappings = {
    reflow = "<leader>mR",
  },
})
```
