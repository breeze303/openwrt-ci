#!/bin/bash

# 进入 OpenWrt 源码目录 (CI 环境中通常已在当前目录)
# cd $OPENWRT_PATH

# 1. 基础系统设置：修改默认 IP
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 修改 ttyd 默认执行命令，添加 -f root 参数实现自动登录
sed -i 's/\/bin\/login/\/bin\/login -f root/g' feeds/packages/utils/ttyd/files/ttyd.config

# 2. 清理冲突及旧版插件 (确保 feeds 更新前清理干净)
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 3. 集成最新版 PassWall2 与 Argon (修正分支问题)
# 核心依赖包
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages
# PassWall2 主程序
git clone --depth=1 https://github.com/velliLi/openwrt-passwall2 package/luci-app-passwall2
# git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall2 package/luci-app-passwall2

# kenzok8的软件源仓库，用于添加fullconenat-nft
git clone --depth=1 https://github.com/kenzok8/small-package package/small-package

# 4.Argon 主题：移除 -b 18.06 以兼容新版 OpenWrt 界面
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
# 补全Lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/lucky

# 5. 刷新并安装 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 6. 统一防火墙至 NFT (解决 6.x 内核兼容性)
find ./feeds/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'
find ./package/ -name "Makefile" | xargs sed -i 's/iptables /iptables-nft /g'
find ./feeds/ -name "Makefile" | xargs sed -i 's/xtables-legacy//g'

# 7. 写入 .config 配置补丁 (精简与功能开关)
cat >> .config <<EOF
# 防火墙与证书补全
CONFIG_PACKAGE_iptables-nft=y
CONFIG_PACKAGE_ip6tables-nft=y
CONFIG_PACKAGE_xtables-nft=y
CONFIG_PACKAGE_ca-bundle=y

# PassWall2 推荐配置：使用 Sing-Box 核心并开启 NFT 代理
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Xray=n

# 默认主题设置
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
EOF

# 8. 最后刷新依赖
make defconfig
