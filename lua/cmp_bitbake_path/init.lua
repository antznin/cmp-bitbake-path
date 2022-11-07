local cmp = require 'cmp'

local source = {}

local constants = {
  max_lines = 20,
}

---@class cmp_bitbake.Option
---@field public trailing_slash boolean
---@field public label_trailing_slash boolean
---@field public get_cwd fun(): string
---@type cmp_bitbake.Option
local defaults = {
  trailing_slash = false,
  label_trailing_slash = true,
  get_cwd = function(params)
    return vim.fn.expand(('#%d:p:h'):format(params.context.bufnr))
  end,
}

source.is_available = function ()
  return vim.bo.filetype == 'bitbake'
end

source.new = function()
  return setmetatable({}, { __index = source })
end

-- TODO: uncomment?
source.get_trigger_characters = function()
  return { '/', '.' }
end

-- source.get_keyword_pattern = function(self, params)
--   return NAME_REGEX .. '*'
-- end

source.complete = function(self, params, callback)
  local option = self:_validate_option(params)
  local found_dirs, dirnames

  local node = self:_get_current_node(params)
  if node ~= '' then
    found_dirs = self:_find_dirnames(node) or {}
  end
  if found_dirs == nil then
    dirnames = self:_dirnames_in_cwd(params, option, function(err, candidates)
      if err then
        return callback()
      end
      callback(candidates)
    end)
    if not dirnames then
      return callback()
    end
  else
    dirnames = found_dirs
  end

  self:_candidates_in_dirs(dirnames, option, function(err, candidates)
    if err then
      return callback()
    end
    callback(candidates)
  end)
end

-- Find all directories in the buffer's parent directory.
source._dirnames_in_cwd = function (self, params, option, callback)
  local dirnames = {}

  local dirname = vim.fs.dirname(vim.api.nvim_buf_get_name(0))

  local fs, err = vim.loop.fs_scandir(dirname)
  if err then
    return callback(err, nil)
  end

  local i = 0
  while true do
    local name, fs_type, e = vim.loop.fs_scandir_next(fs)
    if e then
      return callback(fs_type, nil)
    end
    if not name then
      break
    end
    if fs_type == 'directory' then
      dirnames[i] = dirname .. '/' .. name
    end
    i = i + 1
  end
  return dirnames
end

FILE_REGEX = vim.regex([[file://\(.\+\)$]])

-- Only if the cursor is already in a file:// string.
source._get_current_node = function (_, params)
  -- Check that we match file://.
  local start = FILE_REGEX:match_str(params.context.cursor_before_line)
  if start == nil then
    return ''
  end

  -- Remove `file://`.
  local current_path = string.sub(params.context.cursor_before_line, start + 8)
  return current_path
end

-- Return a list of found directory based on the directory under the cursor.
source._find_dirnames = function (_, path)
  local buf_dirname = vim.fs.dirname(vim.api.nvim_buf_get_name(0))

  -- Find all directories matching that string in the buffer's parent directory.
  local opts = {
    path = buf_dirname,
    type = 'directory',
    limit = math.huge,
  }
  local found_dirs = vim.fs.find(
    vim.fs.basename(vim.fs.dirname(path)),
    opts)

  return found_dirs
end

-- Return candidate items for given list of directories `dirnames`.
source._candidates_in_dirs = function(_, dirnames, option, callback)

  local items = {}

  for _, dirname in pairs(dirnames) do

    local fs, err = vim.loop.fs_scandir(dirname)
    if err then
      return callback(1, nil)
    end

    local function create_item(name, fs_type)

      local path = dirname .. '/' .. name
      local stat = vim.loop.fs_stat(path)
      local lstat = nil
      if stat then
        fs_type = stat.type
      elseif fs_type == 'link' then
        -- Broken symlink
        lstat = vim.loop.fs_lstat(dirname)
        if not lstat then
          return
        end
      else
        return
      end

      local item = {
        label = name,
        filterText = name,
        insertText = name,
        kind = cmp.lsp.CompletionItemKind.File,
        data = {
          path = path,
          type = fs_type,
          stat = stat,
          lstat = lstat,
        },
      }
      if fs_type == 'directory' then
        item.kind = cmp.lsp.CompletionItemKind.Folder
        if option.label_trailing_slash then
          print('hello')
          item.label = name .. '/'
        else
          item.label = name
        end
        item.insertText = name .. '/'
        if not option.trailing_slash then
          item.word = name
        end
      end
      table.insert(items, item)
    end

    while true do
      local name, fs_type, e = vim.loop.fs_scandir_next(fs)
      if e then
        return callback(fs_type, nil)
      end
      if not name then
        break
      end
      create_item(name, fs_type)
    end
  end
  callback(nil, items)
end

---@return cmp_bitbake.Option
source._validate_option = function(_, params)
  local option = vim.tbl_deep_extend('keep', params.option, defaults)
  vim.validate({
    trailing_slash = { option.trailing_slash, 'boolean' },
    label_trailing_slash = { option.label_trailing_slash, 'boolean' },
    get_cwd = { option.get_cwd, 'function' },
  })
  return option
end

return source
