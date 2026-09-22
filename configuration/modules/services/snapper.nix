# Snapper Btrfs 快照。
{ ... }:

{
  services.snapper = {
    # 每次启动创建 boot 快照。
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
      # 限制 boot 快照数量。
      NUMBER_LIMIT = 50;
      # 置 0 才能让 NUMBER_LIMIT 真正生效：原为 86400（1 天内的不删），
      # 而一次集中改造（例如连续几十次 rebuild）产生的快照都落在同一天，
      # 于是越过 50 的上限不断累积（曾达 204 个）。
      NUMBER_MIN_AGE = 0;
    };

    # /home 是独立子卷（@home），root 配置只覆盖 @，故需单独建一个配置，
    # 否则个人数据（flatpak 应用数据 ~/.var、游戏存档、配置）不受保护 ——
    # 迁移时 flatpak 应用数据丢失且无法从快照找回，即因此缺口。
    configs."home" = {
      SUBVOLUME = "/home";
      TIMELINE_CREATE = true;
      TIMELINE_LIMIT_HOURLY = 24;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
      EMPTY_PRE_POST_CLEANUP = true;
      NUMBER_LIMIT = 50;
      NUMBER_MIN_AGE = 0;
    };
  };
}
