#!/bin/bash

echo -e "\e[32m██████╗ ██╗   ██╗██████╗ ██╗   ██╗   ███╗   ██╗███████╗████████╗"
echo -e "██╔══██╗██║   ██║██╔══██╗██║   ██║   ████╗  ██║██╔════╝╚══██╔══╝"
echo -e "██████╔╝██║   ██║██████╔╝██║   ██║   ██╔██╗ ██║█████╗     ██║   "
echo -e "██╔══██╗██║   ██║██╔═══╝ ██║   ██║   ██║╚██╗██║██╔══╝     ██║   "
echo -e "██║  ██║╚██████╔╝██║     ╚██████╔╝██╗██║ ╚████║███████╗   ██║   "
echo -e "╚═╝  ╚═╝ ╚═════╝ ╚═╝      ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   \e[0m"

echo -e "\e[31m本脚本只可对Armbian主机进行初始化操作，其他主机系统可能不兼容！！！"
# 修改时区为东八区上海
sudo timedatectl set-timezone Asia/Shanghai
# 打印当前时间
echo -e "\e[96m当前时间：$(date)"

if [[ $(locale | grep LANG | cut -d= -f2) != "zh_CN.UTF-8" ]]; then
  # 修改系统语言为中文
  sudo sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
  sudo locale-gen zh_CN.UTF-8
  sudo update-locale LANG=zh_CN.UTF-8 LC_ALL=

  # 安装必要的软件包
  sudo apt install apt-transport-https ca-certificates

echo -e "\e[32m已更换为中文环境，即将重启，请稍后重新连接后再次执行代码。"
  sudo reboot
  exit
fi


if grep -qs "/dev/mmcblk" /etc/fstab; then
    echo -e "\e[32mTF卡已经挂载，跳过挂载步骤。"
else
    echo -e "\e[96mTF卡未挂载，执行挂载操作。"
    # 挂载 TF 卡的选择提示
    read -p $'\e[31m是否挂载TF卡？(Y/N，默认为N): \e[0m' choice
    choice=${choice^^} # 转换为大写字母
    
    if [ "$choice" == "Y" ]; then
        # 创建 TF 卡挂载目录
        sudo mkdir -p /mnt/tfcard
    
        # 挂载 mmcblk0p1 设备到 /mnt/tfcard
        sudo mount /dev/mmcblk0p1 /mnt/tfcard
    
        # 将挂载信息添加到 /etc/fstab
        echo "/dev/mmcblk0p1  /mnt/tfcard  auto  defaults  0  0" | sudo tee -a /etc/fstab
    
        # 重新加载挂载
        sudo mount -a
    
        echo -e "\e[32m已挂载TF卡到 /mnt/tfcard"
    fi
fi

# 更换 Armbian 的源为国内源
read -p $'\e[31m是否更换源为国内源？有条件“爬墙”则不建议换源(Y/N，默认为N): \e[0m' choice

choice=${choice^^} # 转换为大写字母

if [ "$choice" == "Y" ]; then
    sudo sed -i.bak 's#apt.armbian.com#mirrors.tuna.tsinghua.edu.cn/armbian#g' /etc/apt/sources.list.d/armbian.list
    sudo sed -i.bak 's#security.debian.org#mirrors.ustc.edu.cn/debian-security#g' /etc/apt/sources.list
    sudo sed -i.bak 's#deb.debian.org#mirrors.ustc.edu.cn#g' /etc/apt/sources.list
    sudo sed -i.bak 's#ports.ubuntu.com#mirrors.tuna.tsinghua.edu.cn/ubuntu-ports#g' /etc/apt/sources.list
    echo -e "\e[32m已更换源为国内源"
fi
# 更新软件包列表
sudo apt update

# 安装更新
sudo apt upgrade -y
/mnt/tfcard/backup/openwrt/create_backup_symlink.sh
/mnt/tfcard/backup/openwrt/install_docker.sh

# 安装系统的选择提示
read -p $'\e[31m请选择要安装的系统：
1. 安装CasaOS
2. 安装1Panel
3. 安装宝塔
0. 跳过
请输入选项(0): \e[0m' choice


if [ -z "$system_choice" ]; then
    system_choice=0
fi

case $system_choice in
    1)
        # 安装CasaOS
        curl -fsSL https://get.casaos.io | sudo bash
        ;;
    2)
        # 安装1Panel
        curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
        ;;
    3)
        # 安装宝塔
        wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && bash install.sh ed8484bec
        ;;
    *)
        # 跳过
        echo -e "\e[32m已跳过安装系统"
        ;;
esac
