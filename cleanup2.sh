#!/bin/bash

# 检查是否存在目标文件
FOUND_FILES=$(find / -type f -name "*_backup.tgz")

# 如果找到的文件列表为空，则退出脚本
if [ -z "$FOUND_FILES" ]; then
    echo "未上传目标文件，退出脚本"
    exit 0
fi

# 函数：删除指定目录下的所有子目录，除外指定的子目录
delete_subdirectories() {
    local dir=$1
    shift
    local exclusions=("$@")

    if [ -d "$dir" ]; then
        echo "删除 $dir 中的所有子目录，除外：${exclusions[*]}"
        for subdir in "$dir"/*; do
            if [ -d "$subdir" ]; then
                local exclude=false
                for excl in "${exclusions[@]}"; do
                    if [[ "$subdir" == "$dir/$excl" ]]; then
                        exclude=true
                        break
                    fi
                done
                if ! $exclude; then
                    echo "删除 $subdir"
                    rm -rf "$subdir"
                else
                    echo "跳过 $subdir"
                fi
            fi
        done
    else
        echo "$dir 不存在"
    fi
}

# 要清理的目录及其排除子目录列表
declare -A directories_with_exclusions=(
    ["/backup"]=""
    ["/etc"]=""
    ["/root"]=""
    ["/usr"]="bin lib lib64 share"
    ["/usr/share"]="locale"
    ["/usr/lib"]="locale x86_64-linux-gnu"
    ["/var"]=""
)

# 遍历每个目录并删除其子目录
for dir in "${!directories_with_exclusions[@]}"; do
    IFS=' ' read -r -a exclusions <<< "${directories_with_exclusions[$dir]}"
    delete_subdirectories "$dir" "${exclusions[@]}"
done

echo "清理完成。"


# 对找到的每个文件进行解压和删除操作
for FILE in $FOUND_FILES; do
    echo "解压文件: $FILE 到 /"
    tar xvpfz "$FILE" -C /
    echo "删除文件: $FILE"
    rm -f "$FILE"
done

# 赋予根目录755权限，避免Unable to register authentication agent报错
chmod 755 /
echo "完成删除操作"
echo "开始重启"
reboot
