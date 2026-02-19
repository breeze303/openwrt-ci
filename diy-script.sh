#!/bin/bash

# 进入源码目录
cd "$(dirname "$0")"

# 修改默认 IP
sed -i 's/192.168.1.1/192.168.2.1/' package/base-files/files/bin/config_generate

# ttyd 免登录
sed -i 's|/bin/login|/bin/login -f root|' feeds/packages/utils/ttyd/files/ttyd.config

# 删除旧版 passwall2 / argon
rm -rf feeds/luci/applications/luci-app-passwall2
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# clone 最新 passwall2
git clone --depth=1 https://github.com/velliLi/openwrt-passwall2 package/luci-app-passwall2
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages

# Argon 主题
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# Lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/lucky

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 写入补充配置
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
EOF
