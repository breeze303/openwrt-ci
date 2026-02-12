#!/bin/bash

# 进入 OpenWrt 源码目录
cd $OPENWRT_PATH

# 1. 基础系统设置
# 修改默认 IP 为 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate || echo "IP修改失败"

# 2. 清理可能导致冲突的旧包 (移除 feeds 中可能存在的旧版)
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 3. 集成 PassWall2 及必要依赖 (更新为 2026 活跃源)
# 核心依赖包 (Binary Core)
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
# PassWall2 插件本体 (LuCI Interface)
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall2 package/luci-app-passwall2

# Argon 主题 (最新版 UI)
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 4. 刷新并安装 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 5. 核心修正：将配置强制写入 .config 
# 理由：在 feeds 安装后强行锁定 y，防止 make defconfig 自动删除未识别的项
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_Iptables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Sing-Box=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=y
CONFIG_PACKAGE_sing-box=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_libopenssl=y
CONFIG_PACKAGE_libmbedtls=y
EOF

# 6. 最后执行一次 defconfig 刷新依赖树
make defconfig
