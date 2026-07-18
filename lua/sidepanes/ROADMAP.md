# Sidepanes Roadmap

This is the living roadmap for `sidepanes.nvim`.

When discussing "what's next?", use this file as the reference point:

- State what is already done.
- State what is currently in progress.
- Propose the next roadmap refinement.
- Update this file when the roadmap changes materially.

## Current Status

Sidepanes has grown from a Markdown side viewer into a pane system for Markdown, Codex, Claude, and IPython. The main refactor work has already split most behavior out of `init.lua` into focused modules for configuration, commands, mappings, terminal sessions, questions, rendering/reflow, picker behavior, lifecycle, validation, health checks, and integrations.

Recently completed or in progress:

- Public facade boundary: mutable pane state is hidden from `require("sidepanes")`.
- `get_config()` returns a defensive copy of normalized config.
- `_state()` remains internal for companion modules and tests.
- `switch_to(target, opts)` is the stable public switch API.
- `make_switch_entry(target, opts)` validates and normalizes advanced switch targets.
- `switch(entry)` is internal and not exposed on the public facade.
- `ask_with_entry(entry, opts)` is internal and not exposed on the public facade.
- Scratch-buffer lifecycle callbacks moved to `sidepanes.internal`.
- `show_last_agent(opts)` and `toggle_markdown_agent()` are documented as advanced workflow helpers.
- Runtime width API exists through `get_width()`, `set_width(value)`, and `adjust_width(delta)`.
- Width commands exist through `:SidepanesWidth` and `:Sidepanes width`.
- Width values support columns, percentages, screen fractions, and deltas.
- Width changes reflow Markdown when the Markdown viewer is active and avoid Markdown reflow while a terminal pane is active.

## Roadmap

### 1. Commit Current API And Width Pass

Commit the current public API, switch target, width command, documentation, and regression coverage work.

Acceptance:

- `tests/run_sidepanes_checks.sh` passes.
- `:checkhealth sidepanes` has no Sidepanes warnings or errors in the normal configured environment.
- `ask_with_entry` remains absent from the public facade.
- `lua/sidepanes/api.lua` is tracked.

### 2. Public Surface Finalization

Status: completed.

Finalize which functions belong on `require("sidepanes")` and which belong behind internal/private module paths.

Current decision:

- Keep `switch_to(target, opts)` stable.
- Keep `make_switch_entry(target, opts)` advanced.
- Keep `switch(entry)` internal.
- Keep `ask_with_entry(entry, opts)` internal.
- Keep scratch-buffer lifecycle callbacks internal through `sidepanes.internal`.

Acceptance:

- `require("sidepanes").switch` is absent.
- `require("sidepanes").ask_with_entry` is absent.
- `require("sidepanes").finish_question`, `write_question`, `cancel_question`, and `change_question_target` are absent.
- Scratch prompt `:q` and `:wq` command-line mappings still work through `sidepanes.internal`.
- Full Sidepanes checks pass.

Completed refinement:

- Added `lua/sidepanes/internal.lua` for raw switch, raw ask-entry, and scratch-buffer lifecycle callbacks.
- Updated question-editor command-line mappings to call `sidepanes.internal`.
- Kept `require("sidepanes")` focused on stable and advanced public APIs.

### 3. Command And Mapping Polish

Decide whether width changes deserve default mappings or should remain command/API-only.

Possible mappings:

- `<leader>p+` to increase pane width.
- `<leader>p-` to decrease pane width.
- A picker or command prompt for exact width values.

Current leaning:

- Keep `:SidepanesWidth` as the primary interface unless repeated manual resizing becomes common.

### 4. Docs Split

The README is becoming dense. Split detailed API/config documentation into Neovim-native or plugin-local docs.

Options:

- `doc/sidepanes.txt` for `:help sidepanes`.
- `docs/sidepanes.md` for longer Markdown documentation.
- Keep README as a quickstart plus links.

Acceptance:

- Public API is documented.
- Advanced/unstable API is clearly labeled.
- Commands, mappings, config, health checks, and examples are discoverable.

### 5. Package Hygiene

Prepare Sidepanes as a proper standalone-ish Neovim plugin surface.

Possible work:

- Add `doc/sidepanes.txt`.
- Generate helptags-compatible sections.
- Keep module top-level comments consistent.
- Confirm no personal config assumptions leak into plugin modules.
- Keep personal `init.lua` as a consumer of the public setup/config surface.

### 6. Naming And API Cleanup Later

Consider renaming helpers whose names no longer perfectly match behavior.

Candidates:

- `show_last_agent()` -> `show_last_terminal()`
- `toggle_markdown_agent()` -> `toggle_markdown_terminal()`

Current leaning:

- Do not rename immediately.
- Keep current names documented because they match existing keymaps/workflow.
- Revisit only if the public surface becomes confusing.

## Testing Standard

Before calling roadmap work complete, run:

```sh
tests/run_sidepanes_checks.sh
```

For public API or dependency work, also run or verify:

- `:checkhealth sidepanes`
- public facade assertions for stable/hidden functions
- legacy module-name scan
- module top-level comment sweep

The goal is not mathematical proof. The goal is targeted coverage deep enough to catch realistic regressions in the changed behavior.
