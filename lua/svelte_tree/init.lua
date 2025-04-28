local Path = require("plenary.path")
local scan = require("plenary.scandir")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")

local M = {}

-- Parse imports and in-file component usage in order
local function parse_components_in_order(file)
  local components = {}

  for line in io.lines(file) do
    for tag in line:gmatch("<([A-Z][A-Za-z0-9_]*)") do
      table.insert(components, tag)
    end
  end

  return components
end

-- Build a hierarchical tree based on file component order
local function build_component_hierarchy(project_dir)
  local files = scan.scan_dir(project_dir, { depth = nil, search_pattern = ".*%.svelte$" })
  local name_to_path = {}
  local hierarchy = {}
  local used = {}

  for _, file in ipairs(files) do
    local filename = Path:new(file):make_relative(project_dir)
    local component_name = filename:gsub(".svelte$", ""):gsub(".*/", "")
    name_to_path[component_name] = filename
  end

  for name, path in pairs(name_to_path) do
    local full_path = Path:new(project_dir, path)
    local components = parse_components_in_order(full_path.filename)
    local stack = {}

    for _, comp in ipairs(components) do
      if not stack[#stack] then
        hierarchy[comp] = hierarchy[comp] or {}
        table.insert(stack, comp)
      else
        hierarchy[stack[#stack]] = hierarchy[stack[#stack]] or {}
        table.insert(hierarchy[stack[#stack]], comp)
        table.insert(stack, comp)
      end
      used[comp] = true
    end
  end

  return hierarchy, name_to_path
end

-- Recursively format the tree
local function format_tree(hierarchy, roots)
  local result = {}
  local visited = {}

  local function recurse(name, depth)
    if visited[name] then
      table.insert(result, { display = string.rep("  ", depth) .. "↪ " .. name .. " (circular)", name = name })
      return
    end
    visited[name] = true
    table.insert(result, { display = string.rep("  ", depth) .. "├─ " .. name, name = name })

    if hierarchy[name] then
      for _, child in ipairs(hierarchy[name]) do
        recurse(child, depth + 1)
      end
    end

    visited[name] = false
  end

  for _, root in ipairs(roots) do
    recurse(root, 0)
  end

  return result
end

-- Find root components (appearing first)
local function find_roots(hierarchy)
  local roots = {}
  local referenced = {}

  for parent, children in pairs(hierarchy) do
    for _, child in ipairs(children) do
      referenced[child] = true
    end
  end

  for parent, _ in pairs(hierarchy) do
    if not referenced[parent] then
      table.insert(roots, parent)
    end
  end

  return roots
end

function M.svelte_hierarchy()
  local cwd = vim.loop.cwd()
  local hierarchy, name_to_path = build_component_hierarchy(cwd)
  local roots = find_roots(hierarchy)
  local formatted = format_tree(hierarchy, roots)

  pickers.new({}, {
    prompt_title = "Svelte Component Hierarchy",
    finder = finders.new_table {
      results = formatted,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.display,
        }
      end,
    },
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry, _)
        local component = entry.value.name
        local rel_path = name_to_path[component]
        if rel_path then
          local full_path = Path:new(cwd, rel_path):absolute()
          local lines = vim.fn.readfile(full_path)
          table.insert(lines, 1, "// " .. rel_path)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "svelte")
        else
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"No preview available"})
        end
      end
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function open_file()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.value and selection.value.name then
          local component = selection.value.name
          local rel_path = name_to_path[component]
          if rel_path then
            vim.cmd("edit " .. Path:new(cwd, rel_path):absolute())
          else
            vim.notify("Component file not found", vim.log.levels.ERROR)
          end
        else
          vim.notify("No valid selection", vim.log.levels.ERROR)
        end
      end

      map("i", "<CR>", open_file)
      map("n", "<CR>", open_file)
      return true
    end,
  }):find()
end

return M
