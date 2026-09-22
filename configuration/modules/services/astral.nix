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
      PathExists = core;
      PathChanged = core;
      Unit = "astral-core-capability.service";
    };
  };
}
