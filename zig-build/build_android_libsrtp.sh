#!/bin/bash

source ./zig-build/build_android_env.sh

TARGET="x86_64-linux-gnu"
LIBSRTP_DIR="$(pwd)/3rdpart/libsrtp"
INSTALL_DIR="$(pwd)/zig-build/install/libsrtp/${TARGET}"

# 解析命令行参数
for arg in "$@"; do
  case $arg in
    --target=*)
      TARGET="${arg#*=}"
      INSTALL_DIR="$(pwd)/zig-build/install/libsrtp/${TARGET}"
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
      echo "  aarch64-linux-gnu     - ARM64 Linux (GNU libc)"
      echo "  aarch64-linux-android     - ARM64 Android"
      echo "  arm-linux-android         - ARM 32-bit Android"      
      echo "  riscv64-linux-gnu     - RISC-V 64-bit Linux (GNU libc)"   
      echo "  x86_64-windows-gnu    - x86_64 Windows (MinGW)"
      echo "  x86_64-macos          - x86_64 macOS"
      echo "  aarch64-macos         - ARM64 macOS"
      exit 0
      ;;
  esac
done


# 检查libsrtp源码是否存在
if [ ! -d "$LIBSRTP_DIR" ]; then
    echo "错误: 未找到libsrtp源码目录: $LIBSRTP_DIR"
    exit 1
fi

# 检查OpenSSL是否存在
OPENSSL_DIR="$(pwd)/zig-build/install/openssl/${TARGET}"
if [ ! -d "$OPENSSL_DIR" ]; then
    echo "错误: 未找到OpenSSL目录: $OPENSSL_DIR"
    echo "请先运行 build-openssl.sh --target=${TARGET} 编译OpenSSL"
    exit 1
fi

# 创建安装目录
if [ -d $INSTALL_DIR ]; then
    rm -rf $INSTALL_DIR
fi
mkdir -p $INSTALL_DIR

# 根据目标架构确定OpenSSL配置参数
LIBSRTP_TARGET=""
case $TARGET in
  x86_64-linux-gnu)
    LIBSRTP_TARGET="x86_64-pc-linux-gnu​"
    ;;
  aarch64-linux-gnu)
    LIBSRTP_TARGET="aarch64-unknown-linux-gnu​"
    ;;
  riscv64-linux-gnu)
    LIBSRTP_TARGET="riscv64-unknown-linux-gnu"
    ;;
  arm-linux-gnu)
    LIBSRTP_TARGET="arm-unknown-linux-gnueabihf"
    ;;
  x86_64-windows-gnu*)
    LIBSRTP_TARGET="x86_64-w64-mingw32"
    ;;
  x86_64-macos*)
    LIBSRTP_TARGET="x86_64-apple-darwin"
    ;;
  aarch64-macos*)
    LIBSRTP_TARGET="arm64-apple-darwin"
    ;;            
  aarch64-linux-android)
    LIBSRTP_TARGET="aarch64-unknown-linux-android"
    ;;
  x86_64-android)
    LIBSRTP_TARGET="x86_64-unknown-linux-android"
    ;;
  arm-linux-android)
    LIBSRTP_TARGET="arm-unknown-linux-androideabi"
    ;;
  *)
    echo "警告: 未知目标架构 $TARGET，尝试使用通用配置"
    LIBSRTP_TARGET="linux-generic64"
    ;;
esac

echo "=== 开始为 $TARGET 编译 libsrtp==="
echo "源码目录: $LIBSRTP_DIR"
echo "安装目录: $INSTALL_DIR"
echo "OpenSSL目录: $OPENSSL_DIR"
echo "LIBSRTP目标: $LIBSRTP_TARGET"

cd $LIBSRTP_DIR

# function build() {
TARGET_HOST=$TARGET
AR=$TOOLCHAIN/bin/llvm-ar
CC=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang
AS=$CC
CXX=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang++
LD=$TOOLCHAIN/bin/ld
RANLIB=$TOOLCHAIN/bin/llvm-ranlib
STRIP=$TOOLCHAIN/bin/llvm-strip

./configure \
--prefix="$INSTALL_DIR" --host=${LIBSRTP_TARGET} \
--enable-openssl  \
--with-openssl-dir="$OPENSSL_DIR"

make clean
make && make install
