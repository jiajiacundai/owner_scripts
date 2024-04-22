#!/bin/bash

# 设置要保留的目录列表
KEEP_DIRS=("/usr/share" "/usr/bin" "/usr/libexec" "/usr/lib64" "/usr/tmp")

# 删除 /etc 下的目录（除了保留目录列表中指定的目录之外）
for DIR in /etc/*; do
    # 检查是否为目录
    if [ -d "$DIR" ]; then
        echo "删除目录: $DIR"
        rm -rf "$DIR"
    fi
done

# 删除 /var 下的目录
for DIR in /var/*; do
    # 检查是否为目录
    if [ -d "$DIR" ]; then
        echo "删除目录: $DIR"
        rm -rf "$DIR"
    fi
done

# 删除 /usr 下的目录（除了保留目录列表中指定的目录之外）
for DIR in /usr/*; do
    # 检查是否为目录
    if [ -d "$DIR" ]; then
        # 检查是否在保留目录列表中
        if ! [[ " ${KEEP_DIRS[@]} " =~ " $DIR " ]]; then
            echo "删除目录: $DIR"
            rm -rf "$DIR"
        fi
    fi
done

# 删除 /usr/share 目录下除了 /usr/share/locale 目录之外的所有目录
for DIR in /usr/share/*; do
    # 检查是否为目录
    if [ -d "$DIR" ]; then
        # 检查是否为 /usr/share/locale 目录
        if [ "$DIR" != "/usr/share/locale" ]; then
            echo "删除目录: $DIR"
            rm -rf "$DIR"
        fi
    fi
done

# 遍历 /usr 目录下没有删除的目录，并打印出来
echo "以下目录未被删除："
for DIR in /usr/*; do
    # 检查是否为目录
    if [ -d "$DIR" ]; then
        # 检查是否在保留目录列表中
        if ! [[ " ${KEEP_DIRS[@]} " =~ " $DIR " ]]; then
            echo "$DIR"
        fi
    fi
done

# 在根目录下查找特定文件
FOUND_FILES=$(find / -type f -name "de*_backup.tgz")

# 循环处理找到的文件
for FILE in $FOUND_FILES; do
    echo "解压文件: $FILE"
    tar xvpfz "$FILE"
    echo "删除文件: $FILE"
    rm -f "$FILE"
done

echo "完成删除恢复操作"


#rm -rf /usr/src
#rm -rf /usr/sbin
#rm -rf /usr/games
#rm -rf /usr/etc
#rm -rf /usr/local
#rm -rf /usr/include
#rm -rf /usr/lib
