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
  local last = vim.fn.line('$')

  local i = 1
  while indent == BLANKLINE_INDENT_SENTINEL do
    if curr - i > 0 then
      indent = indent_fn(curr - i)
    end

    if curr + i <= last then
      local t = indent_fn(curr + i)
      if indent == BLANKLINE_INDENT_SENTINEL or t > indent then
        indent = t
      end
    end

    if curr - i <= 0 and curr + i > last then
      indent = 0
      break
    end

    i = i + 1
  end

  if indent == 0 then
    return
  end

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

-- Inline motions
-- Find the line that contains a pair of the given symbol downwards
function M.arbitrary_motion(symbol, arround)
  local line, match
  local curr = vim.fn.line('.')
  local last = vim.fn.line('$')
  local col = vim.fn.col('.')

  local builder = {}
  local i = 0

  while curr + i <= last do
    line = vim.fn.getline(curr + i)
    match = vim.fn.match(line, symbol, 0, 2) >= 0
    if match then
      break
    end
    i = i + 1
    col = 1
  end

  if not match then
    vim.notify('No match found', vim.log.levels.ERROR)
    return
  end

  local count = 0
  table.insert(builder, 'normal! ')
  if i > 0 then
    table.insert(builder, tostring(i) .. 'j')
  end
  if col == 1 then
    table.insert(builder, '^')
  else
    for j = 0, col - 1 do
      local c = line:sub(j, j)
      if c == symbol then
        count = count + 1
      end
    end
  end

  if line:sub(col, col) == symbol then
    if count % 2 == 1 then
      table.insert(builder, 'F' .. symbol)
    end
  elseif count > 0 then
    table.insert(builder, 'F' .. symbol)
  else
    table.insert(builder, 'f' .. symbol)
  end

  if arround then
    table.insert(builder, 'vf' .. symbol)
  else
    table.insert(builder, 'lvt' .. symbol)
  end

  vim.notify(table.concat(builder))
  vim.cmd(table.concat(builder))
end

return M
