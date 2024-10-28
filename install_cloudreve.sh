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

    # 初次运行并生成日志
    echo "首次运行 Cloudreve 以生成初始管理员账号信息..."
    /root/docker-compose/cloudreve/cloudreve > /root/docker-compose/cloudreve/cloudreve.log 2>&1 &
    sleep 5  # 等待 Cloudreve 完成启动并生成日志
    pkill -f "/root/docker-compose/cloudreve/cloudreve"  # 中断 Cloudreve 进程

    # 从日志中提取管理员账号和密码
    admin_user=$(grep -oP 'Admin user name: \K\S+' /root/docker-compose/cloudreve/cloudreve.log)
    admin_password=$(grep -oP 'Admin password: \K\S+' /root/docker-compose/cloudreve/cloudreve.log)
    echo "管理员账号: $admin_user"
    echo "管理员密码: $admin_password"

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
ExecStart=/root/docker-compose/cloudreve/cloudreve > /root/docker-compose/cloudreve/cloudreve.log 2>&1
Restart=on-abnormal
RestartSec=5s
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

    # 加载并启动服务
    systemctl daemon-reload
    systemctl start cloudreve
    systemctl enable cloudreve
    echo "Cloudreve 安装并启动完成！"
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
}

main
