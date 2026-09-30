{ pkgs, llm-agents-nix, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  dsh = llm-agents-nix.packages.${system}.dsh.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace \
        $out/lib/node_modules/@deepseek-ai/dsh/node_modules/node-addon-require-builtin/lib/index.js \
        --replace-fail '    return api.requireBuiltin(moduleId);' \
        '    if (process.execArgv.includes("--expose-internals")) { try { return require(moduleId); } catch {} } return api.requireBuiltin(moduleId);'
    '';
  });
in
{
  home.packages = with pkgs; [
    glib
    dsh
    llm-agents-nix.packages.${system}.opencode
  ];
}
