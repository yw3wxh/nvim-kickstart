-- [[ C/C++ 刷题辅助：集中维护 compile_commands.json ]]
--
-- clangd 要知道一个源文件是怎么被编译的（用哪个标准、哪些头文件目录），
-- 才能给出正确的补全和跳转。这个信息来自 compile_commands.json。
--
-- 平时刷题都是单个 .cpp 文件，不会有 cmake 来生成它。实测（clangd 10）没有它时：
--   · 标准库的宏还能补（INT32_MIN 之类）
--   · 但按默认 C++14 解析，C++17 的代码直接报红：
--       L4 WARN Decomposition declarations are a C++17 extension
--       L5 WARN Constexpr if is a C++17 extension
--   · L6 ERR  No template named 'optional'
-- 有编译数据库（含 -std=c++17）时：0 条诊断。所以这个文件是必需的。
--
-- ⚠ 方案演进（都实测过，别走回头路）：
--   1. 最初：手动 <leader>cM 在文件所在目录生成。问题：要用户每个题目目录记着按一次，
--      忘了就退化成 C++14；而且生成物混进 OneDrive 刷题目录。
--   2. 然后：改成打开源文件时自动在文件所在目录生成。问题（回归测试抓到的）：
--      clangd 的项目根是向上找标记（.clangd / compile_commands.json / .git）的，
--      **任何一个祖先目录里有 .clangd 索引缓存目录，root 就被吸上去**，
--      clangd 于是去那个上层找编译数据库、找不到、照样 C++14。
--   3. 现在（本版）：所有条目集中写到一个目录（见 DB_DIR），
--      lspconfig 的 clangd cmd 用 --compile-commands-dir 强制指定它 ——
--      和 root 判定彻底解耦，源码目录里不再多出任何文件。
--   ⚠ 代价：以后如果真用 cmake 项目，编译选项会被这里的集中库挡住（cmd 里的
--      --compile-commands-dir 会让 clangd 不再向上搜项目的 build/compile_commands.json）。
--      到时候把 lspconfig.lua 里那一行注释掉即可。
--
-- （2026-09-29 老吴拍板：原来那个手动键 <leader>cM 删掉了 —— 自动维护已全覆盖，用不到。）

-- 想换 C++ 标准改这里（c++11 / c++14 / c++17 / c++20）
vim.g.cpp_standard = vim.g.cpp_standard or 'c++17'

-- 自动维护开关。false = 完全不生成（clangd 退回 C++14 解析）
if vim.g.cpp_auto_compile_db == nil then
  vim.g.cpp_auto_compile_db = true
end

-- 集中编译数据库的位置。lspconfig.lua 里 clangd 的 --compile-commands-dir 也指向这里，
-- 两处必须是同一个目录，改的话一起改。
vim.g.cpp_compile_db_dir = vim.fn.stdpath 'cache' .. '/clangd-db'
local DB = vim.g.cpp_compile_db_dir .. '/compile_commands.json'

local function read_db(path)
  if not vim.uv.fs_stat(path) then return nil end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'))
  if ok and type(decoded) == 'table' then return decoded end
  return nil
end

-- ⚠ 这里必须用 **arguments 数组**，不能拼成一条 command 字符串 —— 这个坑踩得很惨：
--
--   刷题目录和文件名常常带空格和中文，比如
--     `.../FHQ Treap/P3835 【模板】可持久化平衡树.cpp`
--   command 写法（`g++ ... -o <target> <name>`）拼出来是
--     g++ -std=c++17 ... -o P3835 【模板】可持久化平衡树 P3835 【模板】可持久化平衡树.cpp
--   clangd 读 command 时会按 shell 规则拆词，于是被拆成三个"输入文件"，
--   **没有一个能和真实文件对得上** → clangd 认为这个文件没有编译命令，
--   后果是**连标准库的宏都补不出来**：实测敲 `INT` 只剩 2 个候选（还都是
--   buffer 源从文件里搜的词），而正常情况下应该有 47 个 INT* 开头的宏。
--
--   arguments 是数组，clangd 逐项读取、不做 shell 解析，空格和中文都安全。
-- ⚠⚠ 实测抓到的隐形坑：clangd 10 的 JSON 解析器对条目里的**任何额外字段**
--   （不管叫 `_generator` 还是别的）都会把整条目作废 → "Failed to find compilation
--   database" → 退回 fallback，且毫无提示。所以条目里只允许 directory/arguments/file
--   三个标准字段，一个都不能多。集中库整个目录本来就是我们的专属地盘，不需要标记。
local function make_entry(file)
  local dir = vim.fn.fnamemodify(file, ':h')
  return {
    directory = dir,
    -- 用 g++ 编译；-g 带上调试信息，方便后面配 nvim-dap 调试
    arguments = { 'g++', '-std=' .. vim.g.cpp_standard, '-Wall', '-Wextra', '-g', '-o', vim.fn.fnamemodify(file, ':t:r'), vim.fn.fnamemodify(file, ':t') },
    file = file,
  }
end

-- 判断一条是不是本插件生成的：g++ + -std= 开头。用于清理时区分手工条目。
local function ours(e)
  return type(e) == 'table' and type(e.arguments) == 'table' and e.arguments[1] == 'g++' and type(e.arguments[2]) == 'string' and e.arguments[2]:sub(1, 5) == '-std='
end

--- 把 file 的条目写进集中编译数据库。
--- 返回 'created' / 'updated' / 'ok'（已有且无需改动）/ 'skipped'（上层有项目的 db，别插手）/ nil（失败）
local function ensure(file)
  -- cmake / make 项目自己的编译命令才是权威（真正的 include 路径和宏），
  -- 别用我们的单文件 g++ 命令去覆盖它。
  local up = vim.fs.find('compile_commands.json', { upward = true, path = vim.fn.fnamemodify(file, ':h'), type = 'file' })[1]
  if up then
    -- 但上层的库如果**全部条目都是本插件生成的**（g++/-std 特征），那是旧版方案
    -- 写进源码目录的遗留物 —— 现在集中库优先，它不但没用还挡着自动登记，删掉。
    local d = read_db(up)
    if d and #d > 0 then
      local all_ours = true
      for _, e in ipairs(d) do
        if not ours(e) then all_ours = false break end
      end
      if all_ours then
        vim.fn.delete(up)
        vim.notify('已清理旧版遗留的编译数据库：' .. up, vim.log.levels.INFO)
        up = nil
      end
    end
    if up then return 'skipped' end
  end

  local db = read_db(DB) or {}
  -- 同一个文件只保留一条：
  --   · 本插件生成过的（g++/-std 特征）或旧版坏条目（只有 command）→ 刷新为最新
  --   · 用户手工加的（别的编译器/参数）→ 原样保留，不覆盖
  local changed, found = false, false
  local out = {}
  for _, e in ipairs(db) do
    if type(e) == 'table' and e.file == file then
      found = true
      if ours(e) or type(e.arguments) ~= 'table' then
        out[#out + 1] = make_entry(file)
        changed = true
      else
        out[#out + 1] = e
      end
    else
      out[#out + 1] = e
    end
  end
  if not found then
    out[#out + 1] = make_entry(file)
    changed = true
  end

  if not changed then return 'ok' end
  if not pcall(vim.fn.mkdir, vim.fn.fnamemodify(DB, ':h'), 'p') then return nil end
  if not pcall(vim.fn.writefile, { vim.json.encode(out) }, DB) then return nil end
  return found and 'updated' or 'created'
end

-- 自动维护：打开 C/C++ 源文件时，把它登记进集中编译数据库。
-- ⚠ 必须用 BufReadPre（读取文件之前）：再晚就赶不上 clangd 启动时读库，
--   LspRestart 都救不回来，得整个重启 nvim。
vim.api.nvim_create_autocmd('BufReadPre', {
  group = vim.api.nvim_create_augroup('cpp_compile_db', { clear = true }),
  pattern = { '*.c', '*.cpp', '*.cc', '*.cxx', '*.C' },
  callback = function(args)
    if not vim.g.cpp_auto_compile_db then return end
    -- filetype 在 BufReadPre 时肯定没设，所以按扩展名判断
    local file = vim.fn.fnamemodify(args.file, ':p')
    if file == '' or not vim.uv.fs_stat(file) then return end
    pcall(ensure, file) -- 静默：刷题时每开一个文件都弹提示太吵，失败也不该打断编辑
  end,
})

-- 清理：`:CppCompileDbPurge [目录]`
--   · 不带参数：删除整个集中编译数据库文件（那本来就是我们的专属目录）
--   · 带参数：额外递归扫描该目录，删掉历史上在源码目录里生成过的旧版
--     compile_commands.json（只删所有条目都是 g++/-std 特征的，cmake 等手工文件不动）
vim.api.nvim_create_user_command('CppCompileDbPurge', function(opts)
  -- ① 集中库：整个文件都是本插件维护的，直接删
  local removed = 0
  if vim.uv.fs_stat(DB) then
    local db = read_db(DB)
    removed = db and #db or 0
    vim.fn.delete(DB)
  end

  -- ② 历史遗留：早期版本写进源码目录的那些 json
  local scanned = 0
  if opts.args ~= '' then
    local root = vim.fn.expand(opts.args)
    for _, path in ipairs(vim.fs.find(function(name)
      return name == 'compile_commands.json'
    end, { path = root, type = 'file', limit = math.huge })) do
      local d = read_db(path)
      if d and #d > 0 then
        local all_ours = true
        for _, e in ipairs(d) do
          if not ours(e) then all_ours = false break end
        end
        if all_ours then
          vim.fn.delete(path)
          scanned = scanned + 1
        end
      end
    end
  end

  vim.notify(
    ('已删除集中编译数据库（%d 条）；%s'):format(removed, opts.args ~= '' and ('目录扫描删除旧文件 %d 个'):format(scanned) or '未扫描目录（需要的话传个路径参数）'),
    vim.log.levels.INFO
  )
end, { nargs = '?', complete = 'dir', desc = '清理本插件生成的编译数据库条目' })

-- vim: ts=2 sts=2 sw=2 et
