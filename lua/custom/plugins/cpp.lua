-- [[ C/C++ 刷题辅助 ]]
--
-- clangd 要知道一个源文件是怎么被编译的（用了哪个标准、哪些头文件目录），
-- 才能给出正确的补全和跳转。这个信息来自项目根目录的 compile_commands.json。
--
-- 平时刷题都是单个 .cpp 文件，不会有 cmake 来生成这个文件，
-- 于是 clangd 只能猜，表现就是：标准库能补全，但某些特性报错、
-- 或者自定义头文件找不到。
--
-- 这里的 <leader>cM 就是给单文件场景补上这个文件用的。

-- 想换 C++ 标准的话，改这里即可（c++11 / c++14 / c++17 / c++20）
vim.g.cpp_standard = vim.g.cpp_standard or 'c++17'

local function generate_compile_commands()
  local file = vim.fn.expand '%:p'
  if file == '' or vim.bo.filetype == '' then
    vim.notify('当前没有打开任何文件', vim.log.levels.WARN)
    return
  end

  -- 只对 C/C++ 生效
  if not vim.tbl_contains({ 'c', 'cpp' }, vim.bo.filetype) then
    vim.notify('当前文件不是 C/C++（filetype=' .. vim.bo.filetype .. '）', vim.log.levels.WARN)
    return
  end

  local dir = vim.fn.fnamemodify(file, ':h') -- 文件所在目录
  local name = vim.fn.fnamemodify(file, ':t') -- 文件名
  local target = vim.fn.fnamemodify(file, ':t:r') -- 去掉扩展名，作为输出的可执行文件名

  -- compile_commands.json 的标准格式是一个数组，每项描述一个源文件的编译命令
  local entry = {
    directory = dir,
    -- 用 g++ 编译；-g 带上调试信息，方便后面配 nvim-dap 调试
    command = string.format('g++ -std=%s -Wall -Wextra -g -o %s %s', vim.g.cpp_standard, target, name),
    file = file,
  }

  local path = dir .. '/compile_commands.json'
  vim.fn.writefile({ vim.json.encode { entry } }, path)
  vim.notify('已生成：' .. path .. '\n（C++ 标准：' .. vim.g.cpp_standard .. '）', vim.log.levels.INFO)

  -- 让 clangd 重新加载一次，否则它不会立刻发现新生成的编译数据库
  vim.cmd 'LspRestart'
end

-- ⚠ 键位按 LazyVim 改了：原来用 <leader>cm，而 LazyVim 里 <leader>cm = Mason，
--    所以编译数据库挪到大写 <leader>cM。
-- ⚠ 描述别只写「C++」：c 组是 Code（代码 / LSP 动作），在 python 文件里看到孤零零一条
--    「C++ 生成编译数据库」会让人以为整组都是 C++ 的。这里写全称 + 适用范围；
--    在非 C/C++ 文件里按下去，函数里也会直接提示「当前文件不是 C/C++」。
vim.keymap.set('n', '<leader>cM', generate_compile_commands, { desc = '生成编译数据库（仅 C/C++ 用）' })

-- vim: ts=2 sts=2 sw=2 et
