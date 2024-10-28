#!/bin/bash

# 检测是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 权限运行此脚本"
    exit 1
fi

# 更新并安装依赖项
install_dependencies() {
    echo "正在更新系统并安装必要的依赖项..."
    if command -v apt > /dev/null 2>&1; then
        apt update && apt install -y wget curl vim ca-certificates
    elif command -v yum > /dev/null 2>&1; then
        yum update -y && yum install -y wget curl vim ca-certificates
    else
        echo "不支持的系统，请使用 Debian、Ubuntu 或 CentOS"
        exit 1
    fi
}

# 下载并设置 Cloudreve
install_cloudreve() {
    echo "正在安装 Cloudreve..."

    # 创建安装目录
    mkdir -p /root/docker-compose/cloudreve

    # 下载 Cloudreve 最新版本
    latest_version=$(curl -s https://api.github.com/repos/cloudreve/Cloudreve/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    wget -O cloudreve.tar.gz https://github.com/cloudreve/Cloudreve/releases/download/"$latest_version"/cloudreve_"$latest_version"_linux_amd64.tar.gz
    tar -zxvf cloudreve.tar.gz -C /root/docker-compose/cloudreve
    chmod +x /root/docker-compose/cloudreve/cloudreve
    rm -f cloudreve.tar.gz

    # 创建 systemd 服务文件
    echo "创建 Cloudreve 服务文件..."
    cat <<EOF > /usr/lib/systemd/system/cloudreve.service
[Unit]
Description=Cloudreve
Documentation=https://docs.cloudreve.org
After=network.target
Wants=network.target

[Service]
WorkingDirectory=/root/docker-compose/cloudreve
ExecStart=/root/docker-compose/cloudreve/cloudreve
Restart=on-abnormal
RestartSec=5s
KillMode=mixed

StandardOutput=null
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF

    # 加载并启动服务
    systemctl daemon-reload
    systemctl start cloudreve
    systemctl enable cloudreve
    echo "Cloudreve 安装并启动完成！"
}

# 显示管理员账号和密码
show_admin_credentials() {
    echo "等待 Cloudreve 日志生成管理员账号和密码..."
    sleep 5  # 等待几秒以确保日志文件已创建

    # 查找 Cloudreve 日志文件中生成的管理员信息
    log_file="/root/docker-compose/cloudreve/cloudreve.log"
    if [[ -f "$log_file" ]]; then
        admin_info=$(grep -E "默认管理账号|账号" "$log_file" | head -n 2)
        echo "默认管理员账号和密码："
        echo "$admin_info"
    else
        echo "无法找到 Cloudreve 日志文件。请手动检查日志以获取账号信息。"
    fi
}

# 安装 Aria2
install_aria2() {
    echo "正在安装 Aria2..."
    wget -N git.io/aria2.sh && chmod +x aria2.sh
    ./aria2.sh
    echo "Aria2 安装完成！"
}

# 主安装流程
main() {
    install_dependencies
    install_cloudreve

    read -p "是否安装 Aria2? (y/n): " install_aria2_choice
    if [[ "$install_aria2_choice" =~ ^[Yy]$ ]]; then
        install_aria2
    else
        echo "跳过 Aria2 安装。"
    fi

    # 显示管理员账号和密码
    show_admin_credentials
}

main
