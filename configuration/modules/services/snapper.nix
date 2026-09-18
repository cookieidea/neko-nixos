# snapper 快照（btrfs @snapshots 子卷）
{ pkgs, ... }:

{
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
}
