# snapper 快照（btrfs @snapshots 子卷）
{ ... }:

{
  services.snapper = {
    # 每次开机产生一个 boot 快照
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
      # boot 快照保留上限
      NUMBER_LIMIT = 50;
      NUMBER_MIN_AGE = 86400;   # 1 天内的不删
    };
  };
}
