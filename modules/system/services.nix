# 服务：SSH、udisks2、gvfs、snapper 快照、Sunshine 串流、LACT、smartd、OpenSSH
{ pkgs, ... }:

{
  services.openssh.enable = true;

  services.udisks2.enable = true;   # USB 自动挂载

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

  # btrfs + snapper 快照（@snapshots 独立子卷，回滚根时不带快照）
  # 26.05：键名全大写（SUBVOLUME/TIMELINE_*）；旧 camelCase 被静默吞掉 → 快照不生效
  services.snapper = {
    # 每次开机 + 每次 nixos-rebuild 各产生一个 boot 快照
    snapshotRootOnBoot = true;
    configs."root" = {
      SUBVOLUME = "/";
      TIMELINE_CREATE = true;
      TIMELINE_LIMIT_HOURLY = 24;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
      EMPTY_PRE_POST_CLEANUP = true;
      # NUMBER_LIMIT=0 是「不限量」→ boot 快照永不清理，实测 9/14 一天堆积 96 个
      # （累计 335 个）。设为 50 让 snapper 自动回收旧的 boot 快照。
      NUMBER_LIMIT = 50;
      NUMBER_MIN_AGE = 86400;   # 1 天内的不删
    };
  };
  # 26.05 移除 grub-btrfs → 无 GRUB 快照子菜单；回滚走 generation + snapper

  # Sunshine（Moonlight 串流）：capSysAdmin 供 KMS 抓屏，uinput 模拟键鼠/手柄
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };
  hardware.uinput.enable = true;

  # 应用级服务
  services.lact.enable = true;
  services.smartd.enable = true;   # 磁盘健康监控（SMART）
}
