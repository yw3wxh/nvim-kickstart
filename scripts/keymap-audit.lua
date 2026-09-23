-- [[ 键位自查工具 —— 查"快捷键被谁抢了" ]]
--
-- 什么时候用：
--   1) 新装了插件之后，想确认它没有把别的插件的键覆盖掉
--   2) 某个键按下去没反应 / 反应不对，想知道现在到底绑给了谁
--
-- 用法（一条命令）：
--   nvim --headless \
--     --cmd 'lua dofile(vim.fn.stdpath("config").."/scripts/keymap-audit.lua")' \
--     -c 'lua __keymap_audit_report()' -c 'qall'
--
--   想顺便看某个文件类型下的 buffer 局部键位，就在中间插一句：
--     -c 'edit 你的文件.cpp'
--
-- 为什么要这么绕（用 --cmd 提前注入）：
--   nvim 只允许一个键绑一个功能，**后设置的会静默覆盖先设置的**。
--   只看"最终生效"的键位（:nmap）是发现不了覆盖的 —— 被抢掉的那个
--   已经查不到了。所以必须在所有插件加载**之前**挂上钩子，
--   把每一次"设置键位"的调用都记下来，才知道谁抢了谁。
-- ---------------------------------------------------------------------------

local records = {}

-- nvim 内置的 vim/keymap.lua 会在内部再转发一次到 nvim_set_keymap，
-- 那不是插件行为，记下来会误报，必须丢掉
local function is_internal(src) return type(src) == 'string' and (src:find('vim/keymap', 1, true) or src:find('runtime/lua/vim/_', 1, true)) end

-- 把调用者的文件来源翻译成"人能看懂的名字"：插件名 / 自己的配置文件名
local function name_of(src)
  if type(src) ~= 'string' then return '?' end
  src = src:gsub('^@', '')
  local p = src:match 'pack/[^/]+/opt/([^/]+)'
  if p then return p end
  local c = src:match 'lua/custom/plugins/([^/]+)%.lua'
  if c then return 'custom:' .. c end
  local k = src:match 'lua/kickstart/plugins/([^/]+)%.lua'
  if k then return 'kickstart:' .. k end
  local m = src:match 'lua/([%w_]+)%.lua$'
  if m then return 'config:' .. m end
  if src:match 'runtime/' then return 'nvim内置' end
  return src
end

local function origin()
  for i = 2, 10 do
    local ok, info = pcall(debug.getinfo, i, 'S')
    if ok and info and info.source then
      if is_internal(info.source) then return nil end
      if not info.source:match 'keymap%-audit%.lua' then return name_of(info.source) end
    end
  end
  return '?'
end

local function add(mode, lhs, rhs, desc, buffer, from)
  records[#records + 1] = {
    mode = mode,
    lhs = tostring(lhs),
    rhs = (type(rhs) == 'string' and rhs) or '<函数>',
    desc = desc or '',
    buffer = buffer or '',
    from = from,
  }
end

-- 挂三个入口：现代写法、以及两个老式 API（有些插件还在用）
local orig_kmset = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
  local from = origin()
  if from then
    local modes = type(mode) == 'table' and mode or { mode }
    for _, m in ipairs(modes) do
      add(m, lhs, rhs, type(opts) == 'table' and opts.desc, type(opts) == 'table' and opts.buffer, from)
    end
  end
  return orig_kmset(mode, lhs, rhs, opts)
end

local orig_nsk = vim.api.nvim_set_keymap
vim.api.nvim_set_keymap = function(mode, lhs, rhs, opts)
  local from = origin()
  if from then add(mode, lhs, rhs, type(opts) == 'table' and opts.desc, nil, from) end
  return orig_nsk(mode, lhs, rhs, opts)
end

local orig_bsk = vim.api.nvim_buf_set_keymap
vim.api.nvim_buf_set_keymap = function(buf, mode, lhs, rhs, opts)
  local from = origin()
  if from then add(mode, lhs, rhs, type(opts) == 'table' and opts.desc, buf, from) end
  return orig_bsk(buf, mode, lhs, rhs, opts)
end

-- ---------------------------------------------------------------------------
-- 报告
-- ---------------------------------------------------------------------------
--- 输出键位自查报告。用法见文件顶部。
function __keymap_audit_report()
  local out = {}
  local function p(s) out[#out + 1] = s end

  -- 只统计全局键位；buffer 局部的本就该各管各的，不算冲突
  local globals = {}
  for _, r in ipairs(records) do
    if r.buffer == '' and not r.lhs:match '<Plug>' then globals[#globals + 1] = r end
  end

  p('=' .. string.rep('=', 70))
  p(string.format(
    '共记录 %d 次"设置键位"（其中全局 %d 条），去重后 %d 个按键组合',
    #records,
    #globals,
    (function()
      local seen, n = {}, 0
      for _, r in ipairs(globals) do
        local k = r.mode .. '|' .. r.lhs
        if not seen[k] then seen[k] = true end
      end
      for _ in pairs(seen) do
        n = n + 1
      end
      return n
    end)()
  ))
  p('=' .. string.rep('=', 70))

  -- ---------- 1. 真冲突：同一个键被不同来源设了多次 ----------
  local by_key = {}
  for _, r in ipairs(globals) do
    local k = r.mode .. '|' .. r.lhs
    by_key[k] = by_key[k] or {}
    by_key[k][#by_key[k] + 1] = r
  end

  local conflicts = {}
  for k, rs in pairs(by_key) do
    if #rs > 1 then
      local srcs, seen = {}, {}
      for _, r in ipairs(rs) do
        if not seen[r.from] then seen[r.from] = true end
      end
      for s in pairs(seen) do
        srcs[#srcs + 1] = s
      end
      if #srcs > 1 then conflicts[#conflicts + 1] = { key = k, rs = rs } end
    end
  end
  table.sort(conflicts, function(a, b) return a.key < b.key end)

  p ''
  p(string.format('【1】按键被不同来源重复设置 —— %d 处', #conflicts))
  p(string.rep('-', 71))
  if #conflicts == 0 then
    p '  无 —— 没有键被抢'
  else
    for _, c in ipairs(conflicts) do
      local mode, lhs = c.key:match '^(.-)|(.*)$'
      p(string.format('  [%s] %s', mode, lhs))
      for _, r in ipairs(c.rs) do
        p(string.format('      %-26s %-40s %s', r.from, r.rhs:sub(1, 38), r.desc))
      end
      local last = c.rs[#c.rs]
      p(string.format('      => 最终生效：%s（%s）', last.from, last.desc ~= '' and last.desc or '无说明'))
    end
  end

  -- ---------- 2. 前缀冲突：按了短键要等超时 ----------
  local keys_by_mode = {}
  for _, r in ipairs(globals) do
    keys_by_mode[r.mode] = keys_by_mode[r.mode] or {}
    keys_by_mode[r.mode][r.lhs] = true
  end

  local prefixes = {}
  for mode, set in pairs(keys_by_mode) do
    for short in pairs(set) do
      for long in pairs(set) do
        if long ~= short and long:sub(1, #short) == short then prefixes[#prefixes + 1] = { mode = mode, short = short, long = long } end
      end
    end
  end
  table.sort(prefixes, function(a, b)
    if a.mode ~= b.mode then return a.mode < b.mode end
    if #a.short ~= #b.short then return #a.short < #b.short end
    return a.short < b.short
  end)

  p ''
  p(string.format('【2】前缀冲突（按下短键后要等超时才执行）—— %d 处', #prefixes))
  p(string.rep('-', 71))
  p '  说明：这一项大多是**正常的** —— 比如 textobjects 的 af/if 本来就要'
  p '  等一个字符，mini.surround 的 gsf 后面还要接 l/n。列出来只是让你知道'
  p '  哪些键按下去会有"等一下"的手感。'
  if #prefixes == 0 then p '  无' end
  local last_key = nil
  for _, x in ipairs(prefixes) do
    local k = x.mode .. '|' .. x.short
    if k ~= last_key then
      p(string.format('  [%s] %s', x.mode, x.short))
      last_key = k
    end
  end

  p ''
  p(string.rep('=', 71))
  print(table.concat(out, '\n'))
end
