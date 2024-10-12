#!/bin/sh

# 使用 curl 从世界时间API获取时间
TIME=$(curl -s http://worldtimeapi.org/api/timezone/Etc/UTC | grep -o '"datetime":"[^"]*' | cut -d'"' -f4)

if [ -z "$TIME" ]; then
    echo "无法获取时间"
    exit 1
fi

# 显示获取到的ISO时间，调试用
echo "获取到的UTC时间: $TIME"

# 去除时间字符串中的'T'和'Z'，将其转换为date可识别的格式
CLEAN_TIME=$(echo "$TIME" | sed 's/T/ /; s/\..*//; s/Z//')

# 显示处理后的时间字符串，调试用
echo "处理后的时间字符串: $CLEAN_TIME"

# 如果 timedatectl 命令可用，使用它来设置时间
if command -v timedatectl > /dev/null 2>&1; then
    sudo timedatectl set-time "$CLEAN_TIME"
else
    # 使用 date -u 解析并设置 UTC 时间
    FORMATTED_TIME=$(date -u -d "$CLEAN_TIME" +"%Y%m%d%H%M.%S")
    sudo date "$FORMATTED_TIME"
fi

echo "系统时间已同步为: $(date)"
