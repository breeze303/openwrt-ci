#!/bin/bash

# 进入 OpenWrt 源码目录 (Workflow 中已定义环境变量)
cd $OPENWRT_PATH

# 1. 基础系统设置
# 修改默认IP为 192.168.2.1
# 注意：LiBwrt 的路径可能在 package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate || echo "IP修改跳过"

# 修改本地时间格式
find package/ -name "index.htm" | xargs sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' || echo "时间格式修改跳过"

# 2. 移除冗余源码 (防止编译冲突)
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-passwall

# 3. 核心插件集成 (使用标准 git clone)
# PassWall2
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall2

# SmartDNS
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# MosDNS
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# Themes
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 4. 修复与环境适配
# 针对 6.12 内核可能需要的修正
if [ -f feeds/packages/utils/xfsprogs/Makefile ]; then
    sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile
fi

# 5. 刷新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
