-- ============================================================================
-- Centered Floating Modal Dialogs (core.modal + vim.fn.confirm override)
-- ============================================================================

local M = {}

local modal_ns = vim.api.nvim_create_namespace("CoreFloatingModal")
local orig_confirm = vim.fn.confirm

---@class ModalButton
---@field label string
---@field keys? string[]

---@class ModalConfirmOpts
---@field title? string
---@field prompt string
---@field highlight? string
---@field buttons ModalButton[]
---@field default? integer
---@field cancel? integer

---Open a centered floating confirmation modal and return the 1-based button choice.
---@param opts ModalConfirmOpts
---@return integer choice
function M.confirm(opts)
  local prompt = opts.prompt or "Are you sure?"
  local title = opts.title or " 󰋼 Confirm "
  local buttons = opts.buttons or { { label = " 󰄬 [O]k ", keys = { "o", "y", "1" } } }
  local selected = math.min(math.max(opts.default or 1, 1), #buttons)
  local cancel_choice = opts.cancel or #buttons

  -- Headless fallback so automated scripts never hang
  if #vim.api.nvim_list_uis() == 0 then
    return selected
  end

  local gap = "   "
  local btn_labels = {}
  for _, b in ipairs(buttons) do
    table.insert(btn_labels, b.label)
  end
  local buttons_raw = table.concat(btn_labels, gap)

  local prompt_lines = vim.split(prompt, "\n", { plain = true })
  local max_prompt_w = 0
  for _, line in ipairs(prompt_lines) do
    max_prompt_w = math.max(max_prompt_w, vim.fn.strdisplaywidth(line))
  end

  local content_w = math.max(max_prompt_w, vim.fn.strdisplaywidth(buttons_raw))
  local width = math.max(content_w + 8, 54)

  local function center_pad(str)
    local pad = math.max(math.floor((width - vim.fn.strdisplaywidth(str)) / 2), 0)
    return string.rep(" ", pad) .. str
  end

  local lines = { "" }
  local centered_prompts = {}
  for _, line in ipairs(prompt_lines) do
    local padded = center_pad(line)
    table.insert(lines, padded)
    table.insert(centered_prompts, padded)
  end
  table.insert(lines, "")

  local buttons_pad = math.max(math.floor((width - vim.fn.strdisplaywidth(buttons_raw)) / 2), 0)
  local buttons_line = string.rep(" ", buttons_pad) .. buttons_raw
  local buttons_row_idx = #lines -- 0-based line index for extmarks
  local buttons_line_nr = #lines + 1 -- 1-based line number for mouse clicks
  table.insert(lines, buttons_line)
  table.insert(lines, "")

  local height = #lines

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(math.floor((vim.o.lines - height) / 2) - 1, 0),
    col = math.max(math.floor((vim.o.columns - width) / 2), 0),
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
    zindex = 250,
    focusable = true,
  })
  vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:DiagnosticWarn,FloatTitle:DiagnosticWarn"

  local ranges = {}
  local disp_ranges = {}
  local byte_pos = buttons_pad
  local disp_pos = buttons_pad
  for i, b in ipairs(buttons) do
    local b_start = byte_pos
    local b_end = b_start + #b.label
    ranges[i] = { b_start, b_end }

    local d_w = vim.fn.strdisplaywidth(b.label)
    disp_ranges[i] = { disp_pos + 1, disp_pos + d_w }

    byte_pos = b_end + #gap
    disp_pos = disp_pos + d_w + vim.fn.strdisplaywidth(gap)
  end

  local key_to_btn = {}
  for i, b in ipairs(buttons) do
    key_to_btn[tostring(i)] = i
    for _, k in ipairs(b.keys or {}) do
      key_to_btn[k:lower()] = i
      key_to_btn[k:upper()] = i
    end
  end

  local function render_highlights()
    vim.api.nvim_buf_clear_namespace(buf, modal_ns, 0, -1)
    if opts.highlight and opts.highlight ~= "" then
      local quoted = '"' .. vim.pesc(opts.highlight) .. '"'
      for idx, p_line in ipairs(centered_prompts) do
        local s = p_line:find(quoted)
        if s then
          vim.api.nvim_buf_set_extmark(buf, modal_ns, idx, s - 1, {
            end_col = s + #opts.highlight + 1,
            hl_group = "Title",
          })
        end
      end
    end
    for i, r in ipairs(ranges) do
      vim.api.nvim_buf_set_extmark(buf, modal_ns, buttons_row_idx, r[1], {
        end_col = r[2],
        hl_group = (i == selected) and "PmenuSel" or "Comment",
      })
    end
    vim.cmd("redraw")
  end

  local k_left = vim.api.nvim_replace_termcodes("<Left>", true, false, true)
  local k_right = vim.api.nvim_replace_termcodes("<Right>", true, false, true)
  local k_tab = vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
  local k_stab = vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true)
  local k_cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  local k_esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  local k_ctrl_c = vim.api.nvim_replace_termcodes("<C-c>", true, false, true)
  local k_leftmouse = vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true)

  local choice = cancel_choice
  local ok_loop = pcall(function()
    while true do
      render_highlights()
      local key = vim.fn.getcharstr()
      if key == k_leftmouse then
        local mp = vim.fn.getmousepos()
        if mp.winid == win and mp.line == buttons_line_nr then
          for i, dr in ipairs(disp_ranges) do
            if mp.column >= dr[1] and mp.column <= dr[2] then
              selected = i
              render_highlights()
              choice = i
              return
            end
          end
        elseif mp.winid ~= win then
          choice = cancel_choice
          return
        end
      elseif key == k_left or key == k_stab or key == "h" or key == "H" then
        selected = (selected - 2) % #buttons + 1
      elseif key == k_right or key == k_tab or key == "l" or key == "L" then
        selected = selected % #buttons + 1
      elseif key == k_cr or key == " " then
        choice = selected
        return
      elseif key == k_esc or key == k_ctrl_c then
        choice = cancel_choice
        return
      elseif key_to_btn[key] then
        choice = key_to_btn[key]
        return
      end
    end
  end)

  if vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
  vim.cmd("redraw")

  return ok_loop and choice or cancel_choice
end

---Save a buffer, prompting for a file path if it is an unnamed [No Name] buffer.
---@param buf integer
---@param display_name? string
---@return boolean saved
function M.save_buffer(buf, display_name)
  display_name = display_name or "[No Name]"
  local buf_name = vim.api.nvim_buf_get_name(buf)
  if buf_name == "" then
    local input_path = vim.fn.input("Save as: ", vim.fn.getcwd() .. "/", "file")
    if not input_path or vim.trim(input_path) == "" or input_path:sub(-1) == "/" then
      return false
    end
    local ok_write, err = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd("write " .. vim.fn.fnameescape(input_path))
    end)
    if not ok_write then
      vim.notify("Failed to save " .. display_name .. ": " .. tostring(err), vim.log.levels.ERROR)
      return false
    end
    return true
  end

  local ok_write, err = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd("write")
  end)
  if not ok_write then
    vim.notify("Failed to save " .. display_name .. ": " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Override vim.fn.confirm so standard confirmation calls in Lua also use the floating modal
vim.fn.confirm = function(msg, choices, default, confirm_type)
  if #vim.api.nvim_list_uis() == 0 then
    return orig_confirm(msg, choices, default, confirm_type)
  end

  local raw_choices = (choices and choices ~= "") and vim.split(choices, "\n", { plain = true }) or { "&Ok" }
  local buttons = {}
  for idx, item in ipairs(raw_choices) do
    local hotkey = item:match("&(%w)")
    local formatted = item:gsub("&(%w)", "[%1]", 1)
    local lower = item:lower()
    local icon = ""
    if lower:find("yes") or lower:find("save") or lower:find("ok") then
      icon = "󰆓 "
    elseif lower:find("no") or lower:find("discard") or lower:find("delete") then
      icon = "󰅖 "
    elseif lower:find("cancel") then
      icon = "󰜺 "
    end
    local keys = { tostring(idx) }
    if hotkey then
      table.insert(keys, hotkey:lower())
    end
    table.insert(buttons, {
      label = " " .. icon .. formatted .. " ",
      keys = keys,
    })
  end

  local title_map = {
    Error = "  Error ",
    Question = "  Confirm ",
    Info = "  Info ",
    Warning = "  Warning ",
  }

  return M.confirm({
    title = title_map[confirm_type or ""] or " 󰋼 Confirm ",
    prompt = tostring(msg or ""),
    buttons = buttons,
    default = default or 1,
    cancel = 0,
  })
end

return M
