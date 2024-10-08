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

# 检查系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    echo "操作系统不受支持"
    exit 1
fi

# 根据系统类型安装依赖包
if [[ "$OS" == "centos" ]]; then
    yum install -y gcc gcc-c++ make wget zlib-devel pcre-devel openssl-devel libxslt-devel gd-devel geoip-devel perl-ExtUtils-Embed git
elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt update
    apt install -y build-essential wget zlib1g-dev libpcre3 libpcre3-dev openssl libssl-dev libxslt1-dev libgd-dev libgeoip-dev perl git
else
    echo "操作系统不受支持"
    exit 1
fi

# 提示用户是否安装 LuaJIT
read -p "是否安装 LuaJIT (y/n)? " install_luajit

if [[ "$install_luajit" == "y" || "$install_luajit" == "Y" ]]; then
    # 下载并安装 LuaJIT
    cd /usr/local/src
    wget --no-check-certificate https://www.isres.com/file/LuaJIT-${LUAJIT_VERSION}.tar.gz
    tar zxvf LuaJIT-${LUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LUAJIT_VERSION}
    make && make install
    cd ..
    
    # 设置 LuaJIT 环境变量
    export LUAJIT_LIB=/usr/local/lib
    export LUAJIT_INC=/usr/local/include/luajit-2.1/
    export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH

    # 克隆 lua-nginx-module 模块
    mkdir -p ${Setup_Path}/src
    cd ${Setup_Path}/src
    git clone https://github.com/openresty/lua-nginx-module.git
fi

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

# 配置 Nginx 编译选项
cd nginx-${NGINX_VERSION}
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

# 如果选择安装 LuaJIT，添加 lua-nginx-module 模块
if [[ "$install_luajit" == "y" || "$install_luajit" == "Y" ]]; then
    ./configure --add-module=${Setup_Path}/src/lua-nginx-module
fi

# 编译并安装 Nginx
make -j${cpuCore}
make install

# 刷新 Nginx 环境变量
echo 'export PATH=$PATH:/usr/local/nginx/sbin' | tee -a /etc/profile
source /etc/profile

# 集中删除所有安装包和源码目录
# cd /usr/local/src
# rm -rf LuaJIT-${LUAJIT_VERSION}.tar.gz LuaJIT-${LUAJIT_VERSION} \
#     pcre-${pcre_version}.tar.gz pcre-${pcre_version} \
#     openssl-${OPENSSL_VERSION}.tar.gz openssl-${OPENSSL_VERSION} \
#     nginx-${NGINX_VERSION}.tar.gz nginx-${NGINX_VERSION}
    
# 注册 Nginx 成为系统服务
_AS_A_SYSTEM_SERVICE="y"
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
    echo "PIDFile=${Setup_Path}/logs/nginx.pid" >> $SERVICE_PATH
    echo "ExecStart=${Setup_Path}/sbin/nginx -c ${Setup_Path}/conf/nginx.conf" >> $SERVICE_PATH
    echo "ExecReload=${Setup_Path}/sbin/nginx -s reload" >> $SERVICE_PATH
    echo "ExecStop=${Setup_Path}/sbin/nginx -s quit" >> $SERVICE_PATH
    echo "" >> $SERVICE_PATH

    echo "[Install]" >> $SERVICE_PATH
    echo "WantedBy=multi-user.target" >> $SERVICE_PATH

    systemctl daemon-reload
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    sudo systemctl status nginx

fi

echo "请手动以下命令刷新nginx环境变量，前三条是安装LuaJIT后一键执行，最后一条必须执行"
echo "export LUAJIT_LIB=/usr/local/lib"
echo "export LUAJIT_INC=/usr/local/include/luajit-2.1/"
echo "export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH"
echo "source /etc/profile"
echo "Nginx ${NGINX_VERSION} 安装完成并已启动！"
