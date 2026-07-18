vim.opt.runtimepath:append("/Users/maximl/.config/nvim/illu.nvim")

local defaults = require("markdown_pane.defaults")
local entries = require("markdown_pane.entries")
local markdown_reflow = require("markdown_reflow")
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

local function find_map(bufnr, lhs)
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
        if map.lhs == lhs then
            return map
        end
    end

    error("missing map: " .. lhs)
end

local function call_map(bufnr, lhs)
    local map = find_map(bufnr, lhs)

    assert(map.callback, lhs .. " has no callback")
    map.callback()
end

local function only_question_buf()
    local found = nil

    for bufnr in pairs(pane.question_buffers or {}) do
        assert(not found, "more than one question buffer is open")
        found = bufnr
    end

    assert(found, "no question buffer is open")

    return found
end

local function set_question(bufnr, lines)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modified", true, { buf = bufnr })
end

local function read_file(path)
    if vim.fn.filereadable(path) == 0 then
        return ""
    end

    return table.concat(vim.fn.readfile(path), "\n")
end

local function wait_for_file(path, needle)
    local ok = vim.wait(1500, function()
        return read_file(path):find(needle, 1, true) ~= nil
    end, 20)

    assert(ok, "did not find " .. needle .. " in " .. path .. ":\n" .. read_file(path))
end

local function reset_pane()
    pane.shutdown_terminals({ timeout_ms = 50 })
    pane.close()
    pane.zoomed = false
    pane.config = vim.deepcopy(defaults.config)
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

test("pane-local slot maps switch between markdown, agents, and IPython", function()
    reset_pane()

    local root = root_fixture("pane-slot-switch-test")
    write(root .. "/docs/doc.md", { "# Doc" })

    pane.setup({
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "sleep 10" },
                presets = { { name = "default", label = "Default", args = {} } },
            },
            claude = {
                label = "Claude",
                cmd = { "sh", "-c", "sleep 10" },
                presets = { { name = "default", label = "Default", args = {} } },
            },
            ipython = {
                label = "IPython",
                ask = false,
                cmd = { "sh", "-c", "sleep 10" },
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    pane.open(root .. "/docs/doc.md")
    pane.focus_toggle()

    call_map(pane.bufnr, " x")
    assert(pane.active_mode == "codex", "space-x did not switch to Codex")

    local codex_buf = vim.api.nvim_win_get_buf(pane.winid)

    call_map(codex_buf, " c")
    assert(pane.active_mode == "claude", "space-c did not switch to Claude")

    local claude_buf = vim.api.nvim_win_get_buf(pane.winid)

    call_map(claude_buf, " i")
    assert(pane.active_mode == "ipython", "space-i did not switch to IPython")

    local ipython_buf = vim.api.nvim_win_get_buf(pane.winid)

    call_map(ipython_buf, " 0")
    assert(pane.active_mode == "markdown", "space-0 did not switch to markdown")
    assert(vim.api.nvim_win_get_buf(pane.winid) == pane.bufnr, "space-0 did not restore markdown buffer")
end)

test("public IPython send captures current line through terminal deps", function()
    reset_pane()

    local root = root_fixture("ipython-send-test")
    local out = "/private/tmp/illu-ipython-send.txt"

    pcall(vim.fn.delete, out)
    write(root .. "/src/origin.py", {
        "value = 41 + 1",
        "print(value)",
    })

    pane.setup({
        tools = {
            ipython = {
                label = "IPython",
                ask = false,
                cmd = { "sh", "-c", "tee -a " .. out },
                send_delay_ms = 0,
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    vim.cmd.edit(root .. "/src/origin.py")
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    pane.send_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
        line1 = 1,
        line2 = 1,
    })

    wait_for_file(out, "value = 41 + 1")
end)

test("visual IPython send exits visual mode after capture", function()
    reset_pane()

    local root = root_fixture("ipython-visual-exit-test")
    local out = "/private/tmp/illu-ipython-visual-exit.txt"

    pcall(vim.fn.delete, out)
    write(root .. "/src/origin.py", {
        "first = 1",
        "second = 2",
        "third = 3",
    })

    pane.setup({
        tools = {
            ipython = {
                label = "IPython",
                ask = false,
                cmd = { "sh", "-c", "tee -a " .. out },
                send_delay_ms = 0,
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    vim.cmd.edit(root .. "/src/origin.py")
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal! Vj")

    local visual_mode = vim.fn.mode(1)

    assert(visual_mode:match("[vV\22]"), "test did not enter visual mode")

    pane.send_ipython({
        bufnr = vim.api.nvim_get_current_buf(),
        visual = true,
        visual_mode = visual_mode,
    })

    wait_for_file(out, "first = 1")
    wait_for_file(out, "second = 2")

    local exited = vim.wait(500, function()
        return not vim.fn.mode(1):match("[vV\22]")
    end, 20)

    assert(exited, "visual mode remained active after send")
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

test("question quit cancels unwritten changes and restores origin", function()
    reset_pane()

    local root = root_fixture("question-cancel-test")
    local out = "/private/tmp/illu-question-cancel.txt"

    pcall(vim.fn.delete, out)
    write(root .. "/src/origin.py", { "print('origin')" })

    pane.setup({
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "tee -a " .. out },
                send_delay_ms = 0,
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    vim.cmd.edit(root .. "/src/origin.py")

    local origin_win = vim.api.nvim_get_current_win()
    local origin_buf = vim.api.nvim_get_current_buf()

    pane.ask("codex", nil, { bufnr = origin_buf })

    local qbuf = only_question_buf()

    set_question(qbuf, { "Question:", "this should not send" })
    pane.finish_question(qbuf)

    assert(next(pane.question_buffers) == nil, "question buffer was not cleared")
    assert(next(pane.terminals) == nil, "cancelled question started a terminal")
    assert(vim.api.nvim_get_current_win() == origin_win, "cancel did not restore origin window")
    assert(vim.api.nvim_get_current_buf() == origin_buf, "cancel did not restore origin buffer")
    assert(read_file(out) == "", "cancelled question wrote to terminal")
end)

test("question write then quit sends prompt and focuses terminal", function()
    reset_pane()

    local root = root_fixture("question-send-test")
    local out = "/private/tmp/illu-question-send.txt"

    pcall(vim.fn.delete, out)
    write(root .. "/src/origin.py", { "print('origin')" })

    pane.setup({
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "tee -a " .. out },
                send_delay_ms = 0,
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    vim.cmd.edit(root .. "/src/origin.py")
    pane.ask("codex", nil, { bufnr = vim.api.nvim_get_current_buf() })

    local qbuf = only_question_buf()

    set_question(qbuf, { "Question:", "send this exact prompt" })
    pane.write_question(qbuf)
    pane.finish_question(qbuf)

    wait_for_file(out, "send this exact prompt")
    assert(next(pane.question_buffers) == nil, "sent question buffer was not cleared")
    assert(vim.api.nvim_get_current_win() == pane.winid, "send did not focus the pane terminal")
    assert(pane.active_mode == "codex", "send did not activate Codex")
end)

test("question write without quit does not send", function()
    reset_pane()

    local root = root_fixture("question-write-only-test")
    local out = "/private/tmp/illu-question-write-only.txt"

    pcall(vim.fn.delete, out)
    write(root .. "/src/origin.py", { "print('origin')" })

    pane.setup({
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "tee -a " .. out },
                send_delay_ms = 0,
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    vim.cmd.edit(root .. "/src/origin.py")
    pane.ask("codex", nil, { bufnr = vim.api.nvim_get_current_buf() })

    local qbuf = only_question_buf()

    set_question(qbuf, { "Question:", "draft but do not send" })
    pane.write_question(qbuf)
    vim.wait(150, function()
        return false
    end, 20)

    assert(read_file(out) == "", "write-only question sent to terminal")
    assert(pane.question_buffers[qbuf] ~= nil, "write-only question closed the editor")

    pane.finish_question(qbuf)
    wait_for_file(out, "draft but do not send")
end)

test("asking with a new preset reuses the same agent session and sends a model switch", function()
    reset_pane()

    local root = root_fixture("model-switch-test")
    local out = "/private/tmp/illu-model-switch.txt"

    pcall(vim.fn.delete, out)
    write(root .. "/src/origin.py", { "print('origin')" })

    pane.setup({
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "tee -a " .. out },
                send_delay_ms = 0,
                switch_command = "SWITCH {name}",
                presets = {
                    { name = "one", label = "One", args = {} },
                    { name = "two", label = "Two", args = {} },
                },
            },
        },
    })

    local ctx = pane.open_terminal("codex", "one", { root = root, focus = false })
    local original_buf = ctx.bufnr
    local original_job = ctx.job_id

    vim.cmd.edit(root .. "/src/origin.py")
    pane.ask("codex", "two", { bufnr = vim.api.nvim_get_current_buf() })

    local qbuf = only_question_buf()

    set_question(qbuf, { "Question:", "reuse this session" })
    pane.write_question(qbuf)
    pane.finish_question(qbuf)

    wait_for_file(out, "SWITCH two")
    wait_for_file(out, "reuse this session")

    local updated = pane.terminals[ctx.key]

    assert(updated.bufnr == original_buf, "Codex buffer was replaced")
    assert(updated.job_id == original_job, "Codex job was replaced")
    assert(updated.preset_name == "two", "Codex preset was not updated")

    local current = {}

    for _, entry in ipairs(entries.terminal_entries(pane, root, 1, { ask_only = true })) do
        if entry.tool_name == "codex" and entry.current then
            table.insert(current, entry)
        end
    end

    assert(#current == 1, "model picker marked multiple Codex presets current")
    assert(current[1].preset_name == "two", "model picker current preset did not follow switch")
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

test("focus toggle moves between normal window and pane", function()
    reset_pane()

    local root = root_fixture("focus-toggle-test")

    write(root .. "/docs/doc.md", { "# Doc" })
    write(root .. "/src/origin.py", { "print('origin')" })

    pane.setup({})
    vim.cmd.edit(root .. "/src/origin.py")

    local origin_win = vim.api.nvim_get_current_win()

    pane.open(root .. "/docs/doc.md")
    assert(vim.api.nvim_get_current_win() == origin_win, "open stole focus")

    pane.focus_toggle()
    assert(vim.api.nvim_get_current_win() == pane.winid, "focus_toggle did not focus pane")

    pane.focus_toggle()
    assert(vim.api.nvim_get_current_win() == origin_win, "focus_toggle did not return to origin window")
end)

test("closing and reopening markdown pane restores cursor view", function()
    reset_pane()

    local root = root_fixture("close-reopen-view-test")
    local doc = {}

    for index = 1, 80 do
        table.insert(doc, "Line " .. index)
    end

    write(root .. "/docs/doc.md", doc)
    write(root .. "/src/origin.py", { "print('origin')" })

    pane.setup({ auto_reflow = false })
    vim.cmd.edit(root .. "/src/origin.py")
    pane.open(root .. "/docs/doc.md")
    pane.focus_toggle()

    vim.api.nvim_win_set_cursor(pane.winid, { 40, 0 })
    vim.api.nvim_win_call(pane.winid, function()
        vim.cmd("normal! zt")
    end)

    pane.close()
    assert(not pane.is_open(), "pane did not close")

    pane.open(root .. "/docs/doc.md")
    assert(vim.api.nvim_win_get_cursor(pane.winid)[1] == 40, "markdown cursor view was not restored")
end)

test("closing pane preserves running terminal session", function()
    reset_pane()

    local root = root_fixture("close-terminal-preserve-test")

    write(root .. "/docs/doc.md", { "# Doc" })

    pane.setup({
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "sleep 10" },
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    pane.open(root .. "/docs/doc.md")

    local ctx = pane.open_terminal("codex", nil, { root = root, focus = true })
    local bufnr = ctx.bufnr
    local job_id = ctx.job_id

    pane.close()
    assert(not pane.is_open(), "pane did not close")
    assert(vim.api.nvim_buf_is_valid(bufnr), "terminal buffer was deleted on close")

    local reopened = pane.open_terminal("codex", nil, { root = root, focus = true })

    assert(reopened.bufnr == bufnr, "terminal buffer was not reused")
    assert(reopened.job_id == job_id, "terminal job was not reused")
end)

test("markdown and terminal pane window options are mode-specific", function()
    reset_pane()

    local root = root_fixture("window-options-test")

    write(root .. "/docs/doc.md", { "# Doc" })

    pane.setup({
        wrap = true,
        tools = {
            codex = {
                label = "Codex",
                cmd = { "sh", "-c", "sleep 10" },
                presets = { { name = "default", label = "Default", args = {} } },
            },
        },
    })

    pane.open(root .. "/docs/doc.md")

    assert(vim.api.nvim_get_option_value("number", { win = pane.winid }) == true, "markdown pane number option was off")
    assert(vim.api.nvim_get_option_value("wrap", { win = pane.winid }) == true, "markdown pane wrap option was off")
    assert(vim.api.nvim_get_option_value("conceallevel", { win = pane.winid }) == 3, "markdown pane conceallevel was wrong")

    pane.open_terminal("codex", nil, { root = root, focus = true })

    assert(vim.api.nvim_get_option_value("number", { win = pane.winid }) == false, "terminal pane number option was on")
    assert(vim.api.nvim_get_option_value("wrap", { win = pane.winid }) == false, "terminal pane wrap option was on")
    assert(vim.api.nvim_get_option_value("conceallevel", { win = pane.winid }) == 0, "terminal pane conceallevel was wrong")
end)

test("zoom focuses pane and caps markdown text width", function()
    reset_pane()

    local root = root_fixture("zoom-focus-test")

    write(root .. "/docs/doc.md", {
        "# Doc",
        "",
        "This is a paragraph that exists so zoom reflow has content to work with in the pane.",
    })
    write(root .. "/src/origin.py", { "print('origin')" })

    pane.setup({
        width = 40,
        zoom_text_width = 90,
        reflow_margin = 8,
    })

    vim.cmd.edit(root .. "/src/origin.py")

    local origin_win = vim.api.nvim_get_current_win()

    pane.open(root .. "/docs/doc.md")
    assert(vim.api.nvim_get_current_win() == origin_win, "pane open stole focus before zoom")

    pane.toggle_zoom()

    assert(vim.api.nvim_get_current_win() == pane.winid, "zoom did not focus pane")
    assert(pane.text_width() <= 90, "zoom text width exceeded cap")
end)

test("external mdfmt reflow preserves markdown tables", function()
    if vim.fn.executable("mdfmt") ~= 1 then
        return
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    local table_block = {
        "| Name | Value |",
        "| ---- | ----- |",
        "| alpha | one two three |",
        "| beta | four five six |",
    }
    local lines = {
        "# Doc",
        "",
        "This paragraph is intentionally long enough that mdfmt should wrap it when a narrow width is requested for the external reflow test.",
        "",
        table_block[1],
        table_block[2],
        table_block[3],
        table_block[4],
    }

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    markdown_reflow.reflow_buffer(bufnr, {
        width = 48,
        notify = false,
        external_reflow_cmd = { "mdfmt", "--stdin", "--width", "{width}", "--wrap", "always" },
        external_reflow_protect_tables = true,
        external_reflow_fallback = false,
    })

    local output = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local found = {}

    for _, line in ipairs(output) do
        if line:find("^|") then
            table.insert(found, line)
        end
    end

    assert(vim.deep_equal(found, table_block), table.concat(output, "\n"))
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
