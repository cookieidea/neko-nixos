# Home 模块共享的派生工具和配置数据。
{ pkgs, selfPackages, username }:

(import ./lib/dev-env.nix { inherit pkgs selfPackages username; })
// (import ./lib/runtime.nix { inherit pkgs selfPackages; })
// (import ./lib/seeds.nix { inherit pkgs username; })
