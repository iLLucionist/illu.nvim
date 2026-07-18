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
})
```

For reusable generated tool tables, use `require("sidepanes.presets").codex(...)` or `require("sidepanes.presets").claude(...)`.
