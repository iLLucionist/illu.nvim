local M = {}

local function trim(text)
    local trimmed = text:gsub("^%s+", ""):gsub("%s+$", "")

    return trimmed
end

local function display_width(text)
    return vim.fn.strdisplaywidth(text)
end

local function target_width(opts)
    if opts and opts.width and opts.width > 0 then
        return opts.width
    end

    local ok, markdown_pane = pcall(require, "markdown_pane")

    if ok and markdown_pane.is_open and markdown_pane.is_open() and markdown_pane.text_width then
        local pane_width = markdown_pane.text_width()

        if pane_width and pane_width > 0 then
            return pane_width
        end
    end

    if vim.bo.textwidth > 0 then
        return vim.bo.textwidth
    end

    return 80
end

local function setext_underline(line)
    return line:match("^%s*[=-]+%s*$") ~= nil
end

local function fenced_delimiter(line)
    return line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
end

local function mark_protected(lines)
    local protected = {}
    local in_fence = false

    if lines[1] and lines[1]:match("^%s*%-%-%-%s*$") then
        protected[1] = true

        for i = 2, #lines do
            protected[i] = true

            if lines[i]:match("^%s*(%-%-%-|%.%.%.)%s*$") then
                break
            end
        end
    end

    for i, line in ipairs(lines) do
        if protected[i] then
            goto continue
        end

        if fenced_delimiter(line) then
            in_fence = not in_fence
            protected[i] = true
        elseif in_fence then
            protected[i] = true
        end

        ::continue::
    end

    return protected
end

local function special_markdown_line(lines, index)
    local line = lines[index]
    local next_line = lines[index + 1]

    if line == "" or line:match("^%s*$") then
        return true
    end

    if next_line and setext_underline(next_line) then
        return true
    end

    if setext_underline(line) then
        return true
    end

    local patterns = {
        "^%s*#",
        "^%s*%-%-%-%s*$",
        "^%s*%*%*%*%s*$",
        "^%s*___%s*$",
        "^%s*|",
        "|%s*$",
        "^%s*%[.-%]:",
        "^%s*%[%^.-%]:",
        "^%s*!%[",
        "^%s*<[/!%a]",
        "^%s*:::",
    }

    for _, pattern in ipairs(patterns) do
        if line:match(pattern) then
            return true
        end
    end

    return false
end

local function line_kind(lines, protected, index)
    if protected[index] then
        return nil
    end

    local line = lines[index]

    if line:match("^%s%s%s%s%S") or line:match("^\t%S") then
        return nil
    end

    if special_markdown_line(lines, index) then
        return nil
    end

    local quote_indent, quote_text = line:match("^(%s*>%s?)(.*)$")

    if quote_indent then
        if quote_text:match("^%s*$") then
            return nil
        end

        return {
            name = "quote",
            first_prefix = quote_indent,
            rest_prefix = quote_indent,
            text = quote_text,
        }
    end

    local task_indent, task_marker, task_state, task_text = line:match("^(%s*)([%-%*%+])%s+%[([ xX%-])%]%s+(.*)$")

    if task_indent then
        local first_prefix = task_indent .. task_marker .. " [" .. task_state .. "] "

        return {
            name = "list",
            first_prefix = first_prefix,
            rest_prefix = string.rep(" ", display_width(first_prefix)),
            text = task_text,
        }
    end

    local bullet_indent, bullet_marker, bullet_text = line:match("^(%s*)([%-%*%+])%s+(.*)$")

    if bullet_indent then
        local first_prefix = bullet_indent .. bullet_marker .. " "

        return {
            name = "list",
            first_prefix = first_prefix,
            rest_prefix = string.rep(" ", display_width(first_prefix)),
            text = bullet_text,
        }
    end

    local ordered_indent, ordered_marker, ordered_text = line:match("^(%s*)(%d+[%.%)])%s+(.*)$")

    if ordered_indent then
        local first_prefix = ordered_indent .. ordered_marker .. " "

        return {
            name = "list",
            first_prefix = first_prefix,
            rest_prefix = string.rep(" ", display_width(first_prefix)),
            text = ordered_text,
        }
    end

    return {
        name = "paragraph",
        first_prefix = line:match("^(%s*)") or "",
        rest_prefix = line:match("^(%s*)") or "",
        text = trim(line),
    }
end

local function same_kind(a, b)
    if not a or not b or a.name ~= b.name then
        return false
    end

    if a.name == "paragraph" or a.name == "quote" then
        return a.first_prefix == b.first_prefix
    end

    return false
end

local function list_continuation_text(lines, protected, index, rest_prefix)
    if protected[index] or rest_prefix == "" then
        return nil
    end

    local line = lines[index]

    if line == "" or line:match("^%s*$") then
        return nil
    end

    if special_markdown_line(lines, index) then
        return nil
    end

    if line:sub(1, #rest_prefix) ~= rest_prefix then
        return nil
    end

    local text = line:sub(#rest_prefix + 1)

    if text:match("^%s*[%-%*%+]%s+%[[ xX%-]%]%s+")
        or text:match("^%s*[%-%*%+]%s+")
        or text:match("^%s*%d+[%.%)]%s+")
    then
        return nil
    end

    return text
end

local function wrap_text(text, width, first_prefix, rest_prefix)
    local lines = {}
    local current = ""
    local prefix = first_prefix

    for word in text:gmatch("%S+") do
        local candidate = current == "" and (prefix .. word) or (current .. " " .. word)

        if current == "" or display_width(candidate) <= width then
            current = candidate
        else
            table.insert(lines, current)
            prefix = rest_prefix
            current = prefix .. word
        end
    end

    if current ~= "" then
        table.insert(lines, current)
    end

    return lines
end

function M.reflow_buffer(bufnr, opts)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    opts = opts or {}

    if not opts.force and vim.api.nvim_get_option_value("modifiable", { buf = bufnr }) == false then
        vim.notify("Buffer is not modifiable", vim.log.levels.WARN)
        return 0
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local protected = mark_protected(lines)
    local output = {}
    local changed = 0
    local paragraph_count = 0
    local width = target_width(opts)
    local i = 1

    while i <= #lines do
        local kind = line_kind(lines, protected, i)

        if kind then
            local start = i
            local paragraph = {}
            local first_prefix = kind.first_prefix
            local rest_prefix = kind.rest_prefix

            while i <= #lines do
                local next_kind = line_kind(lines, protected, i)

                if i == start then
                    table.insert(paragraph, trim(next_kind.text))
                    i = i + 1
                elseif kind.name == "list" then
                    local continuation = list_continuation_text(lines, protected, i, rest_prefix)

                    if not continuation then
                        break
                    end

                    table.insert(paragraph, trim(continuation))
                    i = i + 1
                elseif same_kind(kind, next_kind) then
                    table.insert(paragraph, trim(next_kind.text))
                    i = i + 1
                else
                    break
                end
            end

            local wrapped = wrap_text(table.concat(paragraph, " "), width, first_prefix, rest_prefix)
            vim.list_extend(output, wrapped)
            paragraph_count = paragraph_count + 1

            if #wrapped ~= (i - start) then
                changed = changed + 1
            else
                for offset, wrapped_line in ipairs(wrapped) do
                    if wrapped_line ~= lines[start + offset - 1] then
                        changed = changed + 1
                        break
                    end
                end
            end
        else
            table.insert(output, lines[i])
            i = i + 1
        end
    end

    if changed > 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
    end

    if opts.notify ~= false then
        vim.notify(string.format("Reflowed %d Markdown paragraphs at width %d", paragraph_count, width))
    end

    return paragraph_count
end

return M
