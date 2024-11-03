#!/bin/bash

# 设置安装路径
INSTALL_DIR="/root/docker-compose/alist"

# 检查系统类型
check_system() {
    if [ -f /etc/debian_version ]; then
        SYSTEM="debian"
    elif [ -f /etc/redhat-release ]; then
        SYSTEM="centos"
    else
        echo "不支持的操作系统"
        exit 1
    fi
}

# 安装依赖
install_dependencies() {
    if [ "$SYSTEM" = "debian" ]; then
        apt update
        apt install -y wget tar
    elif [ "$SYSTEM" = "centos" ]; then
        yum install -y wget tar
    fi
}

# 下载并安装 AList
install_alist() {
    # 创建安装目录
    mkdir -p $INSTALL_DIR && cd $INSTALL_DIR

    # 获取 AList 最新版下载链接
    LATEST_URL=$(curl -s https://dl.sanguoguoguo.pp.ua/https://api.github.com/repos/AlistGo/alist/releases/latest | grep "browser_download_url.*alist-linux-amd64.tar.gz" | cut -d '"' -f 4)

    # 下载并解压
    wget -O alist-linux-amd64.tar.gz "$LATEST_URL"
    tar -zxvf alist-linux-amd64.tar.gz
    chmod +x alist

    # 配置 systemd 服务
    cat <<EOF >/usr/lib/systemd/system/alist.service
[Unit]
Description=alist
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/alist server
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载 systemd 配置并启动服务
    systemctl daemon-reload
    systemctl enable alist
    systemctl start alist

    # 随机生成并打印管理员密码
    RANDOM_PASS=$(./alist admin random)
    echo "安装完成，管理员密码为：$RANDOM_PASS"
    print_common_commands
}

# 更新 AList
update_alist() {
    # 停止现有服务
    systemctl stop alist

    # 下载并安装最新版
    install_alist

    echo "AList 已更新到最新版本。"
}

# 卸载 AList
uninstall_alist() {
    systemctl stop alist
    systemctl disable alist
    rm -rf $INSTALL_DIR
    rm -f /usr/lib/systemd/system/alist.service
    systemctl daemon-reload
    echo "AList 已卸载。"
}

# 打印常用管理命令
print_common_commands() {
    echo "常用管理命令："
    echo "启动: systemctl start alist"
    echo "关闭: systemctl stop alist"
    echo "重启: systemctl restart alist"
    echo "配置开机自启: systemctl enable alist"
    echo "取消开机自启: systemctl disable alist"
    echo "状态: systemctl status alist"
}

# 主菜单
main_menu() {
    echo "———————————————————————"
    echo "  1. 安装 AList"
    echo "  2. 更新 AList"
    echo "  3. 卸载 AList"
    echo "———————————————————————"
    read -p "请输入选项 [1-3]: " choice

    case $choice in
    1)
        check_system
        install_dependencies
        install_alist
        ;;
    2)
        check_system
        install_dependencies
        update_alist
        ;;
    3)
        uninstall_alist
        ;;
    *)
        echo "无效选项，请重新选择。"
        ;;
    esac
}

# 执行主菜单
main_menu
