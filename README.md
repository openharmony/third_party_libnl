# libnl

#### Introduction & Software Architecture

- [Refer to Official Documentation](https://www.infradead.org/~tgr/libnl/)

#### Usage Instructions

- [Refer to Official API Documentation](https://www.infradead.org/~tgr/libnl/doc/api/group__cb.html)

#### Patch Details

`solve-oh-compile-problem3_11_0.patch` applies the OHOS adaptation patch and archives the patch (with conflicts resolved) to `archive/patches/` for reuse in subsequent version upgrades.

#### Build and Upgrade

This repository adopts the "pre-prepared code environment" approach: the `libnl/` source tree has already been decompressed, configured, patched, and its flex/bison syntax files pre-generated and committed to the repository. During the build phase, compilation is handled directly by `BUILD.gn`, which does not depend on autotools/flex/bison and does not execute scripts during the `gn gen` phase. When upgrading libnl, please run `prepare.sh` and refer to [docs/UPGRADE_GUIDE.md](docs/UPGRADE_GUIDE.md).


#### Contributing

[How to Contribute](https://gitee.com/openharmony/docs/blob/HEAD/zh-cn/contribute/参与贡献.md)

[Commit Message Specifications](https://gitee.com/openharmony/device_qemu/wikis/Commit%20message%E8%A7%84%E8%8C%83)


#### Related Repositories

[third_party_wpa_supplicant](https://gitee.com/openharmony/third_party_wpa_supplicant)

[drivers_peripheral](https://gitee.com/openharmony/drivers_peripheral)
