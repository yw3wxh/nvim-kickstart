-- [[ mason-health.lua —— 让 :checkhealth 不再被 mason 卡死 ]]
--
-- 问题：` :checkhealth `（不带参数、跑全部）会包含 mason 的健康检查，其中
--   check_registries() -> a.wait(registry.refresh)
-- 会去 GitHub 联网拉取 Mason 的包注册表（git fetch github.com/mason-org/mason-registry）。
-- 本机 GitHub 访问慢/被挡（443 通但 ssh.github.com:443 慢），这个网络调用一挂起，
-- nvim 主线程就被 a.wait 冻住 —— 表现就是"运行 checkhealth 就卡死"。
--
-- 处理：截胡 mason.health 模块的加载，把它的 check() 包一层 ——
--   进入 check() 前临时替换两个会联网的调用，跑完这次健康检查再还原：
--     ① registry.refresh      → no-op（原本 git fetch GitHub 注册表，a.wait 会冻主线程）
--     ② providers.github
--       .get_latest_release    → 立刻走失败分支的 stub（原本异步查 GitHub 最新版，
--                                不冻界面但会让 headless 进程等网络回调完才退出，~35s）
--   只影响 `:checkhealth` 这一次调用；mason 平时正常使用（如 :Mason 浏览包）仍会联网。
--   其余检查项（核心工具、各语言运行时、本地 PATH/Providers 等）照常执行，不受影响。
--   代价：本次检查的"注册表是否已安装""mason 最新版"两项可能因没联网而显示一般性提示，
--         属无害的误报，不会再卡界面。

local HEALTH_MOD = 'mason.health'

-- no-op 版的 registry.refresh：满足 a.wait 的回调式签名 (resolve, reject)，
-- 调用即视为"刷新完成"，让 a.wait 立刻返回，不再去 GitHub 拉取。
local function noop_refresh(cb)
  if type(cb) == 'function' then cb() end
end

-- 把真实 mason.health 模块的 check() 包一层：临时替换两个联网调用 -> 跑原 check -> 还原。
local function wrap_check(mod)
  if not (mod and type(mod.check) == 'function') then return end
  local orig_check = mod.check
  mod.check = function()
    -- ① registry.refresh -> no-op：不再去 GitHub 拉取注册表
    local registry = require('mason-registry')
    local orig_refresh = registry.refresh
    registry.refresh = noop_refresh

    -- ② providers.github.get_latest_release -> 立刻走失败分支的 stub：
    --   返回带 on_success/on_failure 的伪 future，on_failure 立即触发（只报本地版本号）。
    --   这样就完全不碰 GitHub，headless 进程不必等网络回调，秒退。
    --   ⚠ 真实模块名是 mason-core.providers，.github 是它里面的 GitHubProvider 子表。
    local providers = require('mason-core.providers')
    local orig_get = providers.github.get_latest_release
    providers.github.get_latest_release = function()
      local fut = {}
      fut.on_success = function() return fut end
      fut.on_failure = function(_, cb) pcall(cb) return fut end
      return fut
    end

    local ok, err = pcall(orig_check)

    -- 还原，不影响 mason 平时的联网（:Mason 浏览包等）
    registry.refresh = orig_refresh
    providers.github.get_latest_release = orig_get
    if not ok then error(err, 0) end
  end
end

-- 情况 1：mason.health 已被加载过（极少见，仅作保险）→ 直接就地改它的 check
if package.loaded[HEALTH_MOD] then
  wrap_check(package.loaded[HEALTH_MOD])
end

-- 情况 2（常态）：在前端插入一个自定义 searcher，截胡 mason.health 的真实加载，
-- 加载完真实模块后把 check() 包一层再返回。
-- 用 searcher（而非 package.preload）是因为：在 preload 的 loader 里再 require 同名模块，
-- 会触发 Lua 的"循环/重复加载"保护而报错；searcher 里委托给原生 loader 则不会。
-- LuaJIT(Lua5.1) 字段是 package.loaders，新版是 package.searchers，两者都兼容。
local searchers = package.searchers or package.loaders
table.insert(searchers, 1, function(name)
  if name ~= HEALTH_MOD then return nil end
  -- 委托给后面的原生 searcher 拿到真实 loader
  for i = 2, #searchers do
    local loader = searchers[i](name)
    if type(loader) == 'function' then
      return function(...)
        local mod = loader(...) -- 真实加载 mason.health（不递归 require 同名模块）
        wrap_check(mod)
        return mod
      end
    end
  end
  return nil
end)
