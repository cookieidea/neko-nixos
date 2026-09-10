# skills

AI agent skills（opencode / Claude Code 通用格式）。安装：`cp -r skills/* ~/.claude/skills/`（opencode 自动扫描该外部目录）。

当前只保留 NixOS 相关；其余（rust-skills 38 个、anthropics 官方 19 个、material-3）已禁用移除——如需恢复见各上游仓库：
- https://github.com/actionbook/rust-skills
- https://github.com/anthropics/skills
- https://github.com/hamen/material-3-skill

## 保留

- **nixos-managing** — NixOS 管理通用参考（rebuild/flake/部署/impermanence/LUKS/监控/反模式），来源 https://github.com/michalzubkowicz/nixos-management-skill
- **neko-nixos-recipes** — 本机（ATRI / NixOS 26.05）实战经验：构建流水线、镜像/缓存、打包模式、运行时库疑难、系统维护、agenix
- **cookie-profile** — 用户偏好与协作方式画像
