#!/bin/bash

# 检测操作系统
if [ -f /etc/centos-release ]; then
    OS="centos"
elif [ -f /etc/debian_version ]; then
    OS="debian"
else
    echo "Unsupported OS"
    exit 1
fi

echo -e "install prebuilt nginx from package manager?[y/n]: \c"
read _INSTALL_FROM_PACKAGE_MANAGER

if [[ "y" == "${_INSTALL_FROM_PACKAGE_MANAGER}" ]]; then

    if [[ "${OS}" == "centos" ]]; then
        # CentOS - Install prebuilt Nginx via yum
        yum -y install yum-utils

        # Create /etc/yum.repos.d/nginx.repo
        cat <<EOL > /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
EOL

        yum install -y nginx

    elif [[ "${OS}" == "debian" ]]; then
        # Debian/Ubuntu - Install prebuilt Nginx via apt
        apt update
        apt install -y gnupg2 ca-certificates lsb-release wget

        wget http://nginx.org/keys/nginx_signing.key
        apt-key add nginx_signing.key

        # Create /etc/apt/sources.list.d/nginx.list
        cat <<EOL > /etc/apt/sources.list.d/nginx.list
deb http://nginx.org/packages/debian/ `lsb_release -cs` nginx
deb-src http://nginx.org/packages/debian/ `lsb_release -cs` nginx
EOL

        apt update
        apt install -y nginx
    fi

    exit
fi

echo -e "make nginx as a system service(register to systemctl)?[y/n]: \c"
read _AS_A_SYSTEM_SERVICE

echo -e "need update PCRE, ZLIB, OPENSSL packages by package manager?[y/n]: \c"
read _UPDATE_BY_PACKAGE_MANAGER

wget https://nginx.org/download/nginx-1.14.2.tar.gz
tar zxf nginx-1.14.2.tar.gz
mv nginx-1.14.2 nginx-1.14.2-src
cd nginx-1.14.2-src/

# ======================== 可选, 如果系统已有则不必安装 ========================
if [[ "y" == "${_UPDATE_BY_PACKAGE_MANAGER}" ]]; then
    if [[ "${OS}" == "centos" ]]; then
        yum -y install make gcc yum-utils pcre pcre-devel zlib zlib-devel openssl openssl-devel
    elif [[ "${OS}" == "debian" ]]; then
        apt update
        apt install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev
    fi
else
    # Manually compile and install PCRE, Zlib, and OpenSSL
    wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.42.tar.gz
    tar -zxf pcre-8.42.tar.gz
    cd pcre-8.42
    ./configure
    make
    make install
    cd ../

    wget http://zlib.net/zlib-1.2.11.tar.gz
    tar -zxf zlib-1.2.11.tar.gz
    cd zlib-1.2.11
    ./configure
    make
    make install
    cd ../

    wget http://www.openssl.org/source/openssl-1.1.1b.tar.gz
    tar -zxf openssl-1.1.1b.tar.gz
    cd openssl-1.1.1b
    ./Configure linux-x86_64 --prefix=$PWD
    make
    make install
    cd ../
fi

mkdir ../nginx-1.14.2/
_BASE_DIR="$PWD"
_BASE_DIR="${_BASE_DIR:0:( ${#_BASE_DIR} - 4 )}"

if [[ "y" == "${_UPDATE_BY_PACKAGE_MANAGER}" ]]; then
    ./configure \
    --prefix=${_BASE_DIR} \
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
    --prefix=${_BASE_DIR} \
    --with-pcre=$PWD/pcre-8.42 \
    --with-zlib=$PWD/zlib-1.2.11 \
    --with-openssl=$PWD/openssl-1.1.1b \
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

if [[ "y" == "${_AS_A_SYSTEM_SERVICE}" ]]; then

    if [[ "${OS}" == "centos" ]]; then
        SERVICE_PATH="/usr/lib/systemd/system/nginx.service"
    elif [[ "${OS}" == "debian" ]]; then
        SERVICE_PATH="/lib/systemd/system/nginx.service"
    fi

    cat <<EOL > ${SERVICE_PATH}
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=${_BASE_DIR}/nginx.pid
ExecStart=${_BASE_DIR}/sbin/nginx -c ${_BASE_DIR}/nginx.conf
ExecReload=${_BASE_DIR}/sbin/nginx -s reload
ExecStop=${_BASE_DIR}/sbin/nginx -s quit

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
fi
