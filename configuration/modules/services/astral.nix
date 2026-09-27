# Astral TUN 需要 CAP_NET_ADMIN，但 GUI 把 core 释放到用户可写的
# ~/.local/share/astral-core/app/ 下运行。直接对那里 setcap 等于允许用户
# 替换后提权，故每次都从只读 store 取副本、设 cap、原子改名就位。
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

        # 目录由 GUI 创建，尚未出现时等 path unit 再触发
        [ -d "${coreDir}" ] || exit 0

        # 已就位且一致则跳过
        if [ -f "${core}" ] && cmp -s "${storeCore}" "${core}" \
           && ${getcap} "${core}" 2>/dev/null | grep -q 'cap_net_admin=ep'; then
          exit 0
        fi

        # 先写临时文件再改名，避免设完 cap 又被替换
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
      # 不要同时用 PathExists：服务退出后会立刻再次满足条件，触发到
      # start-limit-hit
      PathChanged = core;
      Unit = "astral-core-capability.service";
    };
  };
}
