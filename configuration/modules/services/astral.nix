# Astral TUN 权限：GUI 在用户目录动态管理 core，因此用 path unit 监听并由 root 设置文件 capability。
{ pkgs, username, ... }:

let
  core = "/home/${username}/.local/share/astral-core/app/astral-core";
  setcap = "${pkgs.libcap.out}/bin/setcap";
  getcap = "${pkgs.libcap.out}/bin/getcap";
in
{
  systemd.services.astral-core-capability = {
    description = "Grant Astral core CAP_NET_ADMIN";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "astral-core-capability" ''
        if [ ! -f "${core}" ]; then
          exit 0
        fi

        if ${getcap} "${core}" 2>/dev/null | grep -q 'cap_net_admin=ep'; then
          exit 0
        fi

        ${setcap} cap_net_admin=ep "${core}"
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
      # 服务自身也有幂等检查（已有 cap 则 exit 0）。
      PathChanged = core;
      Unit = "astral-core-capability.service";
    };
  };
}
