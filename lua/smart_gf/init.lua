local M = {}

local function valid_buf(bufnr)
    return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function valid_win(winid)
    return winid and vim.api.nvim_win_is_valid(winid)
end

local function normalize_path(path)
    if not path or path == "" then
        return nil
    end

    return vim.fn.fnamemodify(path, ":p")
end

local function path_exists(path)
    return path and vim.uv.fs_stat(path) ~= nil
end

local function current_context()
    local bufnr = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(bufnr)

    local ok, markdown_pane = pcall(require, "markdown_pane")
    local is_markdown_pane = false

    if ok and valid_buf(markdown_pane.bufnr) and bufnr == markdown_pane.bufnr and markdown_pane.source then
        path = markdown_pane.source
        is_markdown_pane = true
    end

    path = normalize_path(path)

    local root = nil

    if path then
        if vim.fs and vim.fs.root then
            root = vim.fs.root(path, { ".git", "pyproject.toml", "package.json", "Cargo.toml", "go.mod" })
        end

        if not root and vim.fs and vim.fs.find then
            local found = vim.fs.find({ ".git", "pyproject.toml", "package.json", "Cargo.toml", "go.mod" }, {
                path = vim.fn.fnamemodify(path, ":h"),
                upward = true,
            })[1]

            if found then
                root = vim.fn.fnamemodify(found, ":p:h")
            end
        end
    end

    root = normalize_path(root or vim.fn.getcwd())

    return {
        bufnr = bufnr,
        path = path,
        dir = path and vim.fn.fnamemodify(path, ":h") or vim.fn.getcwd(),
        root = root,
        is_markdown_pane = is_markdown_pane,
        markdown_pane = ok and markdown_pane or nil,
    }
end

local function clean_target(target)
    target = target or vim.fn.expand("<cfile>")
    target = target:gsub("^%s+", ""):gsub("%s+$", "")
    target = target:gsub("^[`'\"(<%[]+", "")
    target = target:gsub("[`'\".,;:)%]>]+$", "")

    if target:match("^%a[%w+.-]*://") then
        return nil
    end

    return target ~= "" and target or nil
end

local function exact_candidates(target, ctx)
    local candidates = {}

    local function add(path)
        path = normalize_path(path)

        if path and path_exists(path) then
            candidates[path] = true
        end
    end

    if target:sub(1, 1) == "/" then
        add(target)
    else
        add(ctx.dir .. "/" .. target)
        add(ctx.root .. "/" .. target)
    end

    return candidates
end

local function project_files(root)
    if vim.fn.executable("rg") == 1 then
        local files = vim.fn.systemlist({ "rg", "--files", "--hidden", "--glob", "!.git", root })

        if vim.v.shell_error == 0 then
            return files
        end
    end

    local result = {}

    for path, kind in vim.fs.dir(root, { depth = 16 }) do
        if kind == "file" and not path:find("/%.git/") then
            table.insert(result, root .. "/" .. path)
        end
    end

    return result
end

local function common_prefix_score(a, b)
    if not a or not b then
        return 0
    end

    local score = 0
    local a_parts = vim.split(vim.fn.fnamemodify(a, ":p"), "/", { trimempty = true })
    local b_parts = vim.split(vim.fn.fnamemodify(b, ":p"), "/", { trimempty = true })

    for index, part in ipairs(a_parts) do
        if b_parts[index] ~= part then
            break
        end

        score = score + 1
    end

    return score
end

local function candidate_score(path, target, ctx)
    local basename = vim.fn.fnamemodify(path, ":t")
    local relative = vim.fn.fnamemodify(path, ":p"):sub(#ctx.root + 1)
    local score = 0
    local matched = false

    if relative == target then
        score = score + 10000
        matched = true
    end

    if relative:sub(-#target) == target then
        score = score + 6000
        matched = true
    end

    if basename == target then
        score = score + 5000
        matched = true
    elseif basename:lower() == target:lower() then
        score = score + 4500
        matched = true
    elseif basename:find(vim.pesc(target), 1) then
        score = score + 1500
        matched = true
    elseif relative:find(vim.pesc(target), 1) then
        score = score + 800
        matched = true
    end

    if not matched then
        return -math.huge
    end

    score = score + common_prefix_score(ctx.path, path) * 10

    if relative:match("^src/") or relative:match("^lua/") or relative:match("^lib/") then
        score = score + 40
    end

    score = score - math.min(#relative, 500) / 100

    return score
end

local function best_project_match(target, ctx)
    local exact = exact_candidates(target, ctx)

    for path in pairs(exact) do
        return path
    end

    local best = nil
    local best_score = -math.huge

    for _, path in ipairs(project_files(ctx.root)) do
        local score = candidate_score(path, target, ctx)

        if score > best_score then
            best = path
            best_score = score
        end
    end

    if best and best_score > 0 then
        return best
    end

    return nil
end

local function best_buffer_match(target, ctx)
    local best = nil
    local best_score = -math.huge

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if valid_buf(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
            local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))

            if path then
                local score = candidate_score(path, target, ctx)

                if score > best_score then
                    best = {
                        bufnr = bufnr,
                        path = path,
                    }
                    best_score = score
                end
            end
        end
    end

    if best and best_score > 0 then
        return best
    end

    return nil
end

local function target_window(ctx, bufnr)
    if bufnr then
        for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
            if valid_win(winid) and not (ctx.markdown_pane and winid == ctx.markdown_pane.winid) then
                return winid
            end
        end
    end

    if ctx.is_markdown_pane and ctx.markdown_pane then
        local winid = ctx.markdown_pane.last_focus_win

        if not valid_win(winid) or winid == ctx.markdown_pane.winid then
            pcall(vim.cmd, "wincmd p")
            winid = vim.api.nvim_get_current_win()
        end

        if valid_win(winid) and winid ~= ctx.markdown_pane.winid then
            return winid
        end
    end

    return vim.api.nvim_get_current_win()
end

function M.open()
    local target = clean_target()

    if not target then
        vim.notify("No file target under cursor", vim.log.levels.WARN)
        return
    end

    local ctx = current_context()
    local buffer_match = best_buffer_match(target, ctx)

    if buffer_match then
        local winid = target_window(ctx, buffer_match.bufnr)

        if valid_win(winid) then
            vim.api.nvim_set_current_win(winid)
        end

        if vim.api.nvim_get_current_buf() ~= buffer_match.bufnr then
            vim.api.nvim_set_current_buf(buffer_match.bufnr)
        end

        return
    end

    local path = best_project_match(target, ctx)

    if not path then
        vim.notify("No nearby file found for " .. target, vim.log.levels.WARN)
        return
    end

    local winid = target_window(ctx)

    if valid_win(winid) then
        vim.api.nvim_set_current_win(winid)
    end

    vim.cmd.edit(vim.fn.fnameescape(path))
end

return M
