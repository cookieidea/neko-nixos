{
  description = "Astral build dev shell (used by build.sh)";

  inputs.nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          flutter
          dart
          clang
          cmake
          ninja
          pkg-config
          rustc
          cargo
          rustup
          git
          unzip
          protobuf
          perl
        ];

        buildInputs = with pkgs; [
          gtk3
          glib
          libayatana-appindicator
          libdbusmenu-gtk3
          libclang
        ];

        shellHook = ''
          export PUB_CACHE="$HOME/.pub-cache"
          export PROTOC="${pkgs.protobuf}/bin/protoc"
          export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
          export CC="${pkgs.clang}/bin/clang"
          flutter config --no-analytics --enable-linux-desktop >/dev/null 2>&1 || true
        '';
      };
    };
}
