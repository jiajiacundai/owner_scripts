#!/bin/bash

# 定义变量
Setup_Path="/usr/local/nginx"
cpuCore=$(nproc)
pcre_version="8.42"
LUAJIT_VERSION="2.1.0-beta3"
OPENSSL_VERSION="1.1.1w"
NGINX_VERSION="1.24.0"
NGX_CACHE_PURGE_VERSION="2.3"
SUBSTITUTIONS_FILTER_MODULE="ngx_http_substitutions_filter_module"

# 安装依赖包
yum install -y gcc gcc-c++ make wget zlib-devel pcre-devel openssl-devel libxslt-devel gd-devel geoip-devel perl-ExtUtils-Embed git

# 下载并安装 LuaJIT
cd /usr/local/src
wget --no-check-certificate https://www.isres.com/file/LuaJIT-${LUAJIT_VERSION}.tar.gz
tar zxvf LuaJIT-${LUAJIT_VERSION}.tar.gz
cd LuaJIT-${LUAJIT_VERSION}
make && make install

# 设置 LuaJIT 环境变量
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1/
export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH

# 下载并安装 PCRE
cd /usr/local/src
wget --no-check-certificate https://mirrors.aliyun.com/exim/pcre/pcre-${pcre_version}.tar.gz
tar zxvf pcre-${pcre_version}.tar.gz

# 下载并安装 OpenSSL
cd /usr/local/src
wget --no-check-certificate https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
tar zxvf openssl-${OPENSSL_VERSION}.tar.gz

# 克隆 ngx_cache_purge 模块
mkdir -p ${Setup_Path}/src
cd ${Setup_Path}/src
git clone https://github.com/FRiCKLE/ngx_cache_purge.git

# 克隆 ngx_http_substitutions_filter_module 模块
git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

# 下载 Nginx 源码
cd /usr/local/src
wget --no-check-certificate http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar zxvf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}

# 配置 Nginx 编译选项
./configure --prefix=${Setup_Path} \
--add-module=${Setup_Path}/src/ngx_cache_purge \
--with-openssl=/usr/local/src/openssl-${OPENSSL_VERSION} \
--with-pcre=/usr/local/src/pcre-${pcre_version} \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_image_filter_module \
--with-http_gzip_static_module \
--with-http_gunzip_module \
--with-http_sub_module \
--with-http_flv_module \
--with-http_addition_module \
--with-http_realip_module \
--with-http_mp4_module \
--with-http_auth_request_module \
--add-module=${Setup_Path}/src/ngx_http_substitutions_filter_module \
--with-ld-opt="-Wl,-E" \
--with-cc-opt="-Wno-error"

# 编译并安装 Nginx
make -j${cpuCore}
make install

# 启动 Nginx
${Setup_Path}/sbin/nginx

# 设置开机启动
echo "${Setup_Path}/sbin/nginx" >> /etc/rc.local
chmod +x /etc/rc.local

echo "Nginx ${NGINX_VERSION} 安装完成并已启动！"