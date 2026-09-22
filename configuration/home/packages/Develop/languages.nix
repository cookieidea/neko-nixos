{ pkgs, fenix, ... }:

{
  home.packages = with pkgs; [
    (pkgs.lib.setPrio (-20) pkgs.zulu25)
    (pkgs.lib.setPrio (-15) pkgs.zulu21)
    (pkgs.lib.setPrio (-10) pkgs.zulu17)
    (pkgs.lib.setPrio (-5) pkgs.zulu8)
    (python3.withPackages (ps: [ ps.pip ]))
    uv
    # Rust 工具链经 fenix 提供：一条 toolchain 即含 rustc / cargo / rustfmt
    # 与 clippy、rust-std 等组件，版本由 flake.lock 锁定；需要 nightly 或
    # 固定版本时可换用 fenix.packages.<system>.{latest,complete,minimal}。
    fenix.packages.${pkgs.stdenv.hostPlatform.system}.stable.toolchain
    go
    nodejs_22
  ];
}
