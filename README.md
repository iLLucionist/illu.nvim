# illu.nvim
Lua-based config files for neovim

## Sidepanes Configuration

`sidepanes` can still accept the older flat runtime keys directly, but the documented setup shape groups related options by responsibility. The grouped form expands to the same internal runtime config:

```lua
require("sidepanes").setup({
  layout = {
    width = 100,
    zoom_text_width = 90,
    sticky_relative_width = false,
    width_snap_points = { 60, 70, 80, 90, 100, 110, 120, "1/3", "40%", "1/2", "60%", "2/3", "75%" },
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
      width_previous = "<leader>p-",
      width_next = "<leader>p+",
      sticky_relative_width = "<leader>p%",
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
- `layout.sticky_relative_width` -> `sticky_relative_width`
- `layout.width_snap_points` -> `width_snap_points`
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

## Public API

`require("sidepanes")` returns the supported facade for config, commands, and mappings. Mutable pane state is intentionally not exposed as top-level fields; use `get_config()` for a defensive copy of normalized config.

Stable public calls include:

- `setup(opts)`, `get_config()`
- `open(path)`, `toggle(path)`, `close()`, `is_open()`
- `focus_toggle()`, `toggle_zoom()`, `show_markdown()`
- `get_width()`, `set_width(value)`, `adjust_width(delta)`, `snap_width(direction)`, `toggle_sticky_relative_width(enabled)`, `text_width()`, `toggle_wrap()`
- `pick()`, `pick_headings()`, `switch_picker()`
- `switch_to(target, opts)`, `make_switch_entry(target, opts)`
- `open_terminal(tool_name, preset_name, opts)`
- `open_ipython(opts)`, `send_ipython(opts)`, `clear_ipython(opts)`, `restart_ipython(opts)`
- `ask(tool_name, preset_name, opts)`, `ask_picker(opts)`, `ask_last_coding_agent(opts)`, `ask_current_coding_agent(tool_name, opts)`
- `shutdown_terminals(opts)`

`switch_to(target, opts)` is the stable programmatic switch API. It accepts simple targets:

```lua
require("sidepanes").switch_to("markdown")
require("sidepanes").switch_to("codex")
require("sidepanes").switch_to("claude")
require("sidepanes").switch_to("ipython")
require("sidepanes").switch_to("x") -- codex shortcut
```

For more control, pass a table. Presets may use either the configured preset `name` or `label`:

```lua
require("sidepanes").switch_to({
  tool = "codex",
  preset = "GPT-5.5 / high / fast",
  root = vim.fn.getcwd(),
  focus = true,
})
```

`make_switch_entry(target, opts)` validates and normalizes the same input into the internal entry consumed by the switcher. It is an advanced helper for integration code that needs to inspect or store a switch target before invoking `switch_to()`.

`show_last_agent(opts)` and `toggle_markdown_agent()` are advanced workflow helpers. They are useful for navigation, but they expose Sidepanes' current runtime memory rather than a durable history model.

`show_last_agent(opts)` shows the most recently remembered pane terminal. If that terminal is still running, it is reused. If it is not running, Sidepanes tries the remembered tool/preset again. If there is no remembered terminal at all, it falls back to Codex with the default Codex preset. Despite the name, this helper follows the latest pane terminal state today, so IPython or a custom terminal can be involved if that was the last terminal used. The Codex/Claude ask helpers remain coding-agent-specific. `opts.focus` controls whether the pane is focused; when omitted, `focus_on_switch` applies.

`toggle_markdown_agent()` switches from Markdown to `show_last_agent({ focus = true })`, and switches from any terminal mode back to the Markdown viewer. That means it behaves like a two-state workflow shortcut, not a terminal history stack: repeated calls alternate between the viewer and whatever Sidepanes currently considers the last terminal. If no terminal has ever been used, the first call from Markdown opens the Codex default.

`switch(entry)` and `ask_with_entry(entry, opts)` are internal and are not exposed on the public facade. Raw `entry` tables are not a stable user contract. Use `switch_to()` for public switching, and use `ask()`, `ask_picker()`, `ask_current_coding_agent()`, or `ask_last_coding_agent()` for public ask flows.

`require("sidepanes.internal")` exists for Sidepanes-owned implementation hooks such as scratch-buffer command mappings. Treat it as private and unstable.

Pane width can be adjusted at runtime:

```lua
require("sidepanes").set_width(100)    -- columns
require("sidepanes").set_width("50%")  -- percentage of editor columns
require("sidepanes").set_width("1/2")  -- screen fraction
require("sidepanes").set_width(0.5)    -- numeric screen ratio
require("sidepanes").adjust_width(10)  -- add columns
require("sidepanes").adjust_width(-10) -- subtract columns
require("sidepanes").snap_width("next")
require("sidepanes").snap_width("previous")
```

`layout.width` accepts the same absolute and relative width values during setup. The built-in default remains `100` columns.

When the Markdown viewer is active, width changes preserve the viewer cursor/scroll position and reflow/rerender Markdown if automatic reflow is enabled. Terminal panes are resized without Markdown reflow. Zoom still represents a temporary maximum-width mode; `set_width()` changes the normal pane width.

`layout.width_snap_points` configures the boundaries used by `snap_width("next")` and `snap_width("previous")`. Snap points accept the same width units as `set_width()`. The default global mappings are configurable; this config uses `<leader>p-` and `<leader>p+`.

Set `layout.sticky_relative_width = true` to keep relative width choices tied to the total Neovim width. With that enabled, `layout.width = "50%"`, `set_width("50%")`, `set_width("1/2")`, and `set_width(0.5)` remember their ratio and recompute when Neovim is resized. Absolute column widths and `adjust_width()` clear the sticky relative target. `toggle_sticky_relative_width()` toggles this behavior at runtime and captures the current normal pane width as the relative target when enabling it.

`_state()` is reserved for Sidepanes companion modules and tests. Treat it as internal and unstable.

Set `commands = true` to register the default `:Sidepanes*` commands. Set `mappings.global` to a table to install global mappings. `mappings.pane` customizes buffer-local pane mappings; set an entry to `false` to disable it.

`:Sidepanes` is the discoverable command surface. With no arguments it opens the pane switcher; with completion it exposes subcommands:

```vim
:Sidepanes switch
:Sidepanes open docs/notes.md
:Sidepanes codex gpt55_high_fast
:Sidepanes claude sonnet
:Sidepanes ipython
:Sidepanes ask-codex gpt55_high_fast
:Sidepanes width 100
:Sidepanes width 50%
:Sidepanes width +10
:Sidepanes help
```

With commands enabled, `:SidepanesWidth` accepts the same width values as `:Sidepanes width`.

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
