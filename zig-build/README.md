# ZLMediaKit 使用 Zig CC 交叉编译指南

本目录包含使用 Zig CC 交叉编译 ZLMediaKit 的脚本。

## 脚本说明

- `build-zlm.sh`: 使用 Zig CC 直接交叉编译 ZLMediaKit

## 使用方法

### 基本用法

```bash
# 使用默认目标架构 (x86_64-linux-gnu),不编译webrtc
cd zig-build
./build-zlm.sh

# 指定目标架构
./build-zlm.sh --target=aarch64-linux-gnu --enable-webrtc
```

### 支持的目标架构

- `x86_64-linux-gnu`: x86_64 Linux (GNU libc)
- `aarch64-linux-gnu`: ARM64 Linux (GNU libc)
- `riscv64-linux-gnu`: RISC-V 64-bit Linux (GNU libc)
- `x86_64-macos`: x86_64 macOS
- `aarch64-macos`: ARM64 macOS

## 工作原理

脚本通过以下步骤实现交叉编译:

1. 设置 Zig CC 作为编译器: `CC="zig cc -target $TARGET"`
2. 根据目标架构选择适当的 ZLMediaKit 配置目标
3. 使用 ZLMediaKit 的 Configure 脚本配置构建
4. 编译并安装到指定目录

## 输出文件

编译后的文件将安装到 `zig-build/build-install-<TARGET>` 目录:


## 注意事项

- 需要安装 Zig 编译器 (https://ziglang.org/download/)
- Windows无法在Linux系统下构建
- riscv64交叉编译需要修改代码
