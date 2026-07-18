--[[
sidepanes.lifecycle
Purpose: Manage plugin setup-time configuration and global lifecycle autocmds.
Does: Merges user options and installs focus tracking plus graceful terminal shutdown on Neovim exit.
Architecture: Keeps autocmd setup separate from init.lua while delegating user-facing config expansion to config.lua.
]]

local config = require("sidepanes.config")

local M = {}

--- Merge user configuration and install pane lifecycle autocmds.
function M.setup(state, groups, deps, opts)
    state.config = config.normalize(state.config, opts or {})

    vim.api.nvim_clear_autocmds({ group = groups.focus })
    vim.api.nvim_create_autocmd("WinEnter", {
        group = groups.focus,
        callback = function()
            deps.record_focus_win()
        end,
    })

    vim.api.nvim_clear_autocmds({ group = groups.shutdown })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = groups.shutdown,
        callback = function()
            if state.config.shutdown_on_exit then
                deps.shutdown_terminals()
            end
        end,
    })
end

return M
