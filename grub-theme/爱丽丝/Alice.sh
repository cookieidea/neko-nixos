#!/bin/bash
# Copyright (c) 2024 Gabbar
# Visit https://GitHub.com/Gabbar-v7
# modify by bibimingming
# visit https://GitHub.com/bibimingming
#chinese by bibimingming
#follow MIT!

# Cool designed header
echo "#####################################################"
echo "#                                                   #"
echo "#         GameDevelop GRUB Theme Installer          #"
echo "#                 bibimingming                      #"
echo "#                                                   #"
echo "#                                                   #"
echo "#                                                   #"
echo "#####################################################"
echo ""

# Ask for sudo password
echo "为安装主题请输入sudo密码:"
sudo -v

# Variables
THEME_DIR="/boot/grub/themes"
THEME_NAME="Alice"
THEME_PATH="$THEME_DIR/$THEME_NAME/theme.txt"
GRUB_CONFIG="/etc/default/grub"

# Check if the theme folder exists locally
if [ ! -d "$THEME_NAME" ]; then
  echo "错误: 主题文件夹 '$THEME_NAME' 未在本地找到. 确保该文件夹位于当前目录中."
  exit 1
fi

# Check if the theme directory exists in /boot/grub/themes
if [ -d "$THEME_DIR/$THEME_NAME" ]; then
  echo "主题文件夹 '$THEME_NAME' 已存在于 $THEME_DIR."
  echo "移除现有主题..."
  sudo rm -rf "$THEME_DIR/$THEME_NAME"
  echo "现有主题已删除."
fi

# Copy the theme folder to /boot/grub/themes
echo "复制到 $THEME_DIR..."
sudo mkdir -p "$THEME_DIR"
sudo cp -r "$THEME_NAME" "$THEME_DIR/"
echo "主题复制成功."

# Update the GRUB configuration
echo "更新GRUB以使用主题..."
sudo sed -i "/^GRUB_THEME=/d" "$GRUB_CONFIG" # Remove any existing GRUB_THEME entry
echo "GRUB_THEME=\"$THEME_PATH\"" | sudo tee -a "$GRUB_CONFIG"

# Update GRUB
echo "更新 GRUB..."
if command -v update-grub &> /dev/null; then
  # Debian-based systems
  sudo update-grub
elif command -v grub-mkconfig &> /dev/null; then
  # Arch-based systems
  sudo grub-mkconfig -o /boot/grub/grub.cfg
else
  echo "错误: 未能找到GRUB更新命令 (update-grub or grub-mkconfig)."
  exit 1
fi

# Confirmation message
echo ""
echo "主题已成功安装!"

# Pause to let the user see the output
echo "键入任意按键以退出..."
read -n 1 -s

# Exit
exit 1
