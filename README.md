# illu.nvim
Lua-based config files for neovim

## Sidepanes Configuration

`sidepanes` can still accept the older flat runtime keys directly, but the documented setup shape groups related options by responsibility. The grouped form expands to the same internal runtime config:

```lua
require("sidepanes").setup({
  layout = {
    width = 100,
    zoom_text_width = 90,
  },
  markdown = {
    wrap = false,
    wrap_toggle_key = "<leader>mw",
    sticky_heading = true,
    reflow = {
      enabled = true,
      cmd = { "mdfmt", "--stdin", "--width", "{width}", "--wrap", "always" },
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
      send_ipython = "ll",
      zoom = "zz",
      ask_last = "aa",
      ask_codex = "ax",
      ask_claude = "ac",
    },
  },
})
```

Grouped options normalize to these runtime keys:

- `layout.width` -> `width`
- `layout.zoom_text_width` -> `zoom_text_width`
- `markdown.wrap` -> `wrap`
- `markdown.wrap_toggle_key` -> `wrap_toggle_key`
- `markdown.sticky_heading` -> `sticky_heading`
- `markdown.reflow.enabled` -> `auto_reflow`
- `markdown.reflow.cmd` -> `external_reflow_cmd`
- `markdown.reflow.fallback` -> `external_reflow_fallback`
- `markdown.reflow.protect_tables` -> `external_reflow_protect_tables`
- `markdown.reflow.margin` -> `reflow_margin`
- `lifecycle.focus_on_switch` -> `focus_on_switch`
- `lifecycle.focus_on_ask` -> `focus_on_ask`
- `lifecycle.shutdown_on_exit` -> `shutdown_on_exit`
- `lifecycle.shutdown_timeout_ms` -> `shutdown_timeout_ms`
- `validation.enabled` -> `validate`

Use `require("sidepanes.config").default_setup()` to inspect the full grouped default setup shape from Lua.

For reusable generated tool tables, use `require("sidepanes.presets").codex(...)` or `require("sidepanes.presets").claude(...)`.

Set `commands = true` to register the default `:Sidepanes*` commands. Set `mappings.global` to a table to install global mappings. `mappings.pane` customizes buffer-local pane mappings; set an entry to `false` to disable it.

`:Sidepanes` is the discoverable command surface. With no arguments it opens the pane switcher; with completion it exposes subcommands:

```vim
:Sidepanes switch
:Sidepanes open docs/notes.md
:Sidepanes codex gpt55_high_fast
:Sidepanes claude sonnet
:Sidepanes ipython
:Sidepanes ask-codex gpt55_high_fast
:Sidepanes help
```

Run `:checkhealth sidepanes` to inspect external commands, optional dependencies, tool presets, command registration, and mapping configuration.

Sidepanes also runs lightweight setup validation by default. It warns for malformed command/mapping/tool config and for dependencies implied by enabled features, such as `telescope.nvim` for document/headings pickers, the Markdown Treesitter parser for headings, and `smart_gf` for pane-local `gf`. Set `validation.enabled = false` or the legacy `validate = false` to silence setup-time validation. Runtime feature entry points still fail gracefully with a dependency-specific warning when a required dependency is missing.

Run `tests/run_sidepanes_checks.sh` before refactors to execute the regression suite, full-config audit smoke, `:checkhealth sidepanes` smoke, and real Codex/Claude CLI smoke.

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
