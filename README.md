# rv32-llvm-picolibc-xpack

LLVM sysroot build providing a RISC-V bare-metal build from:

- **LLVM 22**
- **picolibc 1.8.11**

Targets CH32V series MCUs with the `xwchc` vendor extension.

## Sysroot variants

Four multilib variants are active and selected automatically by clang based on
compiler flags (`-march`, `-mabi`, `-fno-exceptions`, `-fno-rtti`):

| Variant directory | `-march` | `-mabi` | Exceptions | RTTI |
|---|---|---|---|---|
| `rv32imafc-zicsr-zifencei-xwchc_ilp32f_exn_rtti` | rv32imafc_…_xwchc | ilp32f | ✓ | ✓ |
| `rv32imafc-zicsr-zifencei-xwchc_ilp32f` | rv32imafc_…_xwchc | ilp32f | — | — |
| `rv32imac-zicsr-zifencei-xwchc_ilp32_exn_rtti` | rv32imac_…_xwchc | ilp32 | ✓ | ✓ |
| `rv32imac-zicsr-zifencei-xwchc_ilp32` | rv32imac_…_xwchc | ilp32 | — | — |

## Install manually

Download latest relase, unarchive and use with `--sysroot=PATH_TO_UNARCHIVED_DIR/dist`.

If using cmake, you may find useful ready-made cmake files in `cmake/` directory.

```sh
cmake -DCMAKE_TOOLCHAIN_FILE=rv32-llvm-picolibc/cmake/clang-riscv-ch32v.cmake
```

## Install with xpm

```sh
npx xpm install morpheby/rv32-llvm-picolibc#release/v22.1.4-1.8.11
```

or add to `package.json`:

```json
"xpack": {
  "devDependencies": {
    "@morpheby/rv32-llvm-picolibc": "github:morpheby/rv32-llvm-picolibc-xpack#release/v22.1.4-1.8.11"
  }
}
```

Note that the `main` branch does not provide useful `package.json`, only template. All specific releases
are done in `release/` branches.

## License and acknowledgments

This project is licensed under the **Apache License, Version 2.0** — see
[LICENSE](LICENSE) for the full text.

Portions of this project are derived from or inspired by the
[LLVM Embedded Toolchain for Arm](https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm)
project (© 2020–2023 Arm Limited and affiliates, Apache-2.0).  Specifically:

- `multilib.yaml` — structure and comments adapted from `multilib.yaml.in` in
  that repository.
- `picolibc-cross-files/*.txt` — cross-file format and property conventions
  follow those established in the same project.
- `scripts/build-*.sh` — CMake/meson invocation patterns and staged-install
  technique are derived from its build system.

See [NOTICE](NOTICE) for the full attribution.

---

## Versioning

Release names follow the format:

```
rv32-llvm-picolibc-xpack-{llvm_ver}-{picolibc_ver}-{release_num}
```

## Building locally

Requires: LLVM 21 (clang, clang++, lld, llvm-ar, llvm-nm, llvm-ranlib),
cmake, ninja, meson.

```sh
# 1. Clone sources
git clone --depth=1 --branch main https://github.com/llvm/llvm-project.git workspace/llvm-project
git clone --depth=1 --branch main https://github.com/picolibc/picolibc.git  workspace/picolibc

# 2. Apply patches (if any)
cd workspace/llvm-project
git apply ../../patches/llvmorg-22.1.4.patch
cd ../..

# 3. Set up environment
export XPACK_DIR="$(pwd)"   # root of this repository checkout
export WORKSPACE="$(pwd)/workspace"
export DIST_DIR="$WORKSPACE/rv32-llvm-picolibc"
export PICOLIBC_CROSS_FILES_DIR="$XPACK_DIR/picolibc-cross-files"

# 4. Build in order
(cd workspace/llvm-project &&  "$XPACK_DIR/scripts/build-compiler_rt.sh")
(cd workspace/picolibc      && "$XPACK_DIR/scripts/build-picolibc.sh")
(cd workspace/llvm-project && "$XPACK_DIR/scripts/build-libcxx.sh")

```
