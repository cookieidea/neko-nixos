import os, shutil

BASE = r"C:/Users/jhbhy/WorkBuddy/2026-08-12-03-16-30/nixos-shorin-conversion"
SRC = os.path.join(BASE, "_src/repo/noctalia-dotfiles")
DOT = os.path.join(BASE, "dotfiles")

# 1) 把已适配的 niri / noctalia 移入 dotfiles/config（仅首次移动，已存在则跳过）
for d in ["niri", "noctalia"]:
    src_d = os.path.join(DOT, d)
    dst_d = os.path.join(DOT, "config", d)
    if os.path.isdir(src_d):
        os.makedirs(os.path.dirname(dst_d), exist_ok=True)
        shutil.move(src_d, dst_d)
        print(f"moved {src_d} -> {dst_d}")

EXCLUDE = {
    ".config/niri",
    ".config/noctalia/settings.json",
    ".config/fish/config.fish",
}

def is_text(path):
    try:
        with open(path, "rb" if False else "rb") as f:
            return b"\x00" not in f.read(4096)
    except Exception:
        return False

FISH_CONF = '''# SHORiN rice（源自原 config.fish，用户名已适配为 cookie）
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

# grub
abbr grub 'LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 sudo grub-mkconfig -o /boot/grub/grub.cfg'
# 小黄鸭补帧 需要steam安装正版小黄鸭
abbr lsfg 'LSFG_PROCESS="miyu"'
# fa运行fastfetch
abbr fa fastfetch
abbr reboot 'systemctl reboot'
function sl
	command sl | lolcat
end
function 滚
	sysup
end
function raw
	command ~/.local/bin/random-anime-wallpaper-noctalia $argv
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/cookie/.lmstudio/bin
# End of LM Studio CLI section
'''

copied = []
for root, dirs, files in os.walk(SRC):
    for fn in files:
        full = os.path.join(root, fn)
        rel = os.path.relpath(full, SRC).replace(os.sep, "/")
        if any(rel == ex or rel.startswith(ex + "/") for ex in EXCLUDE):
            continue
        if rel.startswith(".config/"):
            dest = os.path.join(DOT, "config", rel[len(".config/"):])
        elif rel in (".gtkrc-2.0", ".vimrc"):
            dest = os.path.join(DOT, "home", rel)
        elif rel.startswith(".local/"):
            dest = os.path.join(DOT, "local", rel[len(".local/"):])
        else:
            continue
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        if is_text(full):
            with open(full, "r", encoding="utf-8", errors="replace") as f:
                data = f.read()
            data = data.replace("/home/shorin", "/home/cookie")
            with open(dest, "w", encoding="utf-8") as f:
                f.write(data)
        else:
            shutil.copy2(full, dest)
        copied.append(rel)

# 写 fish conf.d（避免与 programs.fish.interactiveShellInit 冲突）
confd = os.path.join(DOT, "config", "fish", "conf.d")
os.makedirs(confd, exist_ok=True)
with open(os.path.join(confd, "shorin.fish"), "w", encoding="utf-8") as f:
    f.write(FISH_CONF)

# 生成 xdg.configFile 片段
xdg_lines = []
for root, dirs, files in os.walk(os.path.join(DOT, "config")):
    for fn in files:
        full = os.path.join(root, fn)
        rel = os.path.relpath(full, os.path.join(DOT, "config")).replace(os.sep, "/")
        if rel == "fish/config.fish":
            continue
        xdg_lines.append('    "%s".source = ./dotfiles/config/%s;' % (rel, rel))

# 生成 home.file 片段
home_lines = []
home_dir = os.path.join(DOT, "home")
if os.path.isdir(home_dir):
    for fn in sorted(os.listdir(home_dir)):
        full = os.path.join(home_dir, fn)
        if os.path.isfile(full):
            # fn 本身已带前导点（.gtkrc-2.0 / .vimrc），不要再补点
            home_lines.append('    "%s".source = ./dotfiles/home/%s;' % (fn, fn))
local_dir = os.path.join(DOT, "local")
for root, dirs, files in os.walk(local_dir):
    for fn in files:
        full = os.path.join(root, fn)
        rel = os.path.relpath(full, local_dir).replace(os.sep, "/")
        exe = " executable = true;" if (rel.startswith("bin/") or rel.endswith(".sh")) else ""
        home_lines.append('    ".local/%s".source = ./dotfiles/local/%s;%s' % (rel, rel, exe))

xdg_block = "  xdg.configFile = {\n" + "\n".join(sorted(xdg_lines)) + "\n  };"
home_block = "  home.file = {\n" + "\n".join(sorted(home_lines)) + "\n  };"

# fish：保持 programs.fish.enable = true（HM 会写 config.fish 并接管 starship/zoxide init），
# 不碰 interactiveShellInit 选项，改为把 SHORiN 的内容放到 conf.d/shorin.fish（fish 自动 source conf.d/*）。
fish_init = '''    fish = {
      enable = true;
    };'''

def replace_block(text, start_marker, end_marker, new_block):
    lines = text.split("\n")
    si = next(i for i, l in enumerate(lines) if l == start_marker)
    ei = next(j for j in range(si + 1, len(lines)) if lines[j] == end_marker)
    return "\n".join(lines[:si] + new_block.split("\n") + lines[ei + 1:])

hn_path = os.path.join(BASE, "home.nix")
with open(hn_path, "r", encoding="utf-8") as f:
    hn = f.read()

# 替换 xdg.configFile 块（含其内部），并紧跟 home.file 块
hn = replace_block(hn, "  xdg.configFile = {", "  };", xdg_block + "\n\n" + home_block)
# 替换 fish 块
hn = replace_block(hn, "    fish = {", "    };", fish_init)

with open(hn_path, "w", encoding="utf-8") as f:
    f.write(hn)

# 校验
bad = []
for root, dirs, files in os.walk(DOT):
    for fn in files:
        full = os.path.join(root, fn)
        if is_text(full):
            with open(full, "r", encoding="utf-8", errors="replace") as f:
                if "/home/shorin" in f.read():
                    bad.append(os.path.relpath(full, BASE))
print("COPIED:", len(copied))
print("xdg entries:", len(xdg_lines), "home entries:", len(home_lines))
print("remaining /home/shorin in dotfiles:", bad if bad else "NONE")
