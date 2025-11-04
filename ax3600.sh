#!/bin/bash
sed -i "s/^# CONFIG_TARGET_qualcommax_ipq807x_DEVICE_xiaomi_ax3600 is not set/CONFIG_TARGET_qualcommax_ipq807x_DEVICE_xiaomi_ax3600=y/" .config
sed -i 's/^CONFIG_CCACHE=y/CONFIG_CCACHE=n/' .config
sed -i '/^CONFIG_PACKAGE_luci-app-\(sqm\|statistics\|acme\|watchcat\|nlbwmon\)=y/s/^/# /' .config
sed -i '/^CONFIG_PACKAGE_iperf3=y/s/^/# /' .config
git clone https://github.com/ouyangyilang/openwrt-vlmcsd.git package/vlmcsd/openwrt-vlmcsd
git clone https://github.com/cokebar/luci-app-vlmcsd.git package/vlmcsd/luci-app-vlmcsd
sed -i "s/'0'/'1'/g" package/vlmcsd/luci-app-vlmcsd/files/vlmcsd.config
git clone https://github.com/jerrykuku/luci-theme-argon.git package/argon/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git package/argon/luci-app-argon-config
sed -i -e "s/set system\.@system\[-1\]\.hostname='OpenWrt'/set system.@system[-1].hostname='Oyyl_Router'/" package/base-files/files/bin/config_generate
sed -i -e "s/set system\.@system\[-1\]\.timezone='GMT0'/set system.@system[-1].timezone='CST-8'/" package/base-files/files/bin/config_generate
sed -i -e "s/set system\.@system\[-1\]\.zonename='UTC'/set system.@system[-1].zonename='Asia\/Shanghai'/" package/base-files/files/bin/config_generate
sed -i -e "/add_list system\.ntp\.server='0.openwrt.pool.ntp.org'/, /add_list system\.ntp\.server='3.openwrt.pool.ntp.org'/c\                add_list system.ntp.server='ntp.aliyun.com'" package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.88.1/g' package/base-files/files/bin/config_generate
sed -i 's/^root:::0:99999:7:::/#&/' package/base-files/files/etc/shadow
sed -i '/^#root:::0:99999:7:::/a\root:$5$xmxpvLvUA0puov/Q$8VyXs7lx90md2yVksUedqKP5JyCQzpU7wY8JyqQv9e/:20389:0:99999:7:::' package/base-files/files/etc/shadow
# 移除 openwrt feeds 自带的核心库
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall/passwall-packages
# 移除 openwrt feeds 过时的luci版本
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/xiaorouji/openwrt-passwall2 package/passwall/passwall-luci
