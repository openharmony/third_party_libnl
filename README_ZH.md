# libnl

#### 简介 & 软件架构

- [参考官方文档](https://www.infradead.org/~tgr/libnl/)

#### 使用说明

- [参考官方API文档](https://www.infradead.org/~tgr/libnl/doc/api/group__cb.html)

#### patch包说明

以下patch包为openEuler:libnl3开源库本身携带
backport-lib-add-include-netlink-private-nl-auto-h-header.patch
backport-lib-use-proper-int-type-for-id-attributes-in-nl_object_identical.patch
backport-route-link-add-RTNL_LINK_REASM_OVERLAPS-stat.patch
backport-route-link-Check-for-null-pointer-in-macvlan.patch
backport-rtnl-link-fix-leaking-rtnl_link_af_ops-in-link_msg_parser.patch
backport-rtnl-route-fix-NLE_NOMEM-handling-in-parse_multipath.patch
solve-redefinition-of-struct-ipv6_mreq.patch

以下patch包为解决在OpenHarmony工程下编译存在的问题自行添加
lib-utils-c.patch
src-lib-utils-c.patch
vrf-c.patch

#### 参与贡献

[如何贡献](https://gitee.com/openharmony/docs/blob/HEAD/zh-cn/contribute/参与贡献.md)

[Commit message规范](https://gitee.com/openharmony/device_qemu/wikis/Commit%20message%E8%A7%84%E8%8C%83)


#### 相关仓

[third_party_wpa_supplicant](https://gitee.com/openharmony/third_party_wpa_supplicant)

[drivers_peripheral](https://gitee.com/openharmony/drivers_peripheral)

