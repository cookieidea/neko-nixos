# ATRI 的 fish 交互配置：别名、函数与代理开关。
#
# 由原先 shorin.fish 与 nyxniri.fish 合并而来 —— 两者都源自 NyxNiri，
# 命名与 ATRI 无关且内含 Arch 专用逻辑。此处只保留 NixOS 下可用的部分，
# 并按 ATRI 重新命名。

set fish_greeting ""
fish_add_path ~/.local/bin

# ── 文件与目录 ──

# y：用 yazi 浏览，退出时 cd 到目标目录。
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
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

# cat：用 bat 显示（带语法高亮）。
function cat
    command bat --theme="base16" -- $argv
end

# ── 系统 ──

# 更新系统。原 `滚` 调用 sysup（Arch 别名），NixOS 下改为 nixos-rebuild。
function sysup
    sudo nixos-rebuild switch
end
function 滚
    sysup
end

abbr reboot 'systemctl reboot'

# ── 信息与娱乐 ──

abbr fa fastfetch
function sl
    command sl | lolcat
end

# raw：随机动画壁纸（脚本由 Home Manager 部署到 ~/.local/bin）。
function raw
    command ~/.local/bin/random-anime-wallpaper-noctalia $argv
end

# ── 补帧（小黄鸭）──

abbr lsfg 'LSFG_PROCESS="miyu"'

# ── 终端代理 ──
# 默认指向 FlClash 的混合端口；可用 proxy_on <端口|host:port> 覆盖。

set -g PROXY_ADDR "127.0.0.1:7890"

function proxy_on
    set -l addr "$PROXY_ADDR"
    if test (count $argv) -gt 0
        if string match -r '^\d+$' -- $argv[1]
            set addr "127.0.0.1:$argv[1]"
        else
            set addr "$argv[1]"
        end
    end

    set -gx http_proxy "http://$addr"
    set -gx https_proxy "http://$addr"
    set -gx all_proxy "socks5://$addr"
    set -gx HTTP_PROXY "http://$addr"
    set -gx HTTPS_PROXY "http://$addr"
    set -gx ALL_PROXY "socks5://$addr"
    echo "[+] 终端代理已开启 (Proxy: $addr)"
end

function proxy_off
    set -e http_proxy
    set -e https_proxy
    set -e all_proxy
    set -e HTTP_PROXY
    set -e HTTPS_PROXY
    set -e ALL_PROXY
    echo "[-] 终端代理已关闭"
end

function proxy_status
    echo "--- 代理环境变量 (Proxy Env) ---"
    for var in http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
        if set -q $var
            echo "$var: "$$var
        else
            echo "$var: [未设置]"
        end
    end

    echo ""
    echo "--- 连通性测试 (Connectivity) ---"
    echo -n "测试 Google.com... "
    set -l start (date +%s%3N)
    set -l code (curl -I -s --connect-timeout 3 -o /dev/null -w "%{http_code}" https://www.google.com 2>/dev/null)
    set -l end (date +%s%3N)
    if test "$code" = "200" -o "$code" = "301" -o "$code" = "302"
        set -l duration (math $end - $start)
        echo "成功 (HTTP $code, $duration ms)"
    else
        echo "失败"
    end

    echo -n "测试 GitHub.com... "
    set -l gh_start (date +%s%3N)
    set -l gh_code (curl -I -s --connect-timeout 3 -o /dev/null -w "%{http_code}" https://github.com 2>/dev/null)
    set -l gh_end (date +%s%3N)
    if test "$gh_code" = "200" -o "$gh_code" = "301" -o "$gh_code" = "302"
        set -l gh_duration (math $gh_end - $gh_start)
        echo "成功 (HTTP $gh_code, $gh_duration ms)"
    else
        echo "失败"
    end

    echo ""
    echo "--- IP 地理位置 (IP Location) ---"
    curl -s --connect-timeout 3 -m 3 cip.cc 2>/dev/null | head -n 3
end

# ── LM Studio CLI（未安装时不污染 PATH）──

if test -d $HOME/.lmstudio/bin
    set -gx PATH $PATH $HOME/.lmstudio/bin
end
