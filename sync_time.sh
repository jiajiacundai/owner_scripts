#!/bin/bash
# 使用curl从世界时间API获取时间
TIME=$(curl -s http://worldtimeapi.org/api/timezone/Etc/UTC | grep -o '"datetime":"[^"]*' | cut -d'"' -f4)
if [ -z "$TIME" ]; then
    echo "无法获取时间"
    exit 1
fi

# 检查当前时区是否为上海
CURRENT_TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ "$CURRENT_TIMEZONE" != "Asia/Shanghai" ]; then
    echo "当前时区为 $CURRENT_TIMEZONE，设置时区为 Asia/Shanghai"
    timedatectl set-timezone Asia/Shanghai
else
    echo "当前时区已为 Asia/Shanghai"
fi

# 将ISO 8601格式的时间转换为date可识别的格式
FORMATTED_TIME=$(date -d "$TIME" +"%Y-%m-%d %H:%M:%S")

# 使用date命令设置系统时间
date -s "$FORMATTED_TIME"

echo "系统时间已同步为: $(date)"
