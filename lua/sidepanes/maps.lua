--[[
sidepanes.maps
Purpose: Install pane-local keymaps for markdown and terminal pane buffers.
Does: Binds quick pane switching, smart gf, ask mappings, and markdown wrap toggling with buffer-local scope.
Architecture: Receives behavior through dependency callbacks from init.lua so mappings stay declarative and do not own plugin state.
]]

local M = {}

--- Install one buffer-local pane mapping.
local function map(bufnr, mode, lhs, rhs, desc, opts)
    opts = opts or {}

    vim.keymap.set(mode, lhs, rhs, {
        buffer = bufnr,
        desc = desc,
        silent = true,
        nowait = opts.nowait,
    })
end

--- Build visual-selection options for pane ask mappings.
local function visual_opts(bufnr)
    return {
        bufnr = bufnr,
        visual = true,
        visual_mode = vim.fn.mode(1),
    }
end

--- Install pane-local normal and visual mappings for one pane buffer.
function M.setup(bufnr, deps)
    deps = deps or {}

    map(bufnr, "n", "<space>0", function()
        deps.show_markdown()
    end, "Show sidepanes", { nowait = true })

    map(bufnr, "n", "<space>x", function()
        deps.open_terminal("codex", nil, { root = deps.pane_root(bufnr), focus = true })
    end, "Show Codex pane", { nowait = true })

    map(bufnr, "n", "<space>c", function()
        deps.open_terminal("claude", nil, { root = deps.pane_root(bufnr), focus = true })
    end, "Show Claude pane", { nowait = true })

    map(bufnr, "n", "<space>i", function()
        deps.open_terminal("ipython", nil, { root = deps.pane_root(bufnr), focus = true })
    end, "Show IPython pane", { nowait = true })

    map(bufnr, "n", "<leader>gg", function()
        deps.toggle_markdown_agent()
    end, "Toggle markdown/agent pane")

    map(bufnr, "n", "<C-g>", function()
        deps.toggle_markdown_agent()
    end, "Toggle markdown/agent pane")

    map(bufnr, "n", "<leader>gi", function()
        deps.open_terminal("ipython", nil, { root = deps.pane_root(bufnr), focus = true })
    end, "Show IPython pane")

    map(bufnr, "n", "gf", function()
        require("smart_gf").open()
    end, "Smart go to file from pane")

    map(bufnr, "x", "aa", function()
        deps.ask_last_coding_agent(visual_opts(bufnr))
    end, "Ask last coding agent")

    map(bufnr, "x", "ax", function()
        deps.ask_current_coding_agent("codex", visual_opts(bufnr))
    end, "Ask current Codex pane")

    map(bufnr, "x", "ac", function()
        deps.ask_current_coding_agent("claude", visual_opts(bufnr))
    end, "Ask current Claude pane")

    if bufnr == deps.markdown_bufnr() then
        map(bufnr, "n", deps.wrap_toggle_key(), function()
            deps.toggle_wrap()
        end, "Toggle sidepanes wrap")
    end
end

return M
