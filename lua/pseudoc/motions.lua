local ts_indent = require 'nvim-treesitter.indent'

local indent_fn = ts_indent.get_indent
local M = {}

function M.select_context(around)
  local curr = vim.fn.line('.')
  local indent = indent_fn(curr)

  local k = 1
  while curr - k > 0 and indent_fn(curr - k) >= indent do
    k = k + 1
  end

  vim.cmd [[normal! v]]
  if around then
    vim.api.nvim_input(tostring(k) .. 'k$')
  elseif k > 1 then
    vim.api.nvim_input(tostring(k - 1) .. 'k^')
  else
    vim.api.nvim_input('^')
  end

  local j = 1
  local last = vim.fn.line('$')
  while curr + j <= last and indent_fn(curr + j) >= indent do
    j = j + 1
  end

  vim.api.nvim_input('o')
  if around then
    if indent_fn(curr + j) > 0 then
      vim.api.nvim_input(tostring(j) .. 'j^h')
    elseif j > 1 then
      vim.api.nvim_input(tostring(j - 1) .. 'j$')
    else
      vim.api.nvim_input('$')
    end
  elseif j > 1 then
    vim.api.nvim_input(tostring(j - 1) .. 'j$h')
  else
    vim.api.nvim_input('$h')
  end
end

return M
