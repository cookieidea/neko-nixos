# gvfs：虚拟文件系统（polkitd 需系统路径，故在系统层启用）
{ pkgs, ... }:

{
  # gvfs 在系统层启用（原先只在 home.packages）：polkitd 只扫描系统路径
  # (/run/current-system/sw/share/polkit-1/actions)，装用户 profile 里会读不到
  # → 文件管理器访问 /root 报 "org.gtk.vfs.file-operations is not registered"。
  # 该模块同时接管 D-Bus/systemd user 单元与 GIO_EXTRA_MODULES。
  # 指定 package = pkgs.gvfs：与 home.nix 的 GIO_EXTRA_MODULES 同源
  # （模块默认用 pkgs.gnome.gvfs，虽同为 1.60.3 但 store 路径不同，会模块/守护错配）。
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
}
