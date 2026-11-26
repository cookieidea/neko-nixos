# flake 的 outputs。inputs 由 flake-file.nix 声明，flake.nix 自动生成。
{ inputs, config, ... }:

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
        overlays = (import ./configuration/overlays/list.nix { inherit nix-cachyos-kernel; }) ++ [
          neko-pkgs.overlays.default
        ];
      };

      selfPackages = import ./configuration/pkgs { inherit pkgs; };
      hmLib = import ./configuration/home/lib.nix { inherit pkgs selfPackages username; };

      hmModule = {
        imports = [ home-manager.nixosModules.home-manager ];

        _module.args = {
          inherit
            desktop
            username
            selfPackages
            bestclient
            ;
        };

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

      # flake-file 提供的写回工具：nix run .#write-flake
      # 这些值是 `pkgs -> derivation` 的函数，需要按系统调用后包成 app。
      apps = forAllSystems (
        system:
        let
          p = nixpkgs.legacyPackages.${system};
          mkApp = drv: {
            type = "app";
            program = nixpkgs.lib.getExe drv;
          };
        in
        {
          write-flake = mkApp (config.flake-file.apps.write-flake p);
          write-inputs = mkApp (config.flake-file.apps.write-inputs p);
          write-lock = mkApp (config.flake-file.apps.write-lock p);
        }
      );

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

          # 注意：不要把 nixosConfigurations 的 toplevel 放进 checks。
          # `nix flake check` 会构建 checks 里的每个 derivation，整机闭包
          # 含 ROCm/Steam 等重量级依赖，CI runner 扛不住；而且 uuyc 这类
          # 「永远最新版」的包 hash 不可复现，会让 CI 必挂。
          # 整机的求值检查由 flake-check.yml 的 eval 步骤单独负责。

          # 格式检查只覆盖 flake 骨架文件。
          # configuration/ 下有大量历史配置尚未按 nixfmt 排版，
          # 全量检查会让 CI 必挂；需要时本地跑 `nix fmt .` 逐步收敛。
          formatting = pkgs.runCommand "formatting-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            cd ${./.}
            nixfmt --check flake.nix flake-file.nix flake-module.nix
            touch $out
          '';
        }
      );
    };
}
