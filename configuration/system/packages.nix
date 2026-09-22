# 系统级工具包：进 /run/current-system/sw，对所有用户可见。
#
# 只放「系统功能真正依赖」或「跨用户共享」的工具。用户自己的日常软件
# 应放 configuration/home/packages/（Home Manager 用户环境）。
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 会话/桌面功能依赖。
    wlsunset         # 护眼（niri binds 调用）
    inotify-tools    # 壁纸同步脚本依赖
    ddcutil          # 显示器亮度（DDC/CI）
    xwayland-satellite   # X11 兼容层（微信/QQ 等）
    gamescope        # 基岩版鼠标修复（--force-grab-cursor）
    grim             # Wayland 截图（mark-shot / niri）
    kdePackages.layer-shell-qt   # mark-shot overlay 用的 Qt6 layer-shell
    gtk-layer-shell  # GTK Wayland layer-shell

    # 虚拟化后端（libvirtd / virt-manager）。
    qemu swtpm
    dnsmasq          # libvirt NAT 网络依赖

    # Waydroid 相关。
    wl-clipboard     # 剪贴板共享
    android-tools    # adb（GPS 转发）
    waydroid-helper  # 配置 GUI
    rclone bindfs    # waydroid-helper 依赖

    # 磁盘与硬件诊断。
    gparted dosfstools exfatprogs f2fs-tools udftools xfsprogs
    libva-utils      # vainfo 硬解诊断
    radeontop        # AMD 占用监控

    # 基础命令行工具（跨用户共享）。
    git
    tmux             # scratchpad
    ripgrep tree wget unzip zip yq b3sum
    cachix
  ];
}
