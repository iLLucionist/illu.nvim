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
      codex = "<leader>px",
      claude = "<leader>pc",
      ipython = "<leader>pi",
      focus = "<leader>pf",
      zoom = "<leader>pz",
      send_ipython = "<leader>pl",
      ask = "<leader>pa",
    },
  },
})
```

For reusable generated tool tables, use `require("sidepanes.presets").codex(...)` or `require("sidepanes.presets").claude(...)`.

Set `commands = true` to register the default `:Sidepanes*` and `:Pane*` commands. Set `mappings.global` to a table to install global mappings; pane-local mappings remain managed separately inside sidepanes buffers.
