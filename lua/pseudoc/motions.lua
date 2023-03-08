local M = {}

local no_ts  = {
  sh = true,
  bash = true,
  debchangelog = true,
}

local BLANKLINE_INDENT_SENTINEL = 0x7fffffff

local function indent_fn(i)
  local ft = vim.bo.filetype
  if no_ts[ft] then
    local line_length = #vim.fn.getline(i)
    if line_length == 0 then
      return BLANKLINE_INDENT_SENTINEL
    end
    return vim.fn.indent(i)
  end
  local ts_indent = require 'nvim-treesitter.indent'
  return ts_indent.get_indent(i)
end

function M.select_context(around)
  local curr = vim.fn.line('.')
  local indent = indent_fn(curr)
  local builder = {}

  local i = 1
  while indent == BLANKLINE_INDENT_SENTINEL do
    if curr - i > 0 then
      indent = indent_fn(curr - i)
    else
      indent = 0
    end
  end

  if indent == 0 then
    return
  end

  local k = 1
  while curr - k > 0 and indent_fn(curr - k) >= indent do
    k = k + 1
  end

  table.insert(builder, [[normal! v]])
  if around then
    table.insert(builder, tostring(k) .. 'k$')
  elseif k > 1 then
    table.insert(builder, tostring(k - 1) .. 'k^')
  else
    table.insert(builder, '^')
  end

  local j = 1
  local last = vim.fn.line('$')
  while curr + j <= last and indent_fn(curr + j) >= indent do
    j = j + 1
  end

  table.insert(builder, 'o')
  if around then
    if indent_fn(curr + j) > 0 then
      table.insert(builder, tostring(j) .. 'j^h')
    elseif j > 1 then
      table.insert(builder, tostring(j - 1) .. 'j$')
    else
      table.insert(builder, '$')
    end
  elseif j > 1 then
    table.insert(builder, tostring(j - 1) .. 'j$h')
  else
    table.insert(builder, '$h')
  end

  vim.cmd(table.concat(builder))
end

return M
