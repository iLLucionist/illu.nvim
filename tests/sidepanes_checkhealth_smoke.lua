--[[
sidepanes_checkhealth_smoke
Purpose: Exercise the real :checkhealth sidepanes command path.
Does: Runs Neovim's health command, inspects the generated report buffer, and fails on Sidepanes warnings or errors.
Architecture: Complements sidepanes_audit_smoke.lua by testing Neovim's command-facing health integration instead of calling the health module directly.
]]

vim.opt.runtimepath:append("/Users/maximl/.config/nvim/illu.nvim")

vim.cmd("checkhealth sidepanes")

local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local report = table.concat(lines, "\n")

assert(report:find("sidepanes.nvim loaded", 1, true), "health report did not load sidepanes:\n" .. report)
assert(
    report:find("built-in sidepanes.markdown_reflow module found", 1, true),
    "health report did not include built-in markdown_reflow module:\n" .. report
)
assert(report:find("Codex presets configured: 12", 1, true), "health report did not include Codex presets:\n" .. report)
assert(report:find("Command registered: :Sidepanes", 1, true), "health report did not include root command:\n" .. report)
assert(report:find("Global mapping registered (n, x): <leader>pl", 1, true), "health report did not include global mapping modes:\n" .. report)
assert(report:find("Pane-local mapping configured (x): aa", 1, true), "health report did not include pane-local mapping modes:\n" .. report)

for _, pattern in ipairs({ "ERROR", "WARNING", "WARN", "❌", "⚠" }) do
    assert(not report:find(pattern, 1, true), "health report contained " .. pattern .. ":\n" .. report)
end

print("sidepanes checkhealth smoke passed")
