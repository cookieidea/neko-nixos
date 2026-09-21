# Home 模块共享的派生工具和配置数据。
#
# 按关注点拆分到 lib/ 下的子模块，此处用 // 扁平合并导出 ——
# 消费方仍写作 hmLib.devEnv / hmLib.mpvRifeWrapped，无需改成嵌套路径。
{ pkgs, selfPackages, username }:

(import ./lib/dev-env.nix { inherit pkgs selfPackages username; })
// (import ./lib/runtime.nix { inherit pkgs selfPackages; })
// (import ./lib/seeds.nix { inherit pkgs username; })
