#!/bin/bash

# 检测操作系统类型 (CentOS, Debian, Ubuntu)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unsupported OS"
    exit 1
fi

echo -e "install prebuilt nginx from package manager?[y/n]: \c"
read _INSTALL_FROM_PACKAGE

if [[ "y" == "${_INSTALL_FROM_PACKAGE}" ]]; then
    if [[ "$OS" == "centos" ]]; then
        # CentOS 安装
        yum -y install yum-utils
        touch /etc/yum.repos.d/nginx.repo
        echo '[nginx-stable]' >> /etc/yum.repos.d/nginx.repo
        echo 'name=nginx stable repo' >> /etc/yum.repos.d/nginx.repo
        echo 'baseurl=http://nginx.org/packages/centos/$releasever/$basearch/' >> /etc/yum.repos.d/nginx.repo
        echo 'gpgcheck=1' >> /etc/yum.repos.d/nginx.repo
        echo 'enabled=1' >> /etc/yum.repos.d/nginx.repo
        echo 'gpgkey=https://nginx.org/keys/nginx_signing.key' >> /etc/yum.repos.d/nginx.repo
        yum install nginx
    elif [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
        # Debian/Ubuntu 安装
        apt update
        apt install -y curl gnupg2 ca-certificates lsb-release
        echo "deb http://nginx.org/packages/$OS $(lsb_release -cs) nginx" \
            | tee /etc/apt/sources.list.d/nginx.list
        curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
        apt update
        apt install -y nginx
    else
        echo "Unsupported OS for package installation"
        exit 1
    fi
    exit
fi

echo -e "make nginx as a system service(register to systemctl)?[y/n]: \c"
read _AS_A_SYSTEM_SERVICE

echo -e "need update PCRE, ZLIB, OPENSSL packages by package manager?[y/n]: \c"
read _UPDATE_BY_PACKAGE_MANAGER

# 下载并解压 nginx 源码
wget https://nginx.org/download/nginx-1.14.2.tar.gz
tar zxf nginx-1.14.2.tar.gz
mv nginx-1.14.2 nginx-1.14.2-src
cd nginx-1.14.2-src/

# 安装依赖或编译相关库
if [[ "y" == "${_UPDATE_BY_PACKAGE_MANAGER}" ]]; then
    if [[ "$OS" == "centos" ]]; then
        yum -y install make gcc yum-utils pcre pcre-devel zlib zlib-devel openssl openssl-devel
    elif [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
        apt update
        apt install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
    fi
else
    # 自行编译安装 PCRE, Zlib, OpenSSL (可选)
    wget https://mirrors.aliyun.com/exim/pcre/pcre-8.42.tar.gz
    tar -zxf pcre-8.42.tar.gz
    cd pcre-8.42
    ./configure --prefix=/usr/local/pcre
    make
    make install
    cd ../

    wget https://zlib.net/fossils/zlib-1.2.11.tar.gz
    tar -zxf zlib-1.2.11.tar.gz
    cd zlib-1.2.11
    ./configure --prefix=/usr/local/zlib
    make
    make install
    cd ../

    wget http://www.openssl.org/source/openssl-1.1.1b.tar.gz
    tar -zxf openssl-1.1.1b.tar.gz
    mv openssl-1.1.1b openssl-1.1.1b-src
    mkdir openssl-1.1.1b
    cd openssl-1.1.1b-src
    ./Configure --prefix=/usr/local/openssl
    make
    make install
    cd ../
fi

# 配置编译 nginx
_BASE_DIR="$PWD"
_BASE_DIR="${_BASE_DIR:0:( ${#_BASE_DIR} - 4 )}"
# echo "BASE_DIR：$_BASE_DIR"
# exit 0

if [[ "y" == "${_UPDATE_BY_PACKAGE_MANAGER}" ]]; then
    ./configure \
    --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-http_v2_module \
    --with-threads
else
    ./configure \
    --prefix=/usr/local/nginx \
    --with-pcre=/usr/local/pcre \
    --with-zlib=/usr/local/zlib \
    --with-openssl=/usr/local/openssl \
    --with-http_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-http_v2_module \
    --with-threads
fi

make
make install

# 注册 Nginx 成为系统服务
if [[ "y" == "${_AS_A_SYSTEM_SERVICE}" ]]; then
    if [[ "$OS" == "centos" ]]; then
        SERVICE_PATH="/usr/lib/systemd/system/nginx.service"
    else
        SERVICE_PATH="/lib/systemd/system/nginx.service"
    fi

    touch $SERVICE_PATH

    echo "[Unit]" >> $SERVICE_PATH
    echo "Description=nginx - high performance web server" >> $SERVICE_PATH
    echo "Documentation=http://nginx.org/en/docs/" >> $SERVICE_PATH
    echo "After=network-online.target remote-fs.target nss-lookup.target" >> $SERVICE_PATH
    echo "Wants=network-online.target" >> $SERVICE_PATH
    echo "" >> $SERVICE_PATH

    echo "[Service]" >> $SERVICE_PATH
    echo "Type=forking" >> $SERVICE_PATH
    echo "PIDFile=${_BASE_DIR}/nginx.pid" >> $SERVICE_PATH
    echo "ExecStart=${_BASE_DIR}/sbin/nginx -c ${_BASE_DIR}/nginx.conf" >> $SERVICE_PATH
    echo "ExecReload=${_BASE_DIR}/sbin/nginx -s reload" >> $SERVICE_PATH
    echo "ExecStop=${_BASE_DIR}/sbin/nginx -s quit" >> $SERVICE_PATH
    echo "" >> $SERVICE_PATH

    echo "[Install]" >> $SERVICE_PATH
    echo "WantedBy=multi-user.target" >> $SERVICE_PATH

    systemctl daemon-reload
fi
