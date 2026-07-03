#!/bin/bash
# Copyright(c) 2026 Huawei Device Co., Ltd.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# prepare.sh —— libnl 代码环境准备脚本（仅升级 libnl 时手动运行，构建期 BUILD.gn
# 不调用本脚本）。
#
# 为区分「上游原始代码 / 构建环境产物 / OHOS 适配」三类变更，本脚本拆成三个阶段，
# 每个阶段对应一次独立 git commit，便于源码可信追踪与后续升级：
#
#   stage 1  upstream  清空 libnl/ 并解压纯上游源码树（无任何改动/生成物）
#                      -> 提交 commit 1 [Import libnl <ver> upstream]
#   stage 2  build     autogen + configure（产出 config.h/version.h）、flex/bison
#                      预生成语法文件、清理 autotools 中间产物
#                      -> 提交 commit 2 [libnl <ver> build env (configure + grammars)]
#   stage 3  patch     应用 OHOS 适配 patch，并把（解决冲突后的）patch 归档到
#                      archive/patches/ 供后续版本升级使用
#                      -> 提交 commit 3 [libnl <ver> OHOS adaptation patch]
#
# 用法:
#   ./prepare.sh upstream [/path/to/libnl-<ver>.tar.gz]   # 阶段1（省略路径时则从上游下载）
#   ./prepare.sh build                                    # 阶段2
#   ./prepare.sh patch                                    # 阶段3
#   ./prepare.sh all      [/path/to/libnl-<ver>.tar.gz]   # 一次性跑完（非升级快速搭建和验证）
#
# 依赖主机工具: tar, sha256sum, patch, flex, bison,
#               autoreconf(automake/autoconf/libtool), 以及下载场景的 curl/wget。
#               这些工具仅本脚本需要，日常 gn/ninja 构建不需要。

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ============ 升级时按实际情况更新以下变量 ============
LIBNL_VERSION="3.11.0"
UPSTREAM_URL="https://github.com/thom311/libnl/archive/refs/tags/libnl3_11_0.tar.gz"
EXTRACTED_DIR="libnl-libnl3_11_0"   # 上游归档解压后的顶层目录名
PATCH_FILE="$SCRIPT_DIR/solve-oh-compile-problem3_11_0.patch"
# ===============================================

ARCHIVE_PATCH_DIR="$SCRIPT_DIR/archive/patches"

die()  { echo "[prepare] ERROR: $*" >&2; exit 1; }
info() { echo "[prepare] $*"; }

# ---------------------------------------------------------------------------
# 阶段 1：清空 libnl/ 并解压纯上游源码树（不做任何修改/生成）
# ---------------------------------------------------------------------------
stage_upstream() {
    local arg="$1" tarball tmp=""

    if [ -n "$arg" ]; then
        tarball="$arg"
        [ -f "$tarball" ] || die "tarball not found: $tarball"
    else
        tmp="$(mktemp /tmp/libnl-src.XXXXXX.tar.gz)"
        tarball="$tmp"
        info "未指定 tarball，从上游下载: $UPSTREAM_URL"
        if command -v curl >/dev/null 2>&1; then
            curl -fL "$UPSTREAM_URL" -o "$tarball" || die "下载失败"
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$tarball" "$UPSTREAM_URL" || die "下载失败"
        else
            die "需要 curl 或 wget 来下载 tarball；或显式传入本地 tarball 路径"
        fi
    fi

    # 对整个上游 tar 包计算一次 SHA256（标准 sha256sum 格式，单行、记录规范包名），
    # 随 commit 1 入库。用户可用同名 tar 包 `sha256sum -c` 复算，或直接与上游社区
    # 发布的 sha256sum 文件比对。
    mkdir -p archive
    local sums="archive/libnl-${LIBNL_VERSION}.sha256sums"
    local tarname
    tarname="$(basename "$UPSTREAM_URL")"   # 规范 tar 包名（如 libnl3_11_0.tar.gz）
    printf '%s  %s\n' "$(sha256sum "$tarball" | awk '{print $1}')" "$tarname" > "$sums"
    info "已生成上游整包 SHA256 -> $sums"
    info "  校验方式: 将上游 tar 包按 $tarname 命名后，在 archive/ 下执行"
    info "            sha256sum -c libnl-${LIBNL_VERSION}.sha256sums"
    info "  或直接与上游社区发布的 sha256sum 文件比对该值。"

    info "清空 libnl/ 并解压纯上游源码树"
    rm -rf libnl "$EXTRACTED_DIR"
    tar xf "$tarball"
    [ -d "$EXTRACTED_DIR" ] || die "解压后未找到目录 $EXTRACTED_DIR"
    mv "$EXTRACTED_DIR" libnl

    [ -n "$tmp" ] && rm -f "$tmp"

    info "阶段1完成。请提交 commit 1（纯上游源码基线 + 整包 SHA256），例如："
    info "  git add libnl/ \"$sums\" && git commit -m \"Import libnl ${LIBNL_VERSION} upstream\""
}

# ---------------------------------------------------------------------------
# 阶段 2：autogen + configure + 语法预生成 + 清理 autotools 中间产物
# ---------------------------------------------------------------------------
stage_build() {
    [ -d libnl ] || die "未找到 libnl/，请先运行: ./prepare.sh upstream"

    cd libnl

    info "运行 autogen.sh + configure（产出 config.h / version.h）"
    ./autogen.sh
    ./configure

    info "flex/bison 预生成 4 组（共 8 个）语法文件"
    flex --header-file=lib/route/pktloc_grammar.h     -o lib/route/pktloc_grammar.c     lib/route/pktloc_grammar.l
    bison -y -d                                        -o lib/route/pktloc_syntax.c      lib/route/pktloc_syntax.y
    flex --header-file=lib/route/cls/ematch_grammar.h -o lib/route/cls/ematch_grammar.c lib/route/cls/ematch_grammar.l
    bison -y -d                                        -o lib/route/cls/ematch_syntax.c  lib/route/cls/ematch_syntax.y

    info "清理 autotools 中间产物（GN 构建不需要，且会泄漏主机路径）"
    rm -f config.status config.log libtool aclocal.m4 stamp-h1 configure
    rm -rf autom4te.cache build-aux
    rm -f libnl-*.pc
    find . -name 'Makefile' -delete
    find . -name 'Makefile.in' -delete
    find . -name '.dirstamp' -delete
    find . -name 'stamp-h1' -delete
    rm -f doc/configure doc/config.status doc/config.log
    rm -rf doc/autom4te.cache doc/build-aux
    # 以下为 autogen/configure 在源码树各处留下的其余生成物（均被上游 .gitignore 忽略，
    # 不会入库；此处物理删除以保证准备好的源码树 == 纯上游 + config.h/version.h/语法文件，
    # 便于与上游社区源码逐文件对比校验）：
    find . -type d -name '.deps' -exec rm -rf {} + 2>/dev/null || true  # 依赖跟踪桩(.Plo)
    find . -name '*~' -delete                                           # 备份文件(configure~ 等)
    rm -f include/config.h.in                                          # autoheader 生成模板
    rm -f doc/Doxyfile doc/aclocal.m4                                  # doc 配置/autoreconf 产物
    rm -f m4/libtool.m4 m4/lt*.m4                                      # libtoolize 生成
    rm -f python/setup.py                                             # configure 由 setup.py.in 生成

    cd "$SCRIPT_DIR"

    # 让上一步生成的 config.h/version.h/语法文件不再被 libnl 自带 .gitignore 忽略，
    # 从而能正常纳入 commit 2（属于「构建环境产物」而非 OHOS 源码适配）。
    unignore_prepared_files

    info "阶段2完成。请提交 commit 2（构建环境产物），例如："
    info "  git add libnl/ && git commit -m \"libnl ${LIBNL_VERSION} build env (configure + grammars)\""
}

# 取消忽略提前生成的构建产物（精确整行匹配，避免正则转义问题）
unignore_prepared_files() {
    local gi="libnl/.gitignore" line
    [ -f "$gi" ] || return 0
    for line in \
        '/include/config.h' \
        '/include/netlink/version.h' \
        '/lib/route/cls/ematch_grammar.[ch]' \
        '/lib/route/cls/ematch_syntax.[ch]' \
        '/lib/route/pktloc_grammar.c' \
        '/lib/route/pktloc_grammar.h' \
        '/lib/route/pktloc_syntax.c' \
        '/lib/route/pktloc_syntax.h'
    do
        awk -v t="$line" '{ if ($0==t) print "# (OHOS prepared, tracked) " $0; else print }' \
            "$gi" > "$gi.tmp" && mv "$gi.tmp" "$gi"
    done
}

# ---------------------------------------------------------------------------
# 阶段 3：应用 OHOS 适配 patch，并归档（解决冲突后的）patch
# ---------------------------------------------------------------------------
stage_patch() {
    [ -d libnl ] || die "未找到 libnl/，请先运行: ./prepare.sh upstream && ./prepare.sh build"
    [ -f "$PATCH_FILE" ] || die "patch 不存在: $PATCH_FILE"

    info "应用 OHOS 适配 patch: $(basename "$PATCH_FILE")"
    info "  （必须在 configure 之后：patch 会把 config.h 的 HAVE_STRERROR_L 等改为交叉编译正确值）"
    ( cd libnl && patch -p1 < "$PATCH_FILE" --fuzz=0 --no-backup-if-mismatch ) \
        || die "patch 应用失败：请手动解决冲突、更新 $(basename "$PATCH_FILE") 后重试"

    # 归档当前（解决冲突后的）patch，供后续版本升级参考复用
    mkdir -p "$ARCHIVE_PATCH_DIR"
    cp "$PATCH_FILE" "$ARCHIVE_PATCH_DIR/solve-oh-compile-problem-${LIBNL_VERSION}.patch"
    info "已归档 patch -> archive/patches/solve-oh-compile-problem-${LIBNL_VERSION}.patch"

    info "阶段3完成。请确认无 *.rej/*.orig 残留后提交 commit 3（OHOS 适配），例如："
    info "  git add libnl/ archive/ && git commit -m \"libnl ${LIBNL_VERSION} OHOS adaptation patch\""
}

usage() {
    cat >&2 <<EOF
用法:
  ./prepare.sh upstream [/path/to/libnl-<ver>.tar.gz]   # 阶段1：纯上游源码 -> commit 1
  ./prepare.sh build                                    # 阶段2：构建环境产物 -> commit 2
  ./prepare.sh patch                                    # 阶段3：OHOS 适配 patch -> commit 3
  ./prepare.sh all      [/path/to/libnl-<ver>.tar.gz]   # 一次性跑完（非升级快速搭建）

升级 libnl 时请按 upstream -> build -> patch 顺序运行，并在每阶段之间各提交一次
独立 commit。详见 docs/UPGRADE_GUIDE.md。
EOF
    exit 1
}

case "$1" in
    upstream) stage_upstream "$2" ;;
    build)    stage_build ;;
    patch)    stage_patch ;;
    all)      stage_upstream "$2"; stage_build; stage_patch ;;
    -h|--help|help) usage ;;
    "")       usage ;;
    *)        die "未知子命令: $1（运行 ./prepare.sh --help 查看用法）" ;;
esac
