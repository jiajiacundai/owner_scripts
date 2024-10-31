#!/bin/bash

# 适合debian/ubuntu，centos7系统
# 检查是否是root用户
if [ "$EUID" -ne 0 ]; then
    echo "请使用root权限运行该脚本."
    exit 1
fi

# 获取操作系统类型
if [ -f /etc/centos-release ]; then
    OS="centos"
elif [ -f /etc/debian_version ]; then
    OS="debian"
else
    echo "不支持的操作系统类型."
    exit 1
fi

# 安装必要的依赖
install_dependencies() {
    if [ "$OS" == "centos" ]; then
        yum install -y curl unzip
    elif [ "$OS" == "debian" ]; then
        apt update && apt install -y curl unzip
    fi
}

# 功能菜单
echo "请选择操作："
echo "1. 安装 rclone"
echo "2. 卸载 rclone"
read -p "输入数字选择操作 (1 或 2): " action

install_rclone() {
    echo "正在安装 rclone..."
    install_dependencies  # 确保依赖项已安装
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
    unzip rclone-current-linux-amd64.zip
    cd rclone-*-linux-amd64
    cp rclone /usr/local/bin/
    chmod 755 /usr/local/bin/rclone
    mkdir -p /usr/local/share/man/man1
    cp rclone.1 /usr/local/share/man/man1/
    mandb
    cd ..
    rm -rf rclone-*-linux-amd64 rclone-current-linux-amd64.zip
    echo "rclone 安装完成."
}

uninstall_rclone() {
    echo "正在卸载 rclone..."
    rm -f /usr/local/bin/rclone
    rm -f /usr/local/share/man/man1/rclone.1
    mandb
    echo "rclone 卸载完成."
}

# 根据用户选择执行安装或卸载操作
if [ "$action" -eq 1 ]; then
    install_rclone
elif [ "$action" -eq 2 ]; then
    uninstall_rclone
else
    echo "无效的选择."
    exit 1
fi
