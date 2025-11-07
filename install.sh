#!/bin/bash
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation version 2.1
# of the License.
#
# Copyright(c) 2023 Huawei Device Co., Ltd.

set -e
cd $1
touch test.lock
(
    flock -x 200
if [ -d "libnl" ];then
    rm -rf libnl
fi
tar xvf libnl-libnl3_11_0.tar.gz
mv libnl-libnl3_11_0 libnl
cd $1/libnl
./autogen.sh
./configure
patch -p1 < $1/solve-oh-compile-problem3_11_0.patch --fuzz=0 --no-backup-if-mismatch
exit 0
)200>test.lock
