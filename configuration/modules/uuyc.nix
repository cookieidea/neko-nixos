# 网易 UU 远程（uuyc）。官方 deb 的二进制会 readlink /proc/self/exe 反推安装目录，
# 并在其下创建 config/、写日志，所以不能直接从只读 store 运行。这里用 oneshot
# 把 store 内容 reflink 到可写的 /opt/uuyc；日志和 /var/lib/Netease 保持真实目录。
{
  pkgs,
  config,
  selfPackages,
  ...
}:

let
  uuyc = selfPackages.uuyc;
  prefix = "/opt/uuyc";
  stateDir = "/var/lib/Netease/uuyc";

  logDirs = [
    "client"
    "client/log"
    "server"
    "server/log"
    "healthd"
    "healthd/log"
    "upgrade"
    "upgrade/log"
    "service"
    "service/log"
    "launcher"
    "launcher/log"
    "uuyc-cli"
    "uuyc-cli/log"
    "webview_host"
    "wow_helper_plugin"
    "wow_helper_plugin/log"
  ];
  writableLogDirs = [
    "client"
    "client/log"
    "upgrade"
    "upgrade/log"
    "launcher"
    "launcher/log"
    "uuyc-cli"
    "uuyc-cli/log"
    "webview_host"
    "wow_helper_plugin"
    "wow_helper_plugin/log"
  ];

  sslEnv = [
    "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
    "SSL_CERT_DIR=/etc/ssl/certs"
    "CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt"
  ];
in
{
  environment.systemPackages = [ uuyc ];

  # 随包 OpenSSL 的 OPENSSLDIR=/etc/ssl，默认信任库是 /etc/ssl/cert.pem；
  # NixOS 只生成 ca-bundle.crt，缺这个文件会导致 TLS 报 unknown_ca。
  environment.etc."ssl/cert.pem".source = config.security.pki.caBundle;

  systemd.tmpfiles.rules = [
    "d ${prefix} 0755 root root -"
    "d ${prefix}/config 0755 root root -"
    "d ${prefix}/setup 0755 root root -"
    "d ${prefix}/log 0755 root root -"
    # 上游 /usr/lib/uuyc：会话启动脚本、AppArmor 源文件。
    "L+ /usr/lib/uuyc - - - - ${uuyc}/usr/lib/uuyc"

    # 程序内部使用了这些绝对路径。
    "L+ /usr/bin/systemd-run - - - - ${pkgs.systemd}/bin/systemd-run"
    "L+ /usr/bin/gdbus - - - - ${pkgs.glib}/bin/gdbus"

    "d /var/lib/Netease 0755 root root -"
    "d ${stateDir} 0755 root root -"
    "d ${stateDir}/cache 0700 root root -"
    "d ${stateDir}/ftp_metadata 0700 root root -"
    "C ${stateDir}/install_config.ini 0644 root root - ${uuyc}/usr/lib/uuyc/install_config.ini"
  ]
  ++ map (d: "d ${prefix}/log/${d} 0755 root root -") logDirs
  ++ map (d: "d ${prefix}/log/${d} 1777 root root -") writableLogDirs;

  # 只读 store -> /opt/uuyc 的可写副本（btrfs reflink，几乎不占空间）。
  systemd.services.uuyc-prefix = {
    description = "Populate /opt/uuyc from the Nix store";
    wantedBy = [ "multi-user.target" ];
    before = [ "uuyc.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    restartTriggers = [ uuyc ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      install -d -m0755 ${prefix} ${prefix}/config ${prefix}/setup
      stamp=${prefix}/.store-path
      want=${uuyc}
      if [ "$(cat "$stamp" 2>/dev/null || true)" = "$want" ]; then
        exit 0
      fi
      for d in bin lib libexec plugins share; do
        rm -rf "${prefix}/$d"
        cp -a --reflink=auto "$want/opt/uuyc/$d" "${prefix}/$d"
      done
      printf '%s\n' "$want" > "$stamp"
    '';
  };

  systemd.sockets.uuyc = {
    description = "uuyc Service Control Socket";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "/run/uuyc-control.sock" ];
    socketConfig = {
      SocketMode = "0666";
      RemoveOnStop = true;
    };
  };

  systemd.services.uuyc = {
    description = "uuyc Server Supervisor";
    wantedBy = [ "multi-user.target" ];
    requires = [
      "uuyc.socket"
      "uuyc-prefix.service"
    ];
    after = [
      "uuyc.socket"
      "uuyc-prefix.service"
      "systemd-user-sessions.service"
    ];
    restartTriggers = [ uuyc ];
    startLimitIntervalSec = 60;
    startLimitBurst = 5;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${prefix}/bin/uuyc_service";
      Environment = [
        "LD_LIBRARY_PATH=${prefix}/lib"
        "PIPEWIRE_MODULE_DIR=${prefix}/lib/pipewire-0.3"
        "PIPEWIRE_CONFIG_PREFIX=${prefix}/share/pipewire"
        "SPA_PLUGIN_DIR=${prefix}/lib/spa-0.2"
        "NRD_LOG_ROOT=${prefix}/log"
      ]
      ++ sslEnv;
      Sockets = "uuyc.socket";
      RuntimeDirectory = "uuyc";
      RuntimeDirectoryMode = "0700";
      RuntimeDirectoryPreserve = "restart";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 15;
      KillMode = "mixed";
    };
  };
}
