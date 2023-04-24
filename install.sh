#!/bin/bash
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation version 2.1
# of the License.
#
# Copyright(c) 2023 Huawei Device Co., Ltd.

set -e
cd $1
if [ -d "libnl-3.5.0" ];then
    rm -rf libnl-3.5.0
fi
tar xvf libnl-3.5.0.tar.gz
cd $1/libnl-3.5.0
./configure
patch -p1 < $1/backport-lib-add-include-netlink-private-nl-auto-h-header.patch --fuzz=0 --no-backup-if-mismatch
patch -p1 < $1/backport-lib-use-proper-int-type-for-id-attributes-in-nl_object_identical.patch --fuzz=0 --no-backup-if-mismatch
patch -p1 < $1/backport-route-link-add-RTNL_LINK_REASM_OVERLAPS-stat.patch --fuzz=0 --no-backup-if-mismatch
patch -p1 < $1/backport-route-link-Check-for-null-pointer-in-macvlan.patch --fuzz=0 --no-backup-if-mismatch
patch -p1 < $1/backport-rtnl-link-fix-leaking-rtnl_link_af_ops-in-link_msg_parser.patch --fuzz=0 --no-backup-if-mismatch
patch -p1 < $1/backport-rtnl-route-fix-NLE_NOMEM-handling-in-parse_multipath.patch --fuzz=0 --no-backup-if-mismatch
patch -p1 < $1/solve-redefinition-of-struct-ipv6_mreq.patch --fuzz=0 --no-backup-if-mismatch
patch -p1 < $1/solve-oh-compile-problem.patch --fuzz=0 --no-backup-if-mismatch
exit 0
