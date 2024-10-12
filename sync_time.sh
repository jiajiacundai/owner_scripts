#!/bin/sh

# 使用 curl 从世界时间API获取时间
TIME=$(curl -s http://worldtimeapi.org/api/timezone/Etc/UTC | grep -o '"datetime":"[^"]*' | cut -d'"' -f4)

if [ -z "$TIME" ]; then
    echo "无法获取时间"
    exit 1
fi

# 显示获取到的ISO时间，调试用
echo "获取到的UTC时间: $TIME"

# 去除时间字符串中的'T'和'Z'，并保持标准的时间格式（只去掉小数部分）
CLEAN_TIME=$(echo "$TIME" | sed 's/\..*//')

# 显示处理后的时间字符串，调试用
echo "处理后的时间字符串: $CLEAN_TIME"

# 如果 timedatectl 命令可用，使用它来设置时间
if command -v timedatectl > /dev/null 2>&1; then
    sudo timedatectl set-time "$CLEAN_TIME"
else
    # 直接使用标准的时间格式设置时间，不再自定义格式
    sudo date -u -d "$CLEAN_TIME"
fi

echo "系统时间已同步为: $(date)"
