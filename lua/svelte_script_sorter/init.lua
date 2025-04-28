local M = {}

local patterns = {
  SVELTE = "import .- from ['\"]svelte",
  COMPONENTS = "import .- from ['\"]%./components",
  STORES = "import .-from.*/stores",
  TYPES = {
    "import type .- from",
    "^type (?!Props)%w+%s-=", -- all types except Props
  },
  PROPS_TYPE = "^type%s+Props%s-=",
  PROPS_LET = "^let%s+%$props%s-=",
  VARIABLES = "^let ",
  REACTIVE = {
    "reactive%(%s*%(%s*%)%s*=>",
    "derived%(",
  },
  EVENTS = "function (handle%u%w*|on%u%w*)",
  FUNCTIONS = "function %w+%s*%(",
}

local section_order = {
  "SVELTE",
  "COMPONENTS",
  "STORES",
  "TYPES",
  "PROPS",
  "VARIABLES",
  "REACTIVE",
  "FUNCTIONS",
  "EVENTS",
}

function M.reorder_script_block(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local script_start, script_end
  for i, line in ipairs(lines) do
    if line:match("<script.-lang=['\"]ts['\"]>") then
      script_start = i
    elseif line:match("</script>") and script_start then
      script_end = i
      break
    end
  end

  if not (script_start and script_end) then
    vim.notify("No <script lang=\"ts\"> block found", vim.log.levels.WARN)
    return
  end

  -- Categorized storage
  local categorized = {}
  for _, cat in ipairs(section_order) do
    categorized[cat] = {}
  end
  local uncategorized = {}

  local i = script_start + 1
  while i < script_end do
    local line = lines[i]
    local matched = false

    -- Special: capture whole type Props block
    if line:match(patterns.PROPS_TYPE) then
      local block = { line }
      i = i + 1
      while i < script_end and not lines[i]:match("^}") do
        table.insert(block, lines[i])
        i = i + 1
      end
      if i < script_end then
        table.insert(block, lines[i]) -- capture closing }
      end
      vim.list_extend(categorized["PROPS"], block)
      matched = true

    -- Special: capture let $props
    elseif line:match(patterns.PROPS_LET) then
      table.insert(categorized["PROPS"], line)
      matched = true

    else
      for cat, pat in pairs(patterns) do
        if type(pat) == "table" then
          for _, subpat in ipairs(pat) do
            if line:match(subpat) then
              table.insert(categorized[cat], line)
              matched = true
              break
            end
          end
        else
          if line:match(pat) then
            table.insert(categorized[cat], line)
            matched = true
          end
        end
        if matched then break end
      end
    end

    if not matched then
      table.insert(uncategorized, line)
    end

    i = i + 1
  end

  -- Rebuild lines
  local new_script_lines = {}

  for _, cat in ipairs(section_order) do
    if #categorized[cat] > 0 then
      if #new_script_lines > 0 then
        table.insert(new_script_lines, "")
        table.insert(new_script_lines, "")
      end
      table.insert(new_script_lines, "// " .. cat)
      vim.list_extend(new_script_lines, categorized[cat])
    end
  end

  if #uncategorized > 0 then
    table.insert(new_script_lines, "")
    table.insert(new_script_lines, "")
    table.insert(new_script_lines, "// UNCATEGORIZED")
    vim.list_extend(new_script_lines, uncategorized)
  end

  -- Add back the closing </script>
  table.insert(new_script_lines, "")
  table.insert(new_script_lines, "</script>")

  -- Replace the script content without touching <script> tag
  vim.api.nvim_buf_set_lines(bufnr, script_start + 1, script_end + 1, false, new_script_lines)
end

return M
