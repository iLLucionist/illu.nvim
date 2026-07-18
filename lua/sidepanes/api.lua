--[[
sidepanes.api
Purpose: Normalize user-facing API inputs into Sidepanes internal operations.
Does: Converts public switch targets into switcher entries and resolves width values from columns, percentages, fractions, and deltas.
Architecture: Sits between init.lua's public facade and lower-level switcher/window modules so public contracts stay stable while internals can evolve.
]]

local entries = require("sidepanes.entries")

local M = {}

local markdown_aliases = {
    ["0"] = true,
    doc = true,
    document = true,
    markdown = true,
    viewer = true,
}

local tool_aliases = {
    c = "claude",
    i = "ipython",
    x = "codex",
}

--- Return a trimmed string representation for user API parsing.
local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

--- Return whether a public value names the markdown viewer.
local function is_markdown_alias(value)
    if type(value) ~= "string" then
        return false
    end

    return markdown_aliases[value] or markdown_aliases[value:lower()]
end

--- Return the configured tool name for a public string or alias.
local function normalize_tool_name(state, value)
    local tools = ((state.config or {}).tools or {})

    if tools[value] then
        return value
    end

    local lower = type(value) == "string" and value:lower() or value
    local name = tool_aliases[lower] or lower

    if tools[name] then
        return name
    end

    return nil
end

--- Return whether a preset name or label exists for a tool.
local function preset_exists(tool, preset_name)
    if not preset_name or preset_name == "" then
        return true
    end

    for _, preset in ipairs(tool.presets or {}) do
        if preset.name == preset_name or preset.label == preset_name then
            return true
        end
    end

    return false
end

--- Return a validated terminal switch entry for a configured tool.
local function terminal_entry(state, tool_name, opts)
    opts = opts or {}

    local tool = ((state.config or {}).tools or {})[tool_name]

    if not tool then
        return nil, "Unknown pane tool: " .. tostring(tool_name)
    end

    local preset_name = opts.preset_name or opts.preset

    if not preset_exists(tool, preset_name) then
        return nil, "Unknown " .. tostring(tool.label or tool_name) .. " preset: " .. tostring(preset_name)
    end

    local preset = entries.preset_by_name(tool, preset_name)

    return {
        kind = "terminal",
        tool_name = tool_name,
        preset_name = preset and preset.name or preset_name,
        root = opts.root,
        bufnr = opts.bufnr,
        focus = opts.focus,
    }
end

--- Normalize a string target such as "markdown", "codex", "x", or "i".
local function string_entry(state, target, opts)
    local value = trim(target)

    if is_markdown_alias(value) then
        return {
            kind = "markdown",
            focus = opts and opts.focus,
        }
    end

    local tool_name = normalize_tool_name(state, value)

    if tool_name then
        return terminal_entry(state, tool_name, opts)
    end

    return nil, "Unknown pane target: " .. tostring(target)
end

--- Normalize a table target or already-built switcher entry.
local function table_entry(state, target, opts)
    opts = vim.tbl_deep_extend("force", {}, target or {}, opts or {})

    if target.kind == "markdown" or is_markdown_alias(target.target) or is_markdown_alias(target.name) then
        return {
            kind = "markdown",
            focus = opts.focus,
        }
    end

    local tool_name = target.tool_name or target.tool or target.name or target.target

    if target.kind == "terminal" or target.kind == "tool" or tool_name then
        tool_name = normalize_tool_name(state, tool_name)

        if not tool_name then
            return nil, "Unknown pane tool: " .. tostring(target.tool_name or target.tool or target.name or target.target)
        end

        return terminal_entry(state, tool_name, opts)
    end

    return nil, "Switch target table needs kind='markdown', kind='terminal', or a tool field"
end

--- Build a validated internal switcher entry from public input.
---
--- Supported string targets:
---   "markdown", "doc", "document", "viewer", "0"
---   configured tool names such as "codex", "claude", "ipython"
---   built-in shortcuts "x", "c", and "i"
---
--- Supported table targets:
---   { kind = "markdown" }
---   { tool = "codex", preset = "gpt55_high_fast", root = "/repo", focus = true }
---   { kind = "terminal", tool_name = "codex", preset_name = "gpt55_high_fast" }
---   { target = "x" }
---
--- Presets may be addressed by name or label. The returned entry is meant for Sidepanes'
--- switcher and should be treated as normalized but still implementation-shaped.
function M.make_switch_entry(state, target, opts)
    if type(target) == "string" then
        return string_entry(state, target, opts)
    end

    if type(target) == "table" then
        return table_entry(state, target, opts)
    end

    return nil, "Switch target must be a string or table"
end

--- Return the largest sensible non-floating pane width for the current screen.
function M.max_width()
    local reserved = math.max(1, tonumber(vim.o.winminwidth) or 1)
    local separator = 1

    return math.max(20, vim.o.columns - reserved - separator)
end

--- Clamp a resolved pane width to a usable column count.
function M.clamp_width(width)
    return math.max(20, math.min(math.floor(width), M.max_width()))
end

--- Resolve a user width value into columns.
function M.resolve_width(value, current_width)
    if type(value) == "number" then
        if value > 0 and value < 1 then
            return M.clamp_width(vim.o.columns * value)
        end

        if value >= 1 then
            return M.clamp_width(value)
        end

        return nil, "Width must be positive"
    end

    if type(value) ~= "string" then
        return nil, "Width must be a number or string"
    end

    local text = trim(value)
    local delta = text:match("^([+-]%d+)$")

    if delta then
        if not current_width then
            return nil, "Relative width needs a current width"
        end

        return M.clamp_width(current_width + tonumber(delta))
    end

    local percent = text:match("^(%d+%.?%d*)%%$")

    if percent then
        percent = tonumber(percent)

        if not percent or percent <= 0 then
            return nil, "Percentage width must be positive"
        end

        return M.clamp_width(vim.o.columns * percent / 100)
    end

    local numerator, denominator = text:match("^(%d+%.?%d*)/(%d+%.?%d*)$")

    if numerator and denominator then
        numerator = tonumber(numerator)
        denominator = tonumber(denominator)

        if not numerator or not denominator or numerator <= 0 or denominator <= 0 then
            return nil, "Fraction width must be positive"
        end

        return M.clamp_width(vim.o.columns * numerator / denominator)
    end

    local numeric = tonumber(text)

    if numeric then
        return M.resolve_width(numeric, current_width)
    end

    return nil, "Could not parse pane width: " .. tostring(value)
end

--- Resolve a width delta into a new absolute width.
function M.resolve_width_delta(delta, current_width)
    if type(delta) == "number" then
        return M.resolve_width(current_width + delta, current_width)
    end

    local text = trim(delta)

    if text:match("^[+-]%d+$") then
        return M.resolve_width(text, current_width)
    end

    local numeric = tonumber(text)

    if numeric then
        return M.resolve_width(current_width + numeric, current_width)
    end

    return nil, "Could not parse pane width delta: " .. tostring(delta)
end

return M
