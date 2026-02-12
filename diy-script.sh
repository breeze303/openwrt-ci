#!/bin/bash

# 进入 OpenWrt 源码目录
cd $OPENWRT_PATH

# 1. 基础系统设置
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate || echo "IP修改跳过"

# 2. 清理可能导致冲突的旧包
# 理由：LiBwrt 源码中可能自带了这些插件的不同版本。如果不删干净就执行 git clone，
# 编译时会提示 "Multiple packages with the same name"，甚至导致编译中断。
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 3. 集成插件 (确保与 .config 中的定义匹配)
# PassWall2 及其核心
# 理由：PassWall2 的核心组件（如 xray, sing-box）在 openwrt-passwall 仓库中，
# 插件本体在 luci-app-passwall 仓库。必须成对拉取。
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall2

# Argon 主题
# 理由：移除 feeds 自带的旧版，通过 git 拉取 jerrykuku 的最新版以获得更好的 UI 体验。
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# 4. 优化：强制移除不需要的 Docker 相关组件 (如果源码自带了它们)
# 理由：既然我们在 .config 中取消了 Docker，手动清理掉这些 package 目录
# 可以进一步缩短 feeds update 的扫描时间，并避免无用的 IPK 生成。
# rm -rf feeds/luci/applications/luci-app-dockerman

# 5. 修复与环境适配 (可选)
# 理由：解决特定环境下 GCC 的编译报错（之前提到过的针对 aarch64 的 xfsprogs 修复）
if [ -f feeds/packages/utils/xfsprogs/Makefile ]; then
    sed -i 's/TARGET_CFLAGS.*/& -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile
fi

# 6. 刷新并安装 Feeds
# 理由：这一步会根据当前的 package 目录重新生成索引，确保新拉取的 PassWall2 能够被识别并正确编译。
./scripts/feeds update -a
./scripts/feeds install -a
