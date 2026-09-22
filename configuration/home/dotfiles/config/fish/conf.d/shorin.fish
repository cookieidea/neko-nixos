# SHORiN 配置迁移。
set fish_greeting ""
fish_add_path ~/.local/bin

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function cat
	command bat --theme="base16" -- $argv
end

function ls
	command eza --icons=auto -- $argv
end

function lt
	command eza --icons=auto --tree -- $argv
end

function la
	command eza -l --icons=auto -- $argv
end

# 注：原 grub-mkconfig 缩写已移除 —— NixOS 下引导由 nixos-rebuild 管理，
# 且 grub-mkconfig 不在 PATH 中。
# 小黄鸭补帧。
abbr lsfg 'LSFG_PROCESS="miyu"'
# fa：运行 Fastfetch。
abbr fa fastfetch
abbr reboot 'systemctl reboot'
function sl
	command sl | lolcat
end
# 注：原 `滚` 调用 sysup（Arch 的更新别名），NixOS 下已不存在，
# 改用 nixos-rebuild switch。
function 滚
	sudo nixos-rebuild switch
end
function raw
	command ~/.local/bin/random-anime-wallpaper-noctalia $argv
end

# LM Studio CLI（若未安装则该路径无效，但不影响其他功能）。
if test -d $HOME/.lmstudio/bin
    set -gx PATH $PATH $HOME/.lmstudio/bin
end

