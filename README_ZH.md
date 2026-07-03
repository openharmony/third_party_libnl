# libnl

#### 简介 & 软件架构

- [参考官方文档](https://www.infradead.org/~tgr/libnl/)

#### 使用说明

- [参考官方API文档](https://www.infradead.org/~tgr/libnl/doc/api/group__cb.html)

#### patch包说明

solve-oh-compile-problem3_11_0.patch 应用 OHOS 适配 patch，并把（解决冲突后的）
patch 归档到archive/patches/ 供后续版本升级复用

#### 构建与升级

本仓库采用“代码环境提前准备”方式：`libnl/` 源码树已完成解压、configure、
打 patch 及 flex/bison 语法文件预生成并入库，构建期由 `BUILD.gn` 直接编译，
不依赖 autotools/flex/bison，也不在 `gn gen` 阶段执行脚本。升级 libnl 时请运行
`prepare.sh` 并参考 [docs/UPGRADE_GUIDE.md](docs/UPGRADE_GUIDE.md)。


#### 参与贡献

[如何贡献](https://gitee.com/openharmony/docs/blob/HEAD/zh-cn/contribute/参与贡献.md)

[Commit message规范](https://gitee.com/openharmony/device_qemu/wikis/Commit%20message%E8%A7%84%E8%8C%83)


#### 相关仓

[third_party_wpa_supplicant](https://gitee.com/openharmony/third_party_wpa_supplicant)

[drivers_peripheral](https://gitee.com/openharmony/drivers_peripheral)

