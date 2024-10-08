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
mkdir -p /www/my-nginx && chmod -R 777 /www/ && cd /www/
wget --no-check-certificate https://nginx.org/download/nginx-1.24.0.tar.gz
tar zxf nginx-1.24.0.tar.gz
mv nginx-1.24.0 nginx-1.24.0-src
cd nginx-1.24.0-src

# 安装依赖或编译相关库
if [[ "y" == "${_UPDATE_BY_PACKAGE_MANAGER}" ]]; then
    if [[ "$OS" == "centos" ]]; then
        yum update
        yum -y install git make gcc sudo yum-utils pcre pcre-devel zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libxslt libxslt-devel
    elif [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
        apt update
        apt install -y git sudo build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
    fi
else
    mkdir -p /www/my-nginx/dependence && cd /www/my-nginx/dependence
    yum -y install git make gcc sudo libxml2 libxml2-devel libxslt libxslt-devel
    # 自行编译安装 PCRE, Zlib, OpenSSL (可选)
    wget --no-check-certificate https://mirrors.aliyun.com/exim/pcre/pcre-8.42.tar.gz
    tar -zxf pcre-8.42.tar.gz
    cd pcre-8.42
    mkdir pcre
    ./configure --prefix=$PWD/pcre
    make
    make install
    cd ..

    wget --no-check-certificate https://zlib.net/fossils/zlib-1.2.11.tar.gz
    tar -zxf zlib-1.2.11.tar.gz
    cd zlib-1.2.11
    mkdir zlib
    ./configure --prefix=$PWD/zlib
    make
    make install
    cd ..

    wget --no-check-certificate http://www.openssl.org/source/openssl-1.1.1b.tar.gz
    tar -zxf openssl-1.1.1b.tar.gz
    mv openssl-1.1.1b openssl-1.1.1b-src
    cd openssl-1.1.1b-src
    mkdir openssl
    ./Configure linux-x86_64 --prefix=$PWD/openssl
    make
    make install
    cd /www/nginx-1.24.0-src
fi

# 安装nginx模块
mkdir -p /www/my-nginx/src && cd /www/my-nginx/src
git clone https://github.com/vision5/ngx_devel_kit.git
# git clone https://github.com/openresty/lua-nginx-module.git
git clone https://github.com/FRiCKLE/ngx_cache_purge.git
git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
git clone https://github.com/arut/nginx-dav-ext-module.git
cd /www/nginx-1.24.0-src

# 配置编译 nginx
_BASE_DIR="/www/my-nginx"

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
    --with-threads \
    --add-module=/www/my-nginx/src/ngx_devel_kit \
    --add-module=/www/my-nginx/src/ngx_cache_purge \
    --add-module=/www/my-nginx/src/ngx_http_substitutions_filter_module \
    --add-module=/www/my-nginx/src/nginx-dav-ext-module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module \
    --with-http_gunzip_module \
    --with-http_sub_module \
    --with-http_flv_module \
    --with-http_addition_module \
    --with-http_realip_module \
    --with-http_mp4_module \
    --with-stream_ssl_preread_module \
    --with-http_dav_module \
    --with-ld-opt="-Wl,-E" \
    --with-cc-opt="-Wno-error"
else
    ./configure \
    --prefix=${_BASE_DIR} \
    --with-pcre=/www/my-nginx/dependence/pcre-8.42 \
    --with-zlib=/www/my-nginx/dependence/zlib-1.2.11 \
    --with-openssl=/www/my-nginx/dependence/openssl-1.1.1b-src \
    --with-http_ssl_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-http_v2_module \
    --with-threads \
    --add-module=/www/my-nginx/src/ngx_devel_kit \
    --add-module=/www/my-nginx/src/ngx_cache_purge \
    --add-module=/www/my-nginx/src/ngx_http_substitutions_filter_module \
    --add-module=/www/my-nginx/src/nginx-dav-ext-module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module \
    --with-http_gunzip_module \
    --with-http_sub_module \
    --with-http_flv_module \
    --with-http_addition_module \
    --with-http_realip_module \
    --with-http_mp4_module \
    --with-stream_ssl_preread_module \
    --with-http_dav_module \
    --with-ld-opt="-Wl,-E" \
    --with-cc-opt="-Wno-error"

fi

make
make install
echo 'export PATH=$PATH:/www/my-nginx/sbin' | tee -a /etc/profile
source /etc/profile

# 注册 Nginx 成为系统服务
if [[ "y" == "${_AS_A_SYSTEM_SERVICE}" ]]; then
    if [[ "$OS" == "centos" ]]; then
        SERVICE_PATH="/usr/lib/systemd/system/nginx.service"
    else
        SERVICE_PATH="/lib/systemd/system/nginx.service"
    fi

    touch $SERVICE_PATH

    echo "[Unit]" > $SERVICE_PATH
    echo "Description=nginx - high performance web server" >> $SERVICE_PATH
    echo "Documentation=http://nginx.org/en/docs/" >> $SERVICE_PATH
    echo "After=network-online.target remote-fs.target nss-lookup.target" >> $SERVICE_PATH
    echo "Wants=network-online.target" >> $SERVICE_PATH
    echo "" >> $SERVICE_PATH

    echo "[Service]" >> $SERVICE_PATH
    echo "Type=forking" >> $SERVICE_PATH
    echo "PIDFile=${_BASE_DIR}/logs/nginx.pid" >> $SERVICE_PATH
    echo "ExecStart=${_BASE_DIR}/sbin/nginx -c ${_BASE_DIR}/conf/nginx.conf" >> $SERVICE_PATH
    echo "ExecReload=${_BASE_DIR}/sbin/nginx -s reload" >> $SERVICE_PATH
    echo "ExecStop=${_BASE_DIR}/sbin/nginx -s quit" >> $SERVICE_PATH
    echo "" >> $SERVICE_PATH

    echo "[Install]" >> $SERVICE_PATH
    echo "WantedBy=multi-user.target" >> $SERVICE_PATH

    systemctl daemon-reload
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    sudo systemctl status nginx

fi
