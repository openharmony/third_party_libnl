# libnl

#### Introduction & Software Architecture
- [Refer to the official documentation](https://www.infradead.org/~tgr/libnl/)

#### Usage Guidelines

- [Refer to the official API documentation](https://www.infradead.org/~tgr/libnl/doc/api/group__cb.html)

#### Generates  Header File

The following patches is carried by the openEuler:libnl3 open source library:

backport-lib-add-include-netlink-private-nl-auto-h-header.patch
backport-lib-use-proper-int-type-for-id-attributes-in-nl_object_identical.patch
backport-route-link-add-RTNL_LINK_REASM_OVERLAPS-stat.patch
backport-route-link-Check-for-null-pointer-in-macvlan.patch
backport-rtnl-link-fix-leaking-rtnl_link_af_ops-in-link_msg_parser.patch
backport-rtnl-route-fix-NLE_NOMEM-handling-in-parse_multipath.patch
solve-redefinition-of-struct-ipv6_mreq.patch

The following patches are added to solve the compilation problem under the OpenHarmony project:

lib-utils-c.patch
src-lib-utils-c.patch
vrf-c.patch

#### Contribution

[How to involve](https://gitee.com/openharmony/docs/blob/HEAD/zh-cn/contribute/参与贡献.md)

[Commit message spec](https://gitee.com/openharmony/device_qemu/wikis/Commit%20message%E8%A7%84%E8%8C%83)

#### Repositories Involved

[third_party_wpa_supplicant](https://gitee.com/openharmony/third_party_wpa_supplicant)

[drivers_peripheral](https://gitee.com/openharmony/drivers_peripheral)

