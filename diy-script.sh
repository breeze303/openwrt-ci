#!/bin/bash

# 进入 OpenWrt 源码目录
cd $OPENWRT_PATH

# 1. 基础系统设置 (修正路径兼容性)
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate || echo "IP修改跳过"

# 2. 清理可能导致冲突的旧包 (这一步很重要)
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/themes/luci-theme-argon

# 3. 集成 PassWall2 及必要插件 (改用稳定源)
# PassWall2 及其核心
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall2

# ⚠️ SmartDNS 处理方案：
# 如果之前报错，我们不再手动 git clone smartdns，而是依赖 feeds。
# 如果你一定要用特定版本，请克隆这个更通用的版本：
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns

# MosDNS
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# Argon 主题
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 4. 刷新并安装 Feeds (确保在脚本内部完成，避免工作流重复执行导致的逻辑混乱)
./scripts/feeds update -a
./scripts/feeds install -a
