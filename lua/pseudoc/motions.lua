local M = {}

local no_ts  = {
  sh = true,
  bash = true,
}

local function indent_fn(i)
  local ft = vim.bo.filetype
  if no_ts[ft] then
    return vim.fn.indent(i)
  end
  local ts_indent = require 'nvim-treesitter.indent'
  return ts_indent.get_indent(i)
end

function M.select_context(around)
  local curr = vim.fn.line('.')
  local indent = indent_fn(curr)
  local builder = {}

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
