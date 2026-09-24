-- [[ neo-tree —— 文件树浏览器（备用）]]
--
-- 注意：本配置里 mini.files 才是默认文件管理器
--   （见 custom/plugins/mini-files.lua，use_as_default_explorer = true），
--   所以 neo-tree 只作为补充，不抢默认职责。
-- 按 `\` 打开并定位到当前文件（reveal）；窗口里再按 `\` 关闭。

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
}
