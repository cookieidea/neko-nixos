function f
    # Fastfetch 随机壁纸：前台立即显示，后台异步补充缓存。

    # 配置。
    # 是否清理 Fastfetch 生成的图片缓存。
    set -l CLEAN_CACHE_MODE true
    
    set -l DOWNLOAD_BATCH_SIZE 10
    set -l MAX_CACHE_LIMIT 100
    set -l MIN_TRIGGER_LIMIT 60
    
    set -l MAX_USED_LIMIT 50
    
    # 提示语言。
    
    set -l IS_ZH true
    if not string match -q -r "^zh" "$LANG"
        set IS_ZH false
    end

    set -l MSG_WAIT "库存不够啦！正在去搬运新的图片，请稍等哦..."
    set -l MSG_NET_ERR "网络好像不太通畅，无法下载新图片 QAQ"
    set -l MSG_FAIL "图片获取失败了，这次只能先显示默认的 Logo 啦 QAQ"

    if test "$IS_ZH" = false
        set MSG_WAIT "Out of stock! Fetching new images, please wait..."
        set MSG_NET_ERR "Network seems unstable, cannot download new images QAQ"
        set MSG_FAIL "Failed to get image, falling back to default Logo QAQ"
    end
    
    # 参数和 Fastfetch 选项。
    
    set -l ARGS_FOR_FASTFETCH
    for arg in $argv
        # 显示帮助。
        if test "$arg" = "-h"; or test "$arg" = "--help"
            if test "$IS_ZH" = true
                echo "========================================================"
                echo "    f - 随机二次元美少女生成器暨 Fastfetch 终端看板娘"
                echo "========================================================"
                echo ""
                echo "用法模式："
                echo "  f       : 标准模式。随机生成一张美少女图片同时显示系统信息。"
                echo "  fwatch  : 持续运行模式。适合挂在副屏当作动态看板娘。"
                echo ""
                echo "进阶技巧："
                echo "  你可以直接在命令后追加原生 fastfetch 的参数。"
                echo "  例如 f --logo-width 40 可以单独控制本次生成的图片宽度。"
                echo "========================================================"
            else
                echo "========================================================"
                echo "    f - Random Anime Girl Generator and Fastfetch Mascot"
                echo "========================================================"
                echo ""
                echo "Usage Modes:"
                echo "  f       : Standard mode. Spawns a random safe for work anime girl for your terminal."
                echo "  fwatch  : Continuous mode. Use with the watch command, perfect for a secondary monitor mascot."
                echo ""
                echo "Advanced Tips:"
                echo "  You can append native fastfetch arguments directly after the command."
                echo "  For example, f --logo-width 40 will control the width of the generated image."
                echo "========================================================"
            end
            return 0
        else
            set -a ARGS_FOR_FASTFETCH $arg
        end
    end
    
    # 缓存目录和并发锁。
    set -l CACHE_DIR "$HOME/.cache/fastfetch_waifu"
    set -l LOCK_FILE "/tmp/fastfetch_waifu.lock"
    
    set -l USED_DIR "$CACHE_DIR/used"
    
    mkdir -p "$CACHE_DIR"
    mkdir -p "$USED_DIR"
    
    # 网络、下载和后台补货。

    function check_network
        curl -sI --connect-timeout 2 "http://captive.apple.com/hotspot-detect.html" >/dev/null 2>&1
        return $status
    end
    
    function get_random_url
        set -l TIMEOUT --connect-timeout 5 --max-time 15
        set -l RAND (math (random) % 3 + 1)
        
        switch $RAND
            case 1
                curl -s $TIMEOUT "https://api.waifu.im/images?IncludedTags=waifu&IsNsfw=false" | jq -r '.images[0].url'
            case 2
                curl -s $TIMEOUT "https://nekos.best/api/v2/waifu" | jq -r '.results[0].url'
            case 3
                curl -s $TIMEOUT "https://api.waifu.pics/sfw/waifu" | jq -r '.url'
        end
    end
    
    function download_one_image -V CACHE_DIR
        set -l URL (get_random_url)
        if string match -qr "^http" -- "$URL"
            set -l FILENAME "waifu_"(date +%s%N)"_"(random)".jpg"
            set -l TARGET_PATH "$CACHE_DIR/$FILENAME"
            
            curl -s -L --connect-timeout 5 --max-time 15 -o "$TARGET_PATH" "$URL"
            
            if test -s "$TARGET_PATH"
                if command -v file >/dev/null 2>&1
                    if not file --mime-type "$TARGET_PATH" | grep -q "image/"
                        rm -f "$TARGET_PATH"
                    end
                end
            else
                rm -f "$TARGET_PATH"
            end
        end
    end
    
    function background_job -V CACHE_DIR -V LOCK_FILE -V MIN_TRIGGER_LIMIT -V DOWNLOAD_BATCH_SIZE -V MAX_CACHE_LIMIT
        # 后台 shell 需要重新导入这些函数。
        set -l get_random_url_def (functions get_random_url | string collect)
        set -l download_one_image_def (functions download_one_image | string collect)
        set -l check_network_def (functions check_network | string collect)
        
        fish -c "
            # 后台任务脱离终端。
            trap '' HUP

            $get_random_url_def
            $download_one_image_def
            $check_network_def
            
            # 防止并发补货。
            flock -n 200 || exit 1

            # 无网络时直接结束后台任务。
            if not check_network
                exit 0
            end
            
            # 传入缓存目录。
            set CACHE_DIR '$CACHE_DIR'
            
            # 检查是否需要补货。
            set CURRENT_COUNT (find \$CACHE_DIR -maxdepth 1 -name '*.jpg' 2>/dev/null | wc -l)
            
            if test \$CURRENT_COUNT -lt $MIN_TRIGGER_LIMIT
                for i in (seq 1 $DOWNLOAD_BATCH_SIZE)
                    download_one_image
                    sleep 0.5
                end
            end
            
            # 删除超出上限的旧图片。
            set FINAL_COUNT (find \$CACHE_DIR -maxdepth 1 -name '*.jpg' 2>/dev/null | wc -l)
            if test \$FINAL_COUNT -gt $MAX_CACHE_LIMIT
                set DELETE_START_LINE (math $MAX_CACHE_LIMIT + 1)
                ls -tp \$CACHE_DIR/*.jpg 2>/dev/null | tail -n +\$DELETE_START_LINE | xargs -I {} rm -- '{}'
            end
        " 200>"$LOCK_FILE" &
        
        # 让后台任务脱离当前终端。
        disown
    end
    
    # 选择图片并运行 Fastfetch。
    
    set -l FILES $CACHE_DIR/*.jpg
    set -l NUM_FILES (count $FILES)
    
    # Fish glob 无匹配时需要额外检查。
    if test "$NUM_FILES" -eq 1; and not test -f "$FILES[1]"
        set NUM_FILES 0
        set FILES
    end
    
    set -l SELECTED_IMG ""
    
    if test "$NUM_FILES" -gt 0
        # 有缓存时随机选择。
        set -l RAND_INDEX (math (random) % $NUM_FILES + 1)
        set SELECTED_IMG "$FILES[$RAND_INDEX]"
        
        # 同时异步补货。
        background_job >/dev/null 2>&1
    else
        # 无缓存时先检查网络并同步下载一张。
        echo "$MSG_WAIT"
        
        if check_network
            download_one_image
        else
            echo "$MSG_NET_ERR"
        end
        
        set FILES $CACHE_DIR/*.jpg
        if test -f "$FILES[1]"
            set SELECTED_IMG "$FILES[1]"
            background_job >/dev/null 2>&1
        end
    end
    

    if test -n "$SELECTED_IMG"; and test -f "$SELECTED_IMG"

        fastfetch --logo "$SELECTED_IMG" --logo-preserve-aspect-ratio true $ARGS_FOR_FASTFETCH
        
        # 消费后移动到 used。
        mv "$SELECTED_IMG" "$USED_DIR/"
        
        # 清理超量的历史图片。
        set -l used_files $USED_DIR/*.jpg
        set -l used_count (count $used_files)
        
        if test "$used_count" -gt 0; and not test -f "$used_files[1]"
             set used_count 0
        end

        if test "$used_count" -gt "$MAX_USED_LIMIT"
            # 保留最新的图片。
            set -l skip_lines (math "$MAX_USED_LIMIT" + 1)
            
            # 删除最旧的文件。
            set -l files_to_delete (ls -tp "$USED_DIR"/*.jpg 2>/dev/null | tail -n +$skip_lines)
            
            if test -n "$files_to_delete"
                rm -- $files_to_delete
            end
        end

        # 按配置清理 Fastfetch 缓存。
        if test "$CLEAN_CACHE_MODE" = true
            # 只清理转换缓存。
            rm -rf "$HOME/.cache/fastfetch/images"
        end
    else
        # 无可用图片时使用 Fastfetch 默认 logo。
        echo "$MSG_FAIL"
        fastfetch $ARGS_FOR_FASTFETCH
    end
end
