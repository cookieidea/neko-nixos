---
name: cookie-profile
description: 用户 cookie 的偏好与协作方式画像。Use when starting any task for this user — covers language, communication style, decision habits, tool preferences, and approval flow. Load early to avoid misjudging scope or tone.
---

# 用户画像：cookie

## 基本环境

- 主机 ATRI（NixOS 26.05，niri + Noctalia，AMD RX 6600，双系统 Win/GRUB）
- 中文交流，技术词中英混用；回复保持中文、简洁直接
- 主力项目：neko-nixos（系统配置 flake）、Breeze（Flutter fork）、若干自打包应用
- 桌面用法偏重度：MC（Java+基岩）、Steam 游戏、OBS、音频处理（PureVox）

## 沟通风格

- **消息极简**："1"、"继续"、"不行"、"可以"——要么是催促/确认，要么是测试结果回报。收到后直接推进下一步，不要反问细节
- 同一请求重复发送（如连发多条相同消息）= 上条没被执行，重做即可，不必道歉
- 汇报结果要**结论先行 + 表格/列表**，数字说话（释放多少 G、哪个提交号）
- 不喜欢长篇解释原理——除非问"为什么/怎么回事"（此时要给完整根因链）
- **允许用 python**（早期不让用，2026-09 明确解除："可以用python"）——文件批量编辑/JSON 处理优先 python

## 决策习惯

- **给方案时先要最小验证路径**：能 30 秒手动验证的别写自动化
- **回退要干净**：经常要求"撤销""撤回提交"——必须连 git 历史一起抹（force push），不是内容级 revert；但**有的撤回要保留**（"core的更新不要撤回"）——撤回前先确认范围，别自作主张扩大
- **"先不要上传"**：提交推送前等确认，验证过了说"推送"才推
- 失败重试容忍度高（可以连续试 5+ 种方案），但**同一方案失败两次必须换思路**，别死磕
- 偏好"顺手做了"：清理残留、修注释措辞这类小事不用请示，做完汇报即可
- 上游有 bug 时愿意 fork 自己修（BedrockBoot/axolotl 都这么干过），但修不动时接受放弃换方案（"算了不要管astral core了"）

## 工具/技术偏好

- 声明式优先：能进 home.nix/configuration.nix 的不写散装脚本；脚本要进 dotfiles 管理
- 注释要**精简**（要求过"把注释精简一下"、"吧pkgs里没用的注释都给去掉"）——保留升级提示和踩坑警告，删叙事性内容
- 版本策略：不追新（axolotl 那次要过 beta，崩了之后接受回稳定版）；包升级倾向最新稳定 release
- JDK 用 Zulu 全家桶（25 默认 + 21/17/8）；MC 启动器 HMCL
- 缓存策略：自建 nekobox.cachix.org，改完系统必推
- 不用 KDE（问过装不装，最后没装）；Alt+Tab 要标准窗口切换行为

## 红线

- **Steam 相关目录不要动**（"不要动"——compatibilitytools.d 的 5.2G Proton 变体保留）
- astral-core 保持开机自启（生命周期管理试验失败后撤回了）
- 系统配置全部走 git 提交记录，不留未提交状态过夜（"把修改都提交一下吧"是高频指令）
- 敏感信息（密码/密钥/token）**永远不写入**任何可能提交的文件——sudo 密码在会话内使用，不落盘

## 任务节奏

- 一次丢多个任务很常见（"更新X，完成后Y，然后Z"）——用 todo 列表管理，按序执行，每完成一项即时汇报
- 深夜也是工作时间（22:00-01:00 高频）
- 调试时的日志/崩溃文件会主动给路径（mclo.gs 链接、Downloads 导出目录），拿到就直接读
