# libnl 升级指导

本仓库采用 **代码环境提前准备** 的方式集成 libnl：上游源码已经过
解压、`configure`、flex/bison 语法文件预生成、以及应用 OpenHarmony 适配 patch，
结果直接入库到 `libnl/` 目录。因此日常构建只需 `gn`/`ninja` 直接
编译 `BUILD.gn`，**不依赖** autotools / configure / flex / bison 等主机工具，
也不在 `gn gen` 阶段执行任何脚本。

> 历史背景：旧方案在每次 `gn gen` 时通过 `BUILD.gn` 的 `exec_script("install.sh")`
> 重复解压 tarball 并运行 `autogen.sh` + `configure`，缓慢且强依赖主机环境。
> 现已由 `prepare.sh`（仅升级时手动运行）替代。

## 仓库内容约定

- `libnl/`：已准备好的源码树（含 `include/config.h`、`include/netlink/version.h`
  以及预生成的语法文件 `lib/route/{pktloc_grammar,pktloc_syntax}.{c,h}`、
  `lib/route/cls/{ematch_grammar,ematch_syntax}.{c,h}`）。直接被 `BUILD.gn` 编译。
- `prepare.sh`：分三阶段的环境准备脚本（升级时手动运行，构建期不调用）。
- `solve-oh-compile-problem3_11_0.patch`：当前生效的 OpenHarmony 适配 patch。
- `archive/patches/`：历史各版本（解决冲突后的）适配 patch 归档，供后续升级参考复用。
- `archive/libnl-<ver>.sha256sums`：**整个上游 tar 包**的 SHA256 校验和（标准
  `sha256sum` 单行格式、记录规范包名），随上游基线 commit 入库，供整包可信校验。
- `COPYING`：LGPL v2.1 许可文件。
- 上游 tarball **不入库**；上游版本/地址记录在 `README.OpenSource`（其元数据结构
  保持不变，**不**在其中记录 SHA256）。源码可信校验改由上述 `*.sha256sums`
  整包校验和 + git「上游基线 commit」提供。

## 升级流程：三个独立 commit

为清晰区分 **上游原始代码 / 构建环境产物 / OHOS 适配** 三类变更，每次升级按
`upstream → build → patch` 三个阶段进行，**每个阶段各提交一次独立 commit**。
这样 `git diff` 在三个 commit 之间分别只显示一类变更，溯源清晰、便于审计与回溯。

以从 `3.11.0` 升级到新版本 `<new_ver>` 为例：

### 0. 准备：更新脚本变量与版本元信息

- 编辑 `prepare.sh` 顶部变量：`LIBNL_VERSION`、`UPSTREAM_URL`、`EXTRACTED_DIR`
  （若上游归档顶层目录名变化）。
- 更新 `README.OpenSource` 的 `Version Number` 与 `Upstream URL`
  （**不**新增 SHA256 字段，保持其元数据结构不变）。
- 更新 `bundle.json` 的 `version`（如适用）。

### 1. commit 1 —— 纯上游源码基线（可信溯源）

```sh
# 方式一：使用本地已下载 tarball；方式二：省略路径，从 Upstream URL 下载
./prepare.sh upstream /path/to/libnl-<new_ver>.tar.gz
```

该阶段会清空 `libnl/` 并解压**未经任何修改**的上游源码树（不含 config.h、
不含语法生成物、不含 OHOS 改动）。脚本会：

- 对**整个上游 tar 包**计算 SHA256，写入 `archive/libnl-<new_ver>.sha256sums`
  （标准 `sha256sum` 单行格式、记录规范包名），随本 commit 入库。
- 该整包校验和可用于：
  ```sh
  # 将上游 tar 包按规范名（如 libnl3_11_0.tar.gz）放到 archive/ 下后校验
  ( cd archive && sha256sum -c libnl-<new_ver>.sha256sums )
  ```
  或直接把该值与**上游社区发布的 sha256sum 文件**比对，确认 tar 包可信。
  > 说明：校验对象是**整包 tar.gz**，与上游社区通常发布的校验形式一致；因此
  > 无需逐文件计算，也不受入库后 configure/patch 改动的影响。

- 提交：
  ```sh
  git add libnl/ archive/libnl-<new_ver>.sha256sums README.OpenSource
  git commit -m "Import libnl <new_ver> upstream"
  ```

### 2. commit 2 —— 构建环境产物（configure + 语法文件）

```sh
./prepare.sh build
```

该阶段运行 `autogen.sh` + `configure`（产出 `config.h`/`version.h`）、flex/bison
预生成 8 个语法文件、清理 autotools 中间产物，并自动调整 `libnl/.gitignore`
使上述生成物可入库。

- 本 commit 的 diff 仅为「新增 config.h + version.h + 8 个语法文件 + .gitignore 调整」，
  不含任何 OHOS 源码改动。
- 提交：
  ```sh
  git add libnl/
  git commit -m "libnl <new_ver> build env (configure + grammars)"
  ```

### 3. commit 3 —— OHOS 适配 patch

```sh
./prepare.sh patch
```

该阶段应用 `solve-oh-compile-problem3_11_0.patch`，并把（解决冲突后的）patch
归档到 `archive/patches/solve-oh-compile-problem-<new_ver>.patch`。

- **若 patch 冲突**：脚本会报错中止。请手动解决冲突、更新根目录的
  `solve-oh-compile-problem*.patch`（或依据上游变更重做），再重新运行
  `./prepare.sh patch`。当前 patch 涉及的文件（升级后重点检查是否仍兼容）：
  - `lib/utils.c`、`lib/route/mdb.c`、`lib/route/neigh.c`、`lib/route/link/bridge.c`
  - `include/base/nl-base-utils.h`
  - `include/config.h`（交叉编译值修正：`HAVE_STRERROR_L`、
    `HAVE_DECL_GETPROTOBYNAME_R`、`HAVE_DECL_GETPROTOBYNUMBER_R` 置 0）
  - `include/nl-priv-dynamic-core/nl-core.h`、`src/lib/utils.c`
- 本 commit 的 diff 仅为「OHOS 对上游源码的适配改动 + 归档 patch」。
- 提交：
  ```sh
  git add libnl/ archive/patches/
  git commit -m "libnl <new_ver> OHOS adaptation patch"
  ```

> 提示：`upstream`/`build`/`patch` 操作的文件集互不相交，`build` 与 `patch` 顺序
> 理论上可换；但务必保持 `configure`（在 build 阶段）早于 `patch`，因为 patch 要
> 修正 configure 生成的 `config.h` 交叉编译值。

### 4. 同步 `BUILD.gn` 的 `sources` 列表

若上游新增/删除/重命名了 `lib/`、`src/lib/` 下的 `.c` 文件，需相应增删 `BUILD.gn`
中 `sources` 条目。语法文件（`pktloc_*`、`ematch_*`）已作为预生成源直接列入
`sources`，无需 `action()`。此改动可并入 commit 3 或单独提交。

### 5. 构建验证

```sh
./build.sh --product-name <product> --build-target libnl_share
```

验证要点：

- `gn gen` 阶段不再执行任何脚本（无 `install.sh` / autotools 调用）。
- 即使主机 **未安装** flex / bison / autoconf，也能成功编译出 `libnl_share` 动态库。

## 一次性快速搭建（非升级场景）

若只是想在本地一次性重建已准备好的源码树（不关心三 commit 拆分）：

```sh
./prepare.sh all /path/to/libnl-3.11.0.tar.gz
```

## 设计要点（为何这样做）

- `configure` 产物中，GN 构建实际只需要 `include/config.h` 与
  `include/netlink/version.h` 两个文件；其余 Makefile / libtool / `.pc` 等
  对 GN 构建无用，故 `build` 阶段在生成后即清理，保持源码树精简、
  避免泄漏主机路径。
- `config.h` 由 `configure` 在主机生成后，再由 patch 修正为交叉编译正确值，
  因此 **顺序必须是先 `configure` 后 `patch`**。
- 三阶段对应三 commit，使「上游代码」「构建产物」「OHOS 适配」在版本历史中
  天然解耦：审计上游变更只看 commit 1，审计 OHOS 改动只看 commit 3。
