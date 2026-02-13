#!/bin/bash

# 进入 OpenWrt 源码目录
cd $OPENWRT_PATH

# 1. 基础系统设置
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 2. 清理冲突插件
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 3. 集成最新版 PassWall2 与 Argon
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall2 package/luci-app-passwall2
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 4. 刷新并安装 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 5. 【核心优化】彻底切断旧版防火墙依赖
# 将所有插件 Makefile 中的 iptables 依赖强制指向 iptables-nft
find ./feeds/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'
find ./package/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'
# 移除过时的 xtables-legacy 关联
find ./feeds/ -name "Makefile" | xargs sed -i 's/xtables-legacy//g'

# 6. 写入最终配置补丁
cat >> .config <<EOF
# 防火墙强制现代版
CONFIG_PACKAGE_iptables-nft=y
CONFIG_PACKAGE_ip6tables-nft=y
CONFIG_PACKAGE_xtables-nft=y
# CONFIG_PACKAGE_iptables-zz-legacy is not set
# CONFIG_PACKAGE_xtables-legacy is not set

# PassWall2 核心精简 (只保留 Sing-Box/Xray)
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Xray=y
# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Libev_Client is not set
# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Client is not set

# 移除内嵌数据库 (减小体积)
# CONFIG_PACKAGE_v2ray-geoip is not set
# CONFIG_PACKAGE_v2ray-geosite is not set
EOF

# 7. 刷新依赖树
make defconfig
