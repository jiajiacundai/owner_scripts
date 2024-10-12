#!/bin/sh

# 使用 curl 从世界时间API获取时间
TIME=$(curl -s http://worldtimeapi.org/api/timezone/Etc/UTC | grep -o '"datetime":"[^"]*' | cut -d'"' -f4)

if [ -z "$TIME" ]; then
    echo "无法获取时间"
    exit 1
fi

# 显示获取到的ISO时间，调试用
echo "获取到的UTC时间: $TIME"

# 将 ISO 8601 格式的时间转换为 date 可识别的格式（添加 -u 表示使用 UTC 时间）
FORMATTED_TIME=$(date -u -d "$TIME" +"%Y%m%d%H%M.%S")

# 使用 date 命令设置系统时间
sudo date "$FORMATTED_TIME"

echo "系统时间已同步为: $(date)"
