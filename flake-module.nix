# flake 的 outputs。inputs 由 flake-file.nix 声明，flake.nix 自动生成。
{ inputs, ... }:

{
  outputs =
    _:
    let
      inherit (inputs)
        nixpkgs
        home-manager
        cooknixvim
        bilihud
        nix-cachyos-kernel
        noctalia
        noctalia-greeter
        agenix
        bestclient
        mark-shot
        llm-agents-nix
        nix-flatpak
        fenix
        nix-vscode-extensions
        nixcord
        linuxqq-wayland-fix
        neko-pkgs
        ;

      self = inputs.self;

      system = "x86_64-linux";
      forAllSystems = nixpkgs.lib.genAttrs [ system ];
      username = "cookie";
      hostname = "ATRI";
      desktop = "niri";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          rocmSupport = true;
          # 新版 nixpkgs 把 gtk+（gtk2）标记为 broken；这里只依赖它的
          # 传递闭包，降级为警告而不是求值失败。
          problems.handlers."gtk+".broken = "warn";
        };
        overlays = (import ./configuration/overlays/list.nix { inherit nix-cachyos-kernel; })
          ++ [ neko-pkgs.overlays.default ];
      };

      selfPackages = import ./configuration/pkgs { inherit pkgs; };
      hmLib = import ./configuration/home/lib.nix { inherit pkgs selfPackages username; };

      hmModule = {
        imports = [ home-manager.nixosModules.home-manager ];

        _module.args = { inherit desktop username selfPackages bestclient; };

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.sharedModules = [ nixcord.homeModules.nixcord ];
        home-manager.users.${username} = import ./configuration/home.nix;
        home-manager.extraSpecialArgs = {
          inherit
            desktop
            username
            cooknixvim
            bilihud
            selfPackages
            noctalia
            bestclient
            mark-shot
            llm-agents-nix
            hmLib
            fenix
            nix-vscode-extensions
            nixcord
            ;
        };
      };
    in
    {
      packages.${system} = selfPackages.public;

      nixosConfigurations = {
        ${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit hostname noctalia-greeter; };
          modules = [
            ./configuration/system.nix
            hmModule
            agenix.nixosModules.default
            (import ./configuration/overlays { inherit nix-cachyos-kernel; })
            nix-flatpak.nixosModules.nix-flatpak
            linuxqq-wayland-fix.nixosModules.default
          ];
        };
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          targets = "configuration flake.nix flake-file.nix flake-module.nix";
        in
        {
          deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
            cd ${./.}
            deadnix --fail --no-underscore ${targets}
            touch $out
          '';

          # 完整构建整机配置：`nix flake check` 会把系统按真实配置构建一遍，
          # 坏掉的包在 check 阶段就暴露，不必等到 switch 失败。
          nixos = self.nixosConfigurations.ATRI.config.system.build.toplevel;

          # 格式检查：确保所有 .nix 文件符合 nixfmt 风格。
          formatting = pkgs.runCommand "formatting-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            cd ${./.}
            nixfmt --check ${targets} $(find configuration -name '*.nix')
            touch $out
          '';
        }
      );
    };
}
