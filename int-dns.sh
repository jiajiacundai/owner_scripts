#!/bin/bash
# 自动配置 DNS 脚本
# 支持 Debian/Ubuntu、CentOS/RHEL、Rocky/Alma、openSUSE、Alpine
# DNS 设置为 Cloudflare + Google IPv6

DNS_CONFIG="nameserver 2606:4700:4700::1111
nameserver 2001:4860:4860::8888
nameserver 1.1.1.1
nameserver 1.0.0.1"

backup_resolv() {
    if [ -f /etc/resolv.conf ]; then
        cp -a /etc/resolv.conf /etc/resolv.conf.bak.$(date +%s)
    fi
}

apply_dns_resolvconf() {
    echo "配置 resolvconf..."
    echo "$DNS_CONFIG" > /etc/resolvconf/resolv.conf.d/head
    resolvconf -u
}

apply_dns_netplan() {
    echo "配置 netplan..."
    NETPLAN_FILE=$(find /etc/netplan -type f -name "*.yaml" | head -n 1)
    if [ -n "$NETPLAN_FILE" ]; then
        cp -a "$NETPLAN_FILE" "$NETPLAN_FILE.bak.$(date +%s)"
        sed -i '/nameservers:/,/^[^ ]/d' "$NETPLAN_FILE"
        cat >> "$NETPLAN_FILE" <<EOF
        nameservers:
            addresses:
                - 2606:4700:4700::1111
                - 2001:4860:4860::8888
                - 1.1.1.1
                - 1.0.0.1
EOF
        netplan apply
    fi
}

apply_dns_networkmanager() {
    echo "配置 NetworkManager..."
    mkdir -p /etc/NetworkManager/conf.d
    cat > /etc/NetworkManager/conf.d/dns.conf <<EOF
[main]
dns=none
EOF
    echo "$DNS_CONFIG" > /etc/resolv.conf
    systemctl restart NetworkManager
}

apply_dns_systemd_resolved() {
    echo "配置 systemd-resolved..."
    mkdir -p /etc/systemd/resolved.conf.d
    cat > /etc/systemd/resolved.conf.d/dns.conf <<EOF
[Resolve]
DNS=2606:4700:4700::1111 2001:4860:4860::8888 1.1.1.1 1.0.0.1
FallbackDNS=
EOF
    systemctl restart systemd-resolved
    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
}

apply_dns_alpine() {
    echo "配置 Alpine Linux DNS..."
    echo "$DNS_CONFIG" > /etc/resolv.conf
}

main() {
    backup_resolv

    if [ -f /etc/alpine-release ]; then
        apply_dns_alpine
    elif command -v resolvconf >/dev/null 2>&1; then
        apply_dns_resolvconf
    elif [ -d /etc/netplan ]; then
        apply_dns_netplan
    elif systemctl is-active --quiet systemd-resolved; then
        apply_dns_systemd_resolved
    elif systemctl is-active --quiet NetworkManager; then
        apply_dns_networkmanager
    else
        echo "⚠️ 未识别系统，不修改 DNS"
        exit 1
    fi

    echo "✅ DNS 配置完成，请测试：ping -c 3 1.1.1.1 或 dig google.com"
}

main
