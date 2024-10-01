#!/bin/bash

# 检查是否以 root 用户运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 用户运行此脚本"
  exit 1
fi

# 安装 NTP
install_ntp() {
  if [ -f /etc/redhat-release ]; then
    # CentOS
    yum install -y ntp
  elif [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    apt update
    apt install -y ntp
  elif [ -f /etc/alpine-release ]; then
    # Alpine
    apk add --no-cache openntpd
  else
    echo "不支持的操作系统"
    exit 1
  fi
}

# 配置 NTP 服务器
configure_ntp() {
  echo "请选择时间同步服务器："
  echo "1) 国内 NTP 服务器"
  echo "2) 国外 NTP 服务器"
  read -p "请输入选项 (1 或 2): " option

  if [ "$option" -eq 1 ]; then
    # 国内 NTP 服务器
    ntp_servers="ntp1.aliyun.com ntp2.aliyun.com ntp3.aliyun.com"
  elif [ "$option" -eq 2 ]; then
    # 国外 NTP 服务器
    ntp_servers="pool.ntp.org"
  else
    echo "无效的选项"
    exit 1
  fi

  # 配置 NTP 服务器
  if [ -f /etc/ntp.conf ]; then
    echo "server $ntp_servers" >> /etc/ntp.conf
  elif [ -f /etc/openntpd/ntpd.conf ]; then
    echo "server $ntp_servers" >> /etc/openntpd/ntpd.conf
  else
    echo "无法找到 NTP 配置文件"
    exit 1
  fi
}

# 启动 NTP 服务
start_ntp() {
  if [ -f /etc/init.d/ntp ]; then
    systemctl enable ntp
    systemctl start ntp
  elif [ -f /usr/sbin/ntpd ]; then
    rc-update add openntpd
    service openntpd start
  else
    echo "无法启动 NTP 服务"
    exit 1
  fi
}

# 主程序
install_ntp
configure_ntp
start_ntp

echo "NTP 安装和配置完成！"
