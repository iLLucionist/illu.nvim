--[[
sidepanes.config
Purpose: Normalize user-facing setup options into the internal runtime config.
Does: Expands ergonomic markdown/tool options, delegates preset generation, preserves legacy option names, and applies cumulative setup merges.
Architecture: Forms the boundary between public setup() input and the state.config table consumed by viewer, render, terminal, and switcher modules.
]]

local presets = require("sidepanes.presets")

local M = {}

--- Assign a value only when the source option was explicitly configured.
local function set_if_present(target, key, value)
    if value ~= nil then
        target[key] = value
    end
end

--- Expand nested markdown reflow options to the internal flat config keys.
local function expand_markdown(opts)
    local expanded = vim.deepcopy(opts or {})
    local markdown = expanded.markdown or {}
    local reflow = markdown.reflow or {}

    set_if_present(expanded, "wrap", markdown.wrap)
    set_if_present(expanded, "wrap_toggle_key", markdown.wrap_toggle_key)
    set_if_present(expanded, "auto_reflow", reflow.enabled)
    set_if_present(expanded, "external_reflow_cmd", reflow.cmd)
    set_if_present(expanded, "external_reflow_fallback", reflow.fallback)
    set_if_present(expanded, "external_reflow_protect_tables", reflow.protect_tables)
    set_if_present(expanded, "reflow_margin", reflow.margin)
    expanded.markdown = nil

    return expanded
end

--- Expand known tool shorthand while preserving custom tool config tables.
local function expand_tools(opts)
    local expanded = vim.deepcopy(opts or {})

    if not expanded.tools then
        return expanded
    end

    for tool_name, tool_opts in pairs(expanded.tools) do
        if tool_opts == false then
            expanded.tools[tool_name] = { enabled = false }
        elseif type(tool_opts) ~= "table" then
            expanded.tools[tool_name] = tool_opts
        else
            expanded.tools[tool_name] = presets.expand_tool(tool_name, tool_opts)
            expanded.tools[tool_name].enabled = nil
        end
    end

    return expanded
end

--- Remove tools explicitly disabled in the user-facing setup table.
local function remove_disabled_tools(config, opts)
    for tool_name, tool_opts in pairs((opts or {}).tools or {}) do
        if tool_opts == false or (type(tool_opts) == "table" and tool_opts.enabled == false) then
            config.tools = config.tools or {}
            config.tools[tool_name] = nil
        end
    end
end

--- Expand ergonomic setup options without merging them into a base config.
function M.expand(opts)
    return expand_tools(expand_markdown(opts or {}))
end

--- Merge setup options into a base config after expanding ergonomic options.
function M.normalize(base, opts)
    local expanded = M.expand(opts or {})
    local result = vim.tbl_deep_extend("force", vim.deepcopy(base or {}), expanded)

    remove_disabled_tools(result, opts)

    return result
end

return M
