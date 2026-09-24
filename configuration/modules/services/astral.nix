# Astral TUN 权限。
#
# TUN 需要 CAP_NET_ADMIN。GUI 会把自带的 core 释放到
# ~/.local/share/astral-core/app/ 并从那里运行，而该目录归用户所有，
# 其中任何可执行文件都能被用户进程替换。
#
# 原实现让 root 直接对那个路径 setcap，等价于「谁能写这个文件，谁就能让
# root 为任意 ELF 授予 CAP_NET_ADMIN」。
#
# 现在改为：root 每次都从只读的 store 取同一份 core，先写到同目录的临时
# 文件上、设好 capability、再原子改名就位。这样带 capability 的 inode
# 始终来自 store，用户的替换品不会被授权；若用户替换了它，替换品没有
# capability（TUN 因此不可用，但也不会提权），下一次触发会被还原。
{ pkgs, username, selfPackages, ... }:

let
  storeCore = "${selfPackages.astral}/app/astral-core";
  coreDir = "/home/${username}/.local/share/astral-core/app";
  core = "${coreDir}/astral-core";
  setcap = "${pkgs.libcap.out}/bin/setcap";
  getcap = "${pkgs.libcap.out}/bin/getcap";
in
{
  systemd.services.astral-core-capability = {
    description = "Install Astral core from store with CAP_NET_ADMIN";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "astral-core-capability" ''
        set -eu

        # 目录由 GUI 首次运行时创建；尚未出现时无事可做，
        # path unit 会在它出现后再次触发。
        [ -d "${coreDir}" ] || exit 0

        # 已就位且内容与 store 一致、capability 也在，则无需改动。
        if [ -f "${core}" ] && cmp -s "${storeCore}" "${core}" \
           && ${getcap} "${core}" 2>/dev/null | grep -q 'cap_net_admin=ep'; then
          exit 0
        fi

        # 先落临时文件：目标是 root 属主，capability 设在它上面，
        # 最后原子改名，避免「设完 cap 再被换掉」的窗口。
        tmp="${core}.new"
        install -o root -g root -m 0755 "${storeCore}" "$tmp"
        ${setcap} cap_net_admin=ep "$tmp"
        mv -f "$tmp" "${core}"
      '';
    };
  };

  systemd.paths.astral-core-capability = {
    wantedBy = [ "paths.target" ];
    pathConfig = {
      # 只用 PathChanged，不要同时用 PathExists。
      # 两者监视同一路径时，path 单元每次被评估都会立刻满足 PathExists →
      # 服务执行完（exit 0）后重新评估又立即满足 → 密集触发，10 秒内超过
      # StartLimitBurst=5 即 start-limit-hit（实测 5 次全在同一秒，
      # switch 因此报 status=4）。
      # PathChanged 已覆盖「core 新建或更新」这一唯一需要设权限的时机；
      # 服务自身也有幂等检查（已有 cap 且内容一致则 exit 0）。
      PathChanged = core;
      Unit = "astral-core-capability.service";
    };
  };
}
