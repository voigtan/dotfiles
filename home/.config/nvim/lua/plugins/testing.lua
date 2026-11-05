-- ============================================================================
-- Vitest Test Runner (neotest + neotest-vitest) & Inline Coverage (nvim-coverage)
-- Supports both coverage/lcov.info AND Vitest's default coverage/coverage-final.json
-- ============================================================================

local map = vim.keymap.set

-- 1. Neotest + Vitest Adapter
local ok_neotest, neotest = pcall(require, "neotest")
if ok_neotest then
  local adapters = {}
  local ok_vitest, vitest = pcall(require, "neotest-vitest")
  if ok_vitest then
    -- Fix neotest-vitest bug where duplicate `it('same title')` blocks in the same file
    -- overwrite an earlier "failed" test result with a later "passed" test result
    local ok_vutil, vutil = pcall(require, "neotest-vitest.util")
    if ok_vutil and vutil.parsed_json_to_results then
      vutil.parsed_json_to_results = function(data, _, consoleOut)
        local tests = {}
        for _, testResult in pairs(data.testResults or {}) do
          local testFn = testResult.name
          for _, assertionResult in pairs(testResult.assertionResults or {}) do
            local status, name = assertionResult.status, assertionResult.title
            if name ~= nil then
              local keyid = testFn
              for _, value in ipairs(assertionResult.ancestorTitles or {}) do
                if value ~= "" then
                  keyid = keyid .. "::" .. value
                end
              end
              keyid = keyid .. "::" .. name
              if status == "pending" or status == "todo" then
                status = "skipped"
              end

              local existing = tests[keyid]
              -- Never overwrite an already-failed test result with a duplicate-named passing test
              if not existing or existing.status ~= "failed" then
                tests[keyid] = {
                  status = status,
                  short = name .. ": " .. status,
                  output = consoleOut,
                  location = assertionResult.location,
                }
              end

              if not vim.tbl_isempty(assertionResult.failureMessages or {}) then
                local errors = {}
                for _, failMessage in ipairs(assertionResult.failureMessages) do
                  local msg = vutil.cleanAnsi(failMessage)
                  local errorLine, errorColumn = vutil.findErrorPosition(testFn, msg)
                  -- Trim internal stack trace lines ("    at ...") so inline virtual_lines show the clean diff
                  local clean_msg = msg:gsub("\n%s+at [^\n]+", ""):gsub("\n\n+", "\n")
                  table.insert(errors, {
                    line = (
                      (errorLine and tonumber(errorLine) - 1)
                      or (assertionResult.location and assertionResult.location.line - 1)
                      or nil
                    ),
                    column = (
                      (errorColumn and tonumber(errorColumn) - 1)
                      or (assertionResult.location and assertionResult.location.column)
                      or nil
                    ),
                    message = clean_msg,
                  })
                  tests[keyid].short = tests[keyid].short .. "\n" .. msg
                end
                tests[keyid].status = "failed"
                tests[keyid].errors = errors
              end
            end
          end
        end
        return tests
      end
    end

    table.insert(
      adapters,
      vitest({
        filter_dir = function(name)
          return name ~= "node_modules" and name ~= ".git" and name ~= "dist"
        end,
      })
    )
  end

  neotest.setup({
    adapters = adapters,
    status = {
      virtual_text = false,
      signs = true,
    },
    output = {
      open_on_run = false,
    },
    floating = {
      border = "rounded",
    },
    summary = {
      follow = true,
      expand_errors = true,
      mappings = {
        expand = { "<CR>", "<Tab>", "<Right>", "l", "<2-LeftMouse>" },
        expand_all = { "e", "Z" },
        output = "o",
        short = "O",
        jumpto = { "i", "gd" },
        run = "r",
        stop = "u",
        watch = "w",
        help = "?",
      },
    },
    icons = {
      passed = "✔",
      running = "⠋",
      failed = "✖",
      skipped = "○",
      unknown = "?",
    },
  })

  -- Use Neovim 0.12 native multi-line `virtual_lines` for Neotest failure diffs
  -- so multi-line Expected/Received assertion diffs render cleanly below the failing line
  local neotest_ns = vim.api.nvim_create_namespace("neotest")
  vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = true,
  }, neotest_ns)

  -- Deduplicate diagnostics in the `neotest` namespace (e.g. when a file has duplicate `it()` titles)
  local orig_diag_set = vim.diagnostic.set
  vim.diagnostic.set = function(ns, bufnr, diagnostics, opts)
    if ns == neotest_ns and type(diagnostics) == "table" then
      local seen = {}
      local unique = {}
      for _, d in ipairs(diagnostics) do
        local key = tostring(d.lnum) .. ":" .. tostring(d.message)
        if not seen[key] then
          seen[key] = true
          table.insert(unique, d)
        end
      end
      diagnostics = unique
    end
    return orig_diag_set(ns, bufnr, diagnostics, opts)
  end
end

-- 2. Inline Code Coverage (reads coverage/lcov.info OR coverage/coverage-final.json)
local ok_cov, coverage = pcall(require, "coverage")
if ok_cov then
  -- Parser for Vitest's default Istanbul/V8 coverage/coverage-final.json
  local function parse_istanbul_json(path, files)
    local util = require("coverage.util")
    local content = path:read()
    local ok, data = pcall(vim.json.decode, content)
    if not ok or type(data) ~= "table" then
      return
    end

    local cwd = vim.fn.getcwd()
    for filepath, entry in pairs(data) do
      local cmeta = util.new_file_meta()
      local line_hits = {}

      local stmt_map = entry.statementMap or {}
      local stmt_counts = entry.s or {}
      local stmts = {}
      for id, count in pairs(stmt_counts) do
        local loc = stmt_map[id]
        if loc and loc.start and loc.start.line then
          local start_line = loc.start.line
          local end_line = (loc["end"] and loc["end"].line) or start_line
          table.insert(stmts, {
            start_line = start_line,
            end_line = end_line,
            span = end_line - start_line,
            count = count,
          })
        end
      end

      -- Apply outer statements first and inner statements last so inner uncovered lines win
      table.sort(stmts, function(a, b)
        return a.span > b.span
      end)
      for _, st in ipairs(stmts) do
        for l = st.start_line, st.end_line do
          line_hits[l] = st.count
        end
      end

      for l, count in pairs(line_hits) do
        cmeta.summary.num_statements = cmeta.summary.num_statements + 1
        if count > 0 then
          table.insert(cmeta.executed_lines, l)
          cmeta.summary.covered_lines = cmeta.summary.covered_lines + 1
        else
          table.insert(cmeta.missing_lines, l)
          cmeta.summary.missing_lines = cmeta.summary.missing_lines + 1
        end
      end

      local branch_map = entry.branchMap or {}
      local branch_counts = entry.b or {}
      local num_branches = 0
      local partial_branches = 0
      for id, counts in pairs(branch_counts) do
        local binfo = branch_map[id]
        local bline = binfo and (binfo.line or (binfo.loc and binfo.loc.start and binfo.loc.start.line))
        if type(counts) == "table" and bline then
          num_branches = num_branches + #counts
          local any_zero = false
          local any_hit = false
          for _, c in ipairs(counts) do
            if c == 0 then
              any_zero = true
            elseif c > 0 then
              any_hit = true
            end
          end
          if any_zero and any_hit then
            partial_branches = partial_branches + 1
            table.insert(cmeta.missing_branches, { bline, -1 })
          end
        end
      end

      cmeta.summary.num_branches = num_branches
      cmeta.summary.num_partial_branches = partial_branches
      if cmeta.summary.num_statements > 0 then
        cmeta.summary.percent_covered = (cmeta.summary.covered_lines / cmeta.summary.num_statements) * 100
      else
        cmeta.summary.percent_covered = 100
      end

      -- Store under relative path so both vim.fn.bufnr(fname) and :CoverageSummary are clean
      local rel = filepath
      if vim.startswith(filepath, cwd .. "/") then
        rel = filepath:sub(#cwd + 2)
      end
      files[rel] = cmeta
    end
  end

  coverage.setup({
    auto_reload = true,
    commands = true,
    highlights = {
      covered = { fg = "#a6d189" }, -- Catppuccin Frappé Green
      uncovered = { fg = "#e78284" }, -- Catppuccin Frappé Red
      partial = { fg = "#e5c890" }, -- Catppuccin Frappé Yellow
    },
    signs = {
      covered = { hl = "CoverageCovered", text = "▎" },
      uncovered = { hl = "CoverageUncovered", text = "▎" },
      partial = { hl = "CoveragePartial", text = "▎" },
    },
    summary = {
      min_coverage = 80.0,
    },
    lang = {
      javascript = {
        coverage_file = function()
          if vim.fn.filereadable("coverage/lcov.info") == 1 then
            return "coverage/lcov.info"
          end
          return "coverage/coverage-final.json"
        end,
      },
    },
  })

  -- Teach nvim-coverage's JS/TS loaders to parse both lcov.info and coverage-final.json
  local Path = require("plenary.path")
  local util = require("coverage.util")
  local cfg = require("coverage.config")

  local custom_js_ts_load = function(callback)
    local js_cfg = cfg.opts.lang.javascript
    local file = util.get_coverage_file(js_cfg.coverage_file)
    local p = Path:new(file)
    if not p:exists() then
      vim.notify(
        "No coverage file found (expected coverage/coverage-final.json or coverage/lcov.info)",
        vim.log.levels.WARN
      )
      return
    end
    if file:match("%.json$") then
      local report_table = util.report_to_table(p, parse_istanbul_json)
      local totals = {
        num_statements = 0,
        covered_lines = 0,
        missing_lines = 0,
        excluded_lines = 0,
        num_branches = 0,
        num_partial_branches = 0,
        percent_covered = 0,
      }
      local seen = {}
      for _, meta in pairs(report_table.files) do
        if not seen[meta] then
          seen[meta] = true
          totals.num_statements = totals.num_statements + meta.summary.num_statements
          totals.covered_lines = totals.covered_lines + meta.summary.covered_lines
          totals.missing_lines = totals.missing_lines + meta.summary.missing_lines
          totals.excluded_lines = totals.excluded_lines + meta.summary.excluded_lines
          totals.num_branches = totals.num_branches + (meta.summary.num_branches or 0)
          totals.num_partial_branches = totals.num_partial_branches + (meta.summary.num_partial_branches or 0)
        end
      end
      if totals.num_statements > 0 then
        totals.percent_covered = (totals.covered_lines / totals.num_statements) * 100
      end
      report_table.totals = totals
      callback(report_table)
    else
      callback(util.lcov_to_table(p))
    end
  end

  for _, lang_name in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
    local ok_lang, lang_mod = pcall(require, "coverage.languages." .. lang_name)
    if ok_lang then
      lang_mod.load = custom_js_ts_load
    end
  end

  -- Automatically place coverage signs when switching to a newly opened file while coverage is ON
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("CoverageAutoPlaceOnBufEnter", { clear = true }),
    callback = function(args)
      local signs = require("coverage.signs")
      if signs.is_enabled() and vim.bo[args.buf].buftype == "" then
        local ft = vim.bo[args.buf].filetype
        if ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
          coverage.load(true)
        end
      end
    end,
  })
end

-- 3. Global Helpers (also used by Right-Click Context Menu)
_G.vitest_actions = {
  run_nearest = function()
    require("neotest").run.run()
  end,
  run_file = function()
    require("neotest").run.run(vim.fn.expand("%"))
  end,
  run_all = function()
    require("neotest").run.run(vim.fn.getcwd())
  end,
  toggle_watch = function()
    require("neotest").watch.toggle(vim.fn.expand("%"))
  end,
  toggle_coverage = function()
    local cov = require("coverage")
    local signs = require("coverage.signs")
    if signs.is_enabled() then
      cov.hide()
      vim.notify("Coverage gutter: OFF")
    else
      cov.load(true)
      vim.notify("Coverage gutter: ON")
    end
  end,
}

-- 4. Keymaps & Which-Key Group (<leader>v...)
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>v", group = "Vitest / Coverage", icon = { icon = "󰙨 ", color = "green" } },
  })
end

map("n", "<leader>vr", _G.vitest_actions.run_nearest, { desc = "Run nearest Vitest test" })
map("n", "<leader>vf", _G.vitest_actions.run_file, { desc = "Run all tests in file" })
map("n", "<leader>va", _G.vitest_actions.run_all, { desc = "Run ALL Vitest tests in project" })
map("n", "<leader>vw", _G.vitest_actions.toggle_watch, { desc = "Toggle Vitest watch mode on file" })
map("n", "<leader>vs", function()
  local neotest_mod = require("neotest")
  neotest_mod.summary.toggle()
  -- Automatically focus the Test Explorer sidebar if it was just opened
  vim.defer_fn(function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neotest-summary" then
        vim.api.nvim_set_current_win(win)
        break
      end
    end
  end, 50)
end, { desc = "Toggle Vitest Test Explorer sidebar" })
map("n", "<leader>vo", function()
  require("neotest").output.open({ enter = true, auto_close = true })
end, { desc = "Show test failure output popup" })
map("n", "<leader>vO", function()
  require("neotest").output_panel.toggle()
end, { desc = "Toggle full Vitest output panel" })
map("n", "<leader>vc", _G.vitest_actions.toggle_coverage, { desc = "Toggle inline test coverage gutter" })
map("n", "<leader>vC", function()
  require("coverage").load(true)
  vim.cmd("CoverageSummary")
end, { desc = "Show file coverage summary popup" })

-- 5. Right-Click Context Menu for Vitest
require("core.context-menu").register("editor", {
  { priority = "100.85", sep = "-test-sep-" },
  { priority = "100.90", label = "Run Nearest Test (Vitest)", cmd = "<Cmd>lua _G.vitest_actions.run_nearest()<CR>" },
  { priority = "100.95", label = "Toggle Test Watch (Vitest)", cmd = "<Cmd>lua _G.vitest_actions.toggle_watch()<CR>" },
})
