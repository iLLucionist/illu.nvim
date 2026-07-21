# illu.nvim

Lua-based Neovim configuration and small local helpers.

## Sidepanes

`sidepanes.nvim` is installed from GitHub at `v0.2.0` and keeps a Markdown viewer, Codex,
Claude, and IPython in one reusable side pane.

Docs:

- Neovim help: `:help sidepanes`
- Plugin repository: [iLLucionist/sidepanes.nvim](https://github.com/iLLucionist/sidepanes.nvim)

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
:Sidepanes width previous
:Sidepanes width +
:Sidepanes width -
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

Run the local consumer smoke after changing the Sidepanes lazy.nvim spec:

```sh
tests/run_sidepanes_checks.sh
```

The full Sidepanes regression suite lives in
[iLLucionist/sidepanes.nvim](https://github.com/iLLucionist/sidepanes.nvim).

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
