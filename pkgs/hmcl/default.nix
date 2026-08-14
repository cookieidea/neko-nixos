# HMCL —— Hello Minecraft Launcher（JavaFX GUI，Minecraft 启动器）
#
# nixpkgs 自带 hmcl，但虚拟机（VMware/vmwgfx → llvmpipe 软件 GL）环境下
# JavaFX 的 Graphics Hardware Qualifier check 判定 GPU 不合格 → 回退
# SW Pipeline（纯软件渲染，性能差）。
#
# 修复：wrapper 注入 JAVA_TOOL_OPTIONS=-Dprism.forceGPU=true
# -Dprism.order=es2，跳过 qualifier check 强制 ES2 管线（llvmpipe 后端，
# 支持 shader，性能更好）。已验证：Prism Pipeline 从
# com.sun.prism.sw.SWPipeline 变为 com.sun.prism.es2.ES2Pipeline。
{ pkgs }:

let
  hmcl = pkgs.hmcl;
in
pkgs.writeShellScriptBin "hmcl" ''
  export JAVA_TOOL_OPTIONS="-Dprism.forceGPU=true -Dprism.order=es2"
  exec ${hmcl}/bin/hmcl "$@"
'' // {
  meta = hmcl.meta // { mainProgram = "hmcl"; };
}
