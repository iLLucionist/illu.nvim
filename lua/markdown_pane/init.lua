local defaults = require("markdown_pane.defaults")
local document_picker = require("markdown_pane.document_picker")
local entries = require("markdown_pane.entries")
local heading = require("markdown_pane.heading")
local lifecycle = require("markdown_pane.lifecycle")
local maps = require("markdown_pane.maps")
local picker = require("markdown_pane.picker")
local question = require("markdown_pane.question")
local render = require("markdown_pane.render")
local selection = require("markdown_pane.selection")
local switcher = require("markdown_pane.switcher")
local terminal = require("markdown_pane.terminal")
local util = require("markdown_pane.util")
local pane_window = require("markdown_pane.window")
local viewer = require("markdown_pane.viewer")
local winbar = require("markdown_pane.winbar")

local M = {
    winid = nil,
    bufnr = nil,
    source = nil,
    wrap_enabled = nil,
    active_mode = "markdown",
    active_terminal_key = nil,
    last_terminal_key = nil,
    last_coding_agent_terminal_key = nil,
    last_tool_terminal_keys = {},
    last_focus_win = nil,
    zoomed = false,
    markdown_view = nil,
    terminals = {},
    question_buffers = {},
    config = vim.deepcopy(defaults.config),
}

local sticky_heading_group = vim.api.nvim_create_augroup("MarkdownPaneStickyHeading", { clear = true })
local focus_group = vim.api.nvim_create_augroup("MarkdownPaneFocus", { clear = true })
local shutdown_group = vim.api.nvim_create_augroup("MarkdownPaneShutdown", { clear = true })

local valid_win = util.valid_win
local valid_buf = util.valid_buf
local project_root = util.project_root
local project_root_for_path = util.project_root_for_path
local statusline_escape = heading.statusline_escape

--- Show a numbered/lettered picker and pass the selected entry to a callback.
local function numbered_select(prompt, entries, callback)
    picker.numbered_select(prompt, entries, callback, M)
end

--- Return whether a buffer belongs to the pane or one of its terminals.
local function is_pane_buf(bufnr)
    if not valid_buf(bufnr) then
        return false
    end

    if bufnr == M.bufnr then
        return true
    end

    for _, ctx in pairs(M.terminals or {}) do
        if bufnr == ctx.bufnr then
            return true
        end
    end

    return false
end

--- Remember the most recent normal window outside the pane.
local function record_focus_win(winid)
    pane_window.record_focus_win(M, {
        is_pane_buf = is_pane_buf,
    }, winid)
end

--- Find the pane terminal context for a buffer.
local function terminal_context_for_buf(bufnr)
    return terminal.context_for_buf(M, bufnr)
end

--- Return whether a terminal context still has a live job and buffer.
local function terminal_is_running(ctx)
    return terminal.is_running(ctx)
end

--- Return whether a tool is one of the conversational coding agents.
local function is_coding_agent_tool(tool_name)
    return terminal.is_coding_agent_tool(tool_name)
end

--- Remember the latest active terminal and per-tool coding-agent terminal.
local function remember_terminal_context(ctx)
    terminal.remember_context(M, ctx)
end

--- Build a picker entry representing an already-running terminal context.
local function entry_for_terminal_context(ctx)
    return terminal.entry_for_context(M, ctx)
end

--- Find the best running terminal context for a tool and optional root.
local function terminal_context_for_tool(tool_name, root)
    return terminal.context_for_tool(M, tool_name, root)
end

--- Find the most recently used running Codex or Claude context.
local function last_coding_agent_context(root)
    return terminal.last_coding_agent_context(M, root)
end

--- Return the user-selected wrap state or configured wrap default.
local function preferred_wrap()
    return pane_window.preferred_wrap(M)
end

--- Compute the text reflow width available inside the pane.
local function pane_text_width(winid)
    return pane_window.text_width(M, winid)
end

--- Save the markdown pane cursor and scroll view for later restoration.
local function save_markdown_view()
    viewer.save_view(M)
end

--- Restore the saved markdown cursor and scroll view when possible.
local function restore_markdown_view()
    viewer.restore_view(M)
end

--- Refresh the pane winbar for markdown heading or terminal identity.
local function update_sticky_heading()
    winbar.update(M)
end

--- Install autocmds that keep the sticky heading current.
local function setup_sticky_heading_autocmds()
    winbar.setup_autocmds(M, sticky_heading_group)
end

--- Create or return the markdown viewer buffer.
local function ensure_buf()
    return viewer.ensure_buf(M)
end

local render_markview
local setup_pane_maps
local window_deps
local viewer_deps
local render_deps
local switcher_deps

--- Apply pane-local window options for markdown or terminal mode.
local function set_window_options(winid, mode)
    pane_window.set_options(M, window_deps(), winid, mode)
end

--- Re-render markview decorations for a markdown buffer.
render_markview = function(bufnr)
    render.markview(bufnr)
end

--- Reflow the markdown pane buffer using configured internal or external formatting.
local function reflow_pane_buffer(bufnr, opts)
    render.reflow_buffer(M, render_deps(), bufnr, opts)
end

--- Resolve the project root associated with a pane buffer.
local function pane_root(bufnr)
    local terminal_ctx = terminal_context_for_buf(bufnr)

    if terminal_ctx then
        return terminal_ctx.root
    end

    if bufnr == M.bufnr and M.source then
        return project_root_for_path(M.source)
    end

    return project_root(bufnr)
end

--- Install pane-local mappings on a markdown or terminal pane buffer.
setup_pane_maps = function(bufnr)
    maps.setup(bufnr, {
        ask_current_coding_agent = M.ask_current_coding_agent,
        ask_last_coding_agent = M.ask_last_coding_agent,
        markdown_bufnr = function()
            return M.bufnr
        end,
        open_terminal = M.open_terminal,
        pane_root = pane_root,
        show_markdown = M.show_markdown,
        toggle_markdown_agent = M.toggle_markdown_agent,
        toggle_wrap = M.toggle_wrap,
        wrap_toggle_key = function()
            return M.config.wrap_toggle_key
        end,
    })
end

--- Build window module callbacks that still belong to pane/viewer state.
window_deps = function()
    return {
        ensure_buf = ensure_buf,
        is_pane_buf = is_pane_buf,
        open_markdown = M.open,
        reflow_pane_buffer = reflow_pane_buffer,
        render_markview = render_markview,
        restore_markdown_view = restore_markdown_view,
        save_markdown_view = save_markdown_view,
        update_sticky_heading = update_sticky_heading,
    }
end

--- Create or reuse the side pane window for a buffer and mode.
local function ensure_win(bufnr, mode, opts)
    return pane_window.ensure(M, window_deps(), bufnr, mode, opts)
end

--- Build render module callbacks that still belong to pane/window state.
render_deps = function()
    return {
        preferred_wrap = preferred_wrap,
        set_window_options = set_window_options,
        text_width = pane_text_width,
    }
end

--- Toggle wrapping in the markdown viewer pane.
function M.toggle_wrap()
    render.toggle_wrap(M, render_deps())
end

--- Build viewer module callbacks that still belong to pane/window/render state.
viewer_deps = function()
    return {
        close_pane = M.close,
        ensure_win = ensure_win,
        pick = M.pick,
        reflow_pane_buffer = reflow_pane_buffer,
        remember_terminal_context = remember_terminal_context,
        render_markview = render_markview,
        set_window_options = set_window_options,
        setup_pane_maps = setup_pane_maps,
        update_sticky_heading = update_sticky_heading,
    }
end

--- Open a markdown file in the pane without stealing focus.
function M.open(path)
    viewer.open(M, viewer_deps(), path)
end

--- Switch the pane back to the markdown viewer.
function M.show_markdown()
    viewer.show_markdown(M, viewer_deps())
end

--- Close the pane window while preserving buffers and state.
function M.close()
    pane_window.close(M, window_deps())
end

--- Toggle the pane, optionally opening a specific markdown file.
function M.toggle(path)
    viewer.toggle(M, viewer_deps(), path)
end

--- Return whether the pane window is currently open.
function M.is_open()
    return pane_window.is_open(M)
end

--- Toggle focus between the pane and the last normal window.
function M.focus_toggle()
    pane_window.focus_toggle(M, window_deps())
end

--- Toggle the pane between normal width and zoom width.
function M.toggle_zoom()
    pane_window.toggle_zoom(M, window_deps())
end

--- Return the current text width used for markdown reflow.
function M.text_width()
    return pane_text_width()
end

--- Merge user configuration and install pane autocmds.
function M.setup(opts)
    lifecycle.setup(M, {
        focus = focus_group,
        shutdown = shutdown_group,
    }, {
        record_focus_win = record_focus_win,
        shutdown_terminals = M.shutdown_terminals,
    }, opts)
end

--- Resolve a configured preset by name, label, or default position.
local function preset_by_name(tool, preset_name)
    return entries.preset_by_name(tool, preset_name)
end

--- Build quick picker entries for Codex, Claude, and optionally IPython.
local function tool_shortcut_entries(root, opts)
    return entries.tool_shortcut_entries(M, root, opts)
end

--- Build numbered picker entries for configured terminal presets.
local function terminal_entries(root, start_index, opts)
    return entries.terminal_entries(M, root, start_index, opts)
end

--- Capture text, file, root, and snippet language for a send/ask action.
local function selection_context(opts)
    return selection.context(opts, {
        pane_bufnr = M.bufnr,
        source = M.source,
        terminal_context_for_buf = terminal_context_for_buf,
    })
end

--- Build terminal module callbacks that still belong to pane/window state.
local function terminal_deps()
    return {
        ensure_win = ensure_win,
        pane_root = pane_root,
        save_markdown_view = save_markdown_view,
        selection_context = selection_context,
        setup_pane_maps = setup_pane_maps,
        update_sticky_heading = update_sticky_heading,
    }
end

--- Open or focus a pane terminal, reusing an existing session when possible.
function M.open_terminal(tool_name, preset_name, opts)
    return terminal.open(M, terminal_deps(), tool_name, preset_name, opts)
end

--- Show the most recently used coding-agent terminal.
function M.show_last_agent(opts)
    terminal.show_last_agent(M, terminal_deps(), opts)
end

--- Build switcher module callbacks that still belong to pane state.
switcher_deps = function()
    return {
        numbered_select = numbered_select,
        open_terminal = M.open_terminal,
        pane_root = pane_root,
        show_last_agent = M.show_last_agent,
        show_markdown = M.show_markdown,
        terminal_context_for_buf = terminal_context_for_buf,
        terminal_entries = terminal_entries,
        tool_shortcut_entries = tool_shortcut_entries,
    }
end

--- Toggle between markdown view and the last coding-agent terminal.
function M.toggle_markdown_agent()
    switcher.toggle_markdown_agent(M, switcher_deps())
end

--- Switch the pane to markdown or a selected terminal entry.
function M.switch(entry)
    switcher.switch(M, switcher_deps(), entry)
end

--- Show the pane switcher picker.
function M.switch_picker()
    switcher.switch_picker(M, switcher_deps())
end

--- Send an ask prompt, switching model first when needed.
local function send_prompt_to_terminal(ctx, entry, prompt, started)
    terminal.send_prompt(M, ctx, entry, prompt, started)
end

--- Open or focus the IPython pane terminal.
function M.open_ipython(opts)
    return terminal.open_ipython(M, terminal_deps(), opts)
end

--- Send the current line or selection to IPython.
function M.send_ipython(opts)
    terminal.send_ipython(M, terminal_deps(), opts)
end

--- Clear the running IPython terminal screen.
function M.clear_ipython(opts)
    terminal.clear_ipython(M, terminal_deps(), opts)
end

--- Restart the IPython pane terminal for the current root.
function M.restart_ipython(opts)
    return terminal.restart_ipython(M, terminal_deps(), opts)
end

--- Shut down all pane-owned terminal sessions.
function M.shutdown_terminals(opts)
    terminal.shutdown_terminals(M, opts)
end

--- Build question-editor callbacks that still belong to pane/window state.
local function question_deps()
    return {
        entry_for_terminal_context = entry_for_terminal_context,
        is_coding_agent_tool = is_coding_agent_tool,
        last_coding_agent_context = last_coding_agent_context,
        numbered_select = numbered_select,
        open_terminal = M.open_terminal,
        preset_by_name = preset_by_name,
        selection_context = selection_context,
        send_prompt_to_terminal = send_prompt_to_terminal,
        set_window_options = set_window_options,
        statusline_escape = statusline_escape,
        terminal_context_for_tool = terminal_context_for_tool,
        terminal_entries = terminal_entries,
        tool_shortcut_entries = tool_shortcut_entries,
        update_sticky_heading = update_sticky_heading,
    }
end

--- Cancel and close a question editor buffer.
function M.cancel_question(bufnr)
    question.cancel(M, bufnr)
end

--- Finish a question editor, sending only after a write.
function M.finish_question(bufnr)
    question.finish(M, bufnr)
end

--- Mark a question editor as written and update its cached prompt.
function M.write_question(bufnr)
    question.write(M, bufnr)
end

--- Open the target picker from inside a question editor.
function M.change_question_target(bufnr)
    question.change_target(M, bufnr)
end

--- Ask a specific picker entry using a captured or fresh context.
function M.ask_with_entry(entry, opts)
    question.ask_with_entry(M, question_deps(), entry, opts)
end

--- Capture selection and ask via the target picker.
function M.ask_picker(opts)
    question.ask_picker(M, question_deps(), opts)
end

--- Ask the most recently used Codex or Claude terminal.
function M.ask_last_coding_agent(opts)
    question.ask_last_coding_agent(M, question_deps(), opts)
end

--- Ask the current/default terminal for a specific coding agent.
function M.ask_current_coding_agent(tool_name, opts)
    question.ask_current_coding_agent(M, question_deps(), tool_name, opts)
end

--- Ask a specific tool and optional preset.
function M.ask(tool_name, preset_name, opts)
    question.ask(M, question_deps(), tool_name, preset_name, opts)
end

--- Pick a markdown document and open it in the pane.
function M.pick()
    document_picker.pick(M.open)
end

setup_sticky_heading_autocmds()

return M
