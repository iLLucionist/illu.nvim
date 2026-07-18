--[[
smart_gf
Purpose: Preserve the historical `require("smart_gf")` entry point.
Does: Re-exports Sidepanes' built-in smart gf implementation.
Architecture: Compatibility shim for older config and tests; new Sidepanes code should require `sidepanes.smart_gf` directly.
]]

return require("sidepanes.smart_gf")
