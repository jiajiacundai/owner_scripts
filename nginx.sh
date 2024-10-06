#!/bin/bash

# 参考 https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/

echo -e "Install prebuilt nginx from apt?[y/n]: \c"

read _INSTALL_FROM_APT

if [[ "y" == "${_INSTALL_FROM_APT}" ]]; then
    # Update apt and install prerequisites
    sudo apt update
    sudo apt -y install curl gnupg2 ca-certificates lsb-release

    # Add NGINX repository
    echo "deb http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
    curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

    # Install NGINX
    sudo apt update
    sudo apt -y install nginx

    exit
fi

echo -e "Make nginx a system service (register to systemctl)?[y/n]: \c"

read _AS_A_SYSTEM_SERVICE

echo -e "Need to update PCRE, ZLIB, OPENSSL packages by apt?[y/n]: \c"

read _UPDATE_BY_APT_FLAG

wget https://nginx.org/download/nginx-1.14.2.tar.gz

tar zxf nginx-1.14.2.tar.gz

mv nginx-1.14.2 nginx-1.14.2-src

cd nginx-1.14.2-src/

# ======================== 可选, 如果系统已有则不必安装 ========================

if [[ "y" == "${_UPDATE_BY_APT_FLAG}" ]];then
    sudo apt -y install build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
else
    # To install PCRE – Supports regular expressions. Required by the NGINX Core and Rewrite modules.
    wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.42.tar.gz
    tar -zxf pcre-8.42.tar.gz
    cd pcre-8.42
    ./configure
    make
    sudo make install
    cd ../

    # To install zlib – Supports header compression. Required by the NGINX Gzip module.
    wget http://zlib.net/zlib-1.2.11.tar.gz
    tar -zxf zlib-1.2.11.tar.gz
    cd zlib-1.2.11
    ./configure
    make
    sudo make install
    cd ../

    # To install OpenSSL – Supports the HTTPS protocol. Required by the NGINX SSL module and others.
    wget http://www.openssl.org/source/openssl-1.1.1b.tar.gz
    tar -zxf openssl-1.1.1b.tar.gz
    mv openssl-1.1.1b openssl-1.1.1b-src
    mkdir openssl-1.1.1b
    cd openssl-1.1.1b-src
    ./Configure linux-x86_64 --prefix=$PWD
    make
    sudo make install
    cd ../
fi

mkdir ../nginx-1.14.2/

_BASE_DIR="$PWD"

_BASE_DIR="${_BASE_DIR:0:( ${#_BASE_DIR} - 4 )}"

if [[ "y" == "${_UPDATE_BY_APT_FLAG}" ]]; then
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
    --with-openssl=$PWD/openssl-1.1.1b-src \
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

sudo make install

if [[ "y" == "${_AS_A_SYSTEM_SERVICE}" ]]; then
    sudo touch /lib/systemd/system/nginx.service

    echo "[Unit]" | sudo tee /lib/systemd/system/nginx.service
    echo "Description=nginx - high performance web server" | sudo tee -a /lib/systemd/system/nginx.service
    echo "Documentation=http://nginx.org/en/docs/" | sudo tee -a /lib/systemd/system/nginx.service
    echo "After=network-online.target remote-fs.target nss-lookup.target" | sudo tee -a /lib/systemd/system/nginx.service
    echo "Wants=network-online.target" | sudo tee -a /lib/systemd/system/nginx.service
    echo "" | sudo tee -a /lib/systemd/system/nginx.service

    echo "[Service]" | sudo tee -a /lib/systemd/system/nginx.service
    echo "Type=forking" | sudo tee -a /lib/systemd/system/nginx.service
    echo "PIDFile=${_BASE_DIR}/nginx.pid" | sudo tee -a /lib/systemd/system/nginx.service
    echo "ExecStart=${_BASE_DIR}/sbin/nginx -c ${_BASE_DIR}/nginx.conf" | sudo tee -a /lib/systemd/system/nginx.service
    echo "ExecReload=${_BASE_DIR}/sbin/nginx -s reload" | sudo tee -a /lib/systemd/system/nginx.service
    echo "ExecStop=${_BASE_DIR}/sbin/nginx -s quit" | sudo tee -a /lib/systemd/system/nginx.service
    echo "" | sudo tee -a /lib/systemd/system/nginx.service

    echo "[Install]" | sudo tee -a /lib/systemd/system/nginx.service
    echo "WantedBy=multi-user.target" | sudo tee -a /lib/systemd/system/nginx.service
    sudo systemctl daemon-reload
fi
