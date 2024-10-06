#!/bin/bash

# 检测操作系统类型 (CentOS, Debian, Ubuntu)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unsupported OS"
    exit 1
fi

# 函数：安装预构建的Nginx包
install_nginx_package() {
    if [[ "$OS" == "centos" ]]; then
        # CentOS 安装
        yum -y install yum-utils
        cat <<EOF > /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF
        yum -y install nginx
    elif [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
        # Debian/Ubuntu 安装
        apt update
        apt install -y curl gnupg2 ca-certificates lsb-release
        echo "deb http://nginx.org/packages/$OS $(lsb_release -cs) nginx" \
            | tee /etc/apt/sources.list.d/nginx.list
        curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
        apt update
        apt -y install nginx
    else
        echo "Unsupported OS for package installation"
        exit 1
    fi
}

# 函数：编译和安装依赖库
compile_dependencies() {
    wget https://mirrors.aliyun.com/exim/pcre/pcre-8.42.tar.gz
    tar -zxf pcre-8.42.tar.gz
    cd pcre-8.42
    ./configure && make && make install
    cd ..

    wget https://zlib.net/fossils/zlib-1.2.11.tar.gz
    tar -zxf zlib-1.2.11.tar.gz
    cd zlib-1.2.11
    ./configure && make && make install
    cd ..

    wget https://www.openssl.org/source/openssl-1.1.1b.tar.gz
    tar -zxf openssl-1.1.1b.tar.gz
    mv openssl-1.1.1b openssl-1.1.1b-src
    cd openssl-1.1.1b-src
    ./Configure linux-x86_64 --prefix=$PWD
    make && make install
    cd ..
}

# 函数：编译安装 Nginx
compile_nginx() {
    ./configure \
        --prefix="$1" \
        --with-http_ssl_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-http_v2_module \
        --with-threads
    make && make install
}

# 函数：配置 Nginx 成为系统服务
setup_system_service() {
    SERVICE_PATH="/lib/systemd/system/nginx.service"
    if [[ "$OS" == "centos" ]]; then
        SERVICE_PATH="/usr/lib/systemd/system/nginx.service"
    fi

    cat <<EOF > $SERVICE_PATH
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=$1/nginx.pid
ExecStart=$1/sbin/nginx -c $1/nginx.conf
ExecReload=$1/sbin/nginx -s reload
ExecStop=$1/sbin/nginx -s quit

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
}

# 主流程
echo -e "Install prebuilt nginx from package manager? [y/n]: \c"
read _INSTALL_FROM_PACKAGE

if [[ "$_INSTALL_FROM_PACKAGE" == "y" ]]; then
    install_nginx_package
    exit
fi

echo -e "Make nginx as a system service (register to systemctl)? [y/n]: \c"
read _AS_A_SYSTEM_SERVICE

echo -e "Need update PCRE, ZLIB, OPENSSL packages by package manager? [y/n]: \c"
read _UPDATE_BY_PACKAGE_MANAGER

# 下载并解压 nginx 源码
wget https://nginx.org/download/nginx-1.14.2.tar.gz
tar zxf nginx-1.14.2.tar.gz
mv nginx-1.14.2 nginx-1.14.2-src
cd nginx-1.14.2-src/

# 安装依赖
if [[ "$_UPDATE_BY_PACKAGE_MANAGER" == "y" ]]; then
    if [[ "$OS" == "centos" ]]; then
        yum -y install make gcc yum-utils pcre pcre-devel zlib zlib-devel openssl openssl-devel
    elif [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
        apt update
        apt install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
    fi
else
    compile_dependencies
fi

# 配置并编译 nginx
_BASE_DIR=$(pwd)
compile_nginx "$_BASE_DIR"

# 注册 Nginx 为系统服务
if [[ "$_AS_A_SYSTEM_SERVICE" == "y" ]]; then
    setup_system_service "$_BASE_DIR"
fi
