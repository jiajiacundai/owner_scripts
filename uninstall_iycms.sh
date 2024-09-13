#!/bin/bash
echo "开始卸载爱影CMS"

# 停止并禁用系统服务
echo "停止iycms服务"
systemctl stop iycms
systemctl disable iycms

# 删除系统服务配置文件
echo "删除iycms服务配置"
rm -f /etc/systemd/system/iycms.service

# 重新加载 systemd
echo "重新加载 systemd 守护进程"
systemctl daemon-reload

# 删除日志配置和文件
echo "删除iycms日志配置和日志文件"
rm -f /etc/rsyslog.d/iycms.conf
rm -f /home/iycms/stdout.log

# 重启 rsyslog 服务
echo "重启 rsyslog"
systemctl restart rsyslog

# 删除爱影CMS安装目录
echo "删除爱影CMS安装目录"
rm -rf /home/iycms

# 恢复防火墙服务（如果需要）
# echo "启动防火墙服务"
# systemctl enable firewalld
# systemctl start firewalld

echo "爱影CMS卸载完成"
