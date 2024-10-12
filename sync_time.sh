#!/bin/sh

# 使用curl从世界时间API获取时间
TIME=$(curl -s http://worldtimeapi.org/api/timezone/Etc/UTC | grep -o '"datetime":"[^"]*' | cut -d'"' -f4)

if [ -z "$TIME" ]; then
    echo "无法获取时间"
    exit 1
fi

# 将ISO 8601格式的时间转换为date可识别的格式
FORMATTED_TIME=$(date -d "$TIME" +"%Y%m%d%H%M.%S")

# 使用date命令设置系统时间
sudo date "$FORMATTED_TIME"

echo "系统时间已同步为: $(date)"
