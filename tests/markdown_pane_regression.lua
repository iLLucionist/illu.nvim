vim.opt.runtimepath:append("/Users/maximl/.config/nvim/illu.nvim")

local pane = require("markdown_pane")

local tests = {}

local function test(name, fn)
    table.insert(tests, { name = name, fn = fn })
end

local function mkdir(path)
    vim.fn.mkdir(path, "p")
end

local function write(path, lines)
    vim.fn.writefile(lines, path)
end

local function has_map(bufnr, lhs)
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
        if map.lhs == lhs and map.nowait == 1 then
            return true
        end
    end

    return false
end

local function reset_pane()
    pane.shutdown_terminals({ timeout_ms = 50 })
    pane.close()
end

local function root_fixture(name)
    local root = "/private/tmp/illu-" .. name

    mkdir(root .. "/.git")
    mkdir(root .. "/docs")
    mkdir(root .. "/src")

    return root
end

test("pane-local slot maps exist on markdown and terminal panes", function()
    reset_pane()

    local root = root_fixture("pane-map-test")
    write(root .. "/docs/doc.md", { "# Doc" })

    pane.setup({
        tools = {
            ipython = {
                label = "IPython",
                ask = false,
                cmd = { "sh", "-c", "sleep 10" },
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    pane.open(root .. "/docs/doc.md")

    for _, lhs in ipairs({ " 0", " x", " c", " i" }) do
        assert(has_map(pane.bufnr, lhs), lhs .. " missing on markdown pane")
    end

    local ctx = pane.open_terminal("ipython", nil, { root = root, focus = true })

    for _, lhs in ipairs({ " 0", " x", " c", " i" }) do
        assert(has_map(ctx.bufnr, lhs), lhs .. " missing on terminal pane")
    end
end)

test("visual-line ask captures all selected lines", function()
    reset_pane()

    local captured = nil
    local original_set_lines = vim.api.nvim_buf_set_lines

    vim.api.nvim_buf_set_lines = function(bufnr, start, stop, strict, lines)
        if lines and lines[1] == "Question:" then
            captured = table.concat(lines, "\n")
        end

        return original_set_lines(bufnr, start, stop, strict, lines)
    end

    pane.setup({
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "sleep 10" },
                send_delay_ms = 0,
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "before",
        "from pipio.core.ir import Value, Binding, ErrorSpec",
        "assert Value(1).value==1 and Binding(\"a\", 1).name==\"a\"",
        "after",
    })
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = 0 })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd("normal! Vj")

    pane.ask("codex", nil, {
        bufnr = vim.api.nvim_get_current_buf(),
        visual = true,
        visual_mode = vim.fn.mode(1),
    })

    vim.api.nvim_buf_set_lines = original_set_lines

    assert(captured, "question buffer was not created")
    assert(captured:find("lines 2%-3"), captured)
    assert(captured:find("from pipio%.core%.ir import Value, Binding, ErrorSpec"), captured)
    assert(captured:find("assert Value%(1%)%.value==1 and Binding"), captured)
end)

test("smart gf from markdown pane opens in last non-pane window", function()
    reset_pane()

    local root = root_fixture("smart-gf-markdown-test")
    write(root .. "/docs/doc.md", { "# Doc", "", "See ir.py" })
    write(root .. "/src/ir.py", { "print('target')" })
    write(root .. "/src/origin.py", { "print('origin')" })

    pane.setup({ focus_on_switch = true })
    vim.cmd.edit(root .. "/src/origin.py")

    local origin_win = vim.api.nvim_get_current_win()

    pane.open(root .. "/docs/doc.md")
    pane.focus_toggle()
    assert(vim.api.nvim_get_current_win() == pane.winid, "pane did not focus")

    vim.api.nvim_win_set_cursor(pane.winid, { 3, 5 })
    require("smart_gf").open()

    assert(vim.api.nvim_get_current_win() == origin_win, "gf did not return to origin window")
    assert(vim.api.nvim_buf_get_name(0) == root .. "/src/ir.py", "gf opened wrong buffer")
    assert(vim.api.nvim_win_get_buf(pane.winid) == pane.bufnr, "pane buffer was replaced")
end)

test("smart gf from IPython pane opens traceback file and line outside pane", function()
    reset_pane()

    local root = root_fixture("smart-gf-terminal-test")
    write(root .. "/src/target.py", { "one", "two", "three" })
    write(root .. "/src/origin.py", { "origin" })

    pane.setup({
        tools = {
            ipython = {
                label = "IPython",
                ask = false,
                cmd = { "sh", "-c", "printf 'File " .. root .. "/src/target.py:2\\n'; sleep 10" },
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    vim.cmd.edit(root .. "/src/origin.py")

    local origin_win = vim.api.nvim_get_current_win()
    local ctx = pane.open_terminal("ipython", nil, { root = root, focus = true })

    vim.wait(1000, function()
        return table.concat(vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false), "\n"):find("target.py", 1, true) ~= nil
    end, 20)

    local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)
    local target_line = nil

    for index, line in ipairs(lines) do
        if line:find("target.py", 1, true) then
            target_line = index
            break
        end
    end

    assert(target_line, table.concat(lines, "\n"))

    vim.api.nvim_win_set_cursor(pane.winid, { target_line, 8 })
    require("smart_gf").open()

    assert(vim.api.nvim_get_current_win() == origin_win, "gf did not switch to origin window")
    assert(vim.api.nvim_buf_get_name(0) == root .. "/src/target.py", "opened wrong file")
    assert(vim.api.nvim_win_get_cursor(0)[1] == 2, "did not jump to traceback line")
    assert(vim.api.nvim_win_get_buf(pane.winid) == ctx.bufnr, "pane terminal buffer was replaced")
end)

test("shutdown sends configured exit commands", function()
    reset_pane()

    local root = root_fixture("shutdown-test")
    local out = "/private/tmp/illu-pane-exit-commands.txt"

    pcall(vim.fn.delete, out)

    pane.setup({
        shutdown_timeout_ms = 200,
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "tee -a " .. out },
                include_cd_arg = false,
                presets = { { name = "default", label = "Default", args = {} } },
            },
            claude = {
                label = "Claude",
                cmd = { "sh", "-c", "tee -a " .. out },
                presets = { { name = "default", label = "Default", args = {} } },
            },
            ipython = {
                label = "IPython",
                ask = false,
                cmd = { "sh", "-c", "tee -a " .. out },
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    pane.open_terminal("codex", nil, { root = root, focus = false })
    pane.open_terminal("claude", nil, { root = root, focus = false })
    pane.open_terminal("ipython", nil, { root = root, focus = false })
    pane.shutdown_terminals({ timeout_ms = 200 })

    local sent = table.concat(vim.fn.readfile(out), "\n")

    assert(sent:find("/quit", 1, true), sent)
    assert(sent:find("/exit", 1, true), sent)
    assert(sent:find("quit()", 1, true), sent)
end)

local failures = {}

for _, item in ipairs(tests) do
    local ok, err = xpcall(item.fn, debug.traceback)

    reset_pane()

    if not ok then
        table.insert(failures, item.name .. "\n" .. err)
    end
end

if #failures > 0 then
    error(table.concat(failures, "\n\n"))
end

print("markdown_pane regression tests passed: " .. #tests)
