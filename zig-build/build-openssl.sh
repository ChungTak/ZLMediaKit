#!/bin/bash
# OpenSSL 3.4.1 使用Zig CC交叉编译脚本

# 出错时退出
set -e

# 默认目标架构
TARGET="x86_64-linux-gnu"
OPENSSL_DIR="$(pwd)/../3rdpart/openssl"
BUILD_DIR="$(pwd)/openssl-build-${TARGET}"
INSTALL_DIR="$(pwd)/openssl-install-${TARGET}"

# 解析命令行参数
for arg in "$@"; do
  case $arg in
    --target=*)
      TARGET="${arg#*=}"
      BUILD_DIR="$(pwd)/openssl-build-${TARGET}"
      INSTALL_DIR="$(pwd)/openssl-install-${TARGET}"
      shift
      ;;
    --help)
      echo "用法: $0 [选项]"
      echo "选项:"
      echo "  --target=<目标>    指定目标架构 (默认: x86_64-linux-gnu)"
      echo "  --help             显示此帮助信息"
      echo ""
      echo "支持的目标架构示例:"
      echo "  x86_64-linux-gnu      - x86_64 Linux (GNU libc)"
      echo "  x86_64-linux-musl     - x86_64 Linux (musl libc)"
      echo "  aarch64-linux-gnu     - ARM64 Linux (GNU libc)"
      echo "  aarch64-linux-musl    - ARM64 Linux (musl libc)"
      echo "  riscv64-linux-gnu     - RISC-V 64-bit Linux (GNU libc)"
      echo "  riscv64-linux-musl    - RISC-V 64-bit Linux (musl libc)"
      echo "  aarch64-android       - ARM64 Android"
      echo "  x86_64-android        - x86_64 Android"
      echo "  arm-android           - ARM 32-bit Android"
      exit 0
      ;;
  esac
done

# 检查Zig是否安装
if ! command -v zig &> /dev/null; then
    echo "错误: 未找到Zig。请安装Zig: https://ziglang.org/download/"
    exit 1
fi

# 检查OpenSSL源码是否存在
if [ ! -d "$OPENSSL_DIR" ]; then
    echo "错误: 未找到OpenSSL源码目录: $OPENSSL_DIR"
    exit 1
fi

# 创建构建和安装目录
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

# 设置Zig CC环境变量
export CC="zig cc -target $TARGET"
export CXX="zig c++ -target $TARGET"
export AR="zig ar"
export RANLIB="zig ranlib"

# 根据目标架构确定OpenSSL配置参数
OPENSSL_TARGET=""
case $TARGET in
  x86_64-linux-*)
    OPENSSL_TARGET="linux-x86_64"
    ;;
  aarch64-linux-*)
    OPENSSL_TARGET="linux-aarch64"
    ;;
  riscv64-linux-*)
    OPENSSL_TARGET="linux64-riscv64"
    ;;
  arm-linux-*)
    OPENSSL_TARGET="linux-armv4"
    ;;
  aarch64-android)
    OPENSSL_TARGET="android-arm64"
    ;;
  x86_64-android)
    OPENSSL_TARGET="android-x86_64"
    ;;
  arm-android)
    OPENSSL_TARGET="android-arm"
    ;;
  *)
    echo "警告: 未知目标架构 $TARGET，尝试使用通用配置"
    OPENSSL_TARGET="linux-generic64"
    ;;
esac

echo "=== 开始为 $TARGET 构建 OpenSSL 3.4.1 ==="
echo "源码目录: $OPENSSL_DIR"
echo "构建目录: $BUILD_DIR"
echo "安装目录: $INSTALL_DIR"
echo "OpenSSL目标: $OPENSSL_TARGET"

# 进入OpenSSL源码目录
cd "$OPENSSL_DIR"

# 清理之前的构建
make clean || true

# 配置OpenSSL
echo "配置OpenSSL..."
./Configure \
  --prefix="$INSTALL_DIR" \
  --openssldir="$INSTALL_DIR/ssl" \
  --libdir=lib \
  no-shared \
  no-tests \
  no-apps \
  "$OPENSSL_TARGET"

# 编译OpenSSL
echo "编译OpenSSL..."
make -j$(nproc)

# 安装OpenSSL
echo "安装OpenSSL..."
make install_sw

echo "=== OpenSSL 3.4.1 构建完成 ==="
echo "安装目录: $INSTALL_DIR"
echo "库文件位置: $INSTALL_DIR/lib"
echo "头文件位置: $INSTALL_DIR/include" 