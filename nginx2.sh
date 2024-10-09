#!/bin/bash

# 设置变量
LUAJIT_VERSION="2.1.0-beta3"
INSTALL_DIR="/usr/local/LuaJIT"

# 确保脚本以 root 权限运行
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# 创建安装目录
mkdir -p $INSTALL_DIR

# 下载和解压 LuaJIT
cd /usr/local/src
wget --no-check-certificate https://www.isres.com/file/LuaJIT-${LUAJIT_VERSION}.tar.gz
tar zxvf LuaJIT-${LUAJIT_VERSION}.tar.gz
cd LuaJIT-${LUAJIT_VERSION}

# 编译和安装 LuaJIT
make && make install PREFIX=$INSTALL_DIR

# 设置 LuaJIT 环境变量
echo "export LUAJIT_LIB=$INSTALL_DIR/lib" >> /etc/profile
echo "export LUAJIT_INC=$INSTALL_DIR/include/luajit-2.1" >> /etc/profile

# 创建符号链接
ln -sf $INSTALL_DIR/bin/luajit-${LUAJIT_VERSION} $INSTALL_DIR/bin/luajit

# 刷新环境变量
source /etc/profile

echo "LuaJIT ${LUAJIT_VERSION} has been successfully installed to $INSTALL_DIR"
echo "Please run 'source /etc/profile' or log out and log back in to apply the changes to your current session."
