# illu.nvim

Lua-based Neovim configuration and local plugins.

## Sidepanes

`sidepanes.nvim` keeps a Markdown viewer, Codex, Claude, and IPython in one
reusable side pane.

Docs:

- Neovim help: `:help sidepanes`
- Markdown reference: [doc/sidepanes.md](doc/sidepanes.md)
- Roadmap: [lua/sidepanes/ROADMAP.md](lua/sidepanes/ROADMAP.md)

Quick commands:

```vim
:Sidepanes
:Sidepanes help
:Sidepanes switch
:Sidepanes codex gpt55_high_fast
:Sidepanes claude sonnet
:Sidepanes ipython
:Sidepanes width 100
:Sidepanes width next
:Sidepanes width pick
:Sidepanes ask
```

Quick API:

```lua
local sidepanes = require("sidepanes")

sidepanes.setup({
  commands = true,
  mappings = {
    global = {
      toggle = "<leader>pp",
      pick = "<leader>mP",
      headings = "<leader>fm",
      markdown = "<leader>p0",
      codex = "<leader>px",
      claude = "<leader>pc",
      ipython = "<leader>pi",
      focus = "<leader>pf",
      zoom = "<leader>pz",
      width_previous = "<leader>p-",
      width_next = "<leader>p+",
      width_picker = "<leader>pw",
      sticky_relative_width = "<leader>p%",
      send_ipython = "<leader>pl",
      ask = "<leader>pa",
    },
  },
})
```

Run checks before Sidepanes refactors:

```sh
tests/run_sidepanes_checks.sh
```

## Markdown Reflow

Markdown reflow is currently shipped inside Sidepanes as
`sidepanes.markdown_reflow`. It is still isolated behind that module path so it
can become its own plugin later without disturbing Sidepanes internals.

```lua
require("sidepanes.markdown_reflow").setup({
  external_reflow_cmd = { "mdfmt", "--stdin", "--width", "{width}", "--wrap", "always" },
  external_reflow_protect_tables = true,
  commands = true,
  mappings = {
    reflow = "<leader>mR",
  },
})
```
