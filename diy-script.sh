#!/bin/bash

# 进入 OpenWrt 源码目录 (环境变量由 Workflow 传入)
cd $OPENWRT_PATH

# 1. 基础系统设置
# 修改默认 IP 为 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate || echo "IP修改跳过"

# 2. 清理可能导致冲突的旧包
# 理由：移除 feeds 中可能存在的旧版插件，防止“Multiple packages with the same name”错误
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 3. 集成 PassWall2 及必要依赖 (使用 2026 年最新活跃仓库)
# 理由：xiaorouji 仓库已失效，必须使用 Openwrt-Passwall 组织下的新仓库
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall2 package/luci-app-passwall2

# Argon 主题
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 4. 刷新并安装 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 5. 【核心修复】暴力解决 iptables-nft 冲突
# 理由：6.12 内核不再支持旧版防火墙，但许多插件仍依赖 "iptables"。
# 我们遍历所有 Makefile，将对 "iptables" 的依赖全部强制替换为 "iptables-nft"。
find ./feeds/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'
find ./package/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'

# 6. 强制补全 .config 配置项
# 理由：确保在编译前最后关头锁定 PassWall2 和 NFT 架构，防止被 defconfig 自动剔除
cat >> .config <<EOF
# 锁定 NFT 架构，剔除旧版防火墙
CONFIG_PACKAGE_iptables-nft=y
CONFIG_PACKAGE_ip6tables-nft=y
CONFIG_PACKAGE_xtables-nft=y
# CONFIG_PACKAGE_iptables is not set
# CONFIG_PACKAGE_ip6tables is not set
# CONFIG_PACKAGE_iptables-zz-legacy is not set
# CONFIG_PACKAGE_ip6tables-zz-legacy is not set

# PassWall2 核心配置
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_Iptables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Sing-Box=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=y

# 基础依赖补全
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_libopenssl=y
CONFIG_PACKAGE_libmbedtls=y
EOF

# 7. 最后刷新依赖树
make defconfig
