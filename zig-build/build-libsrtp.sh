#!/bin/bash
# 使用zig-cc编译libsrtp_v2.4.2的脚本

# 出错时退出
set -e

# 默认目标架构
TARGET="x86_64-linux-gnu"
LIBSRTP_DIR="$(pwd)/../3rdpart/libsrtp"
INSTALL_DIR="$(pwd)/libsrtp-install-${TARGET}"

# 解析命令行参数
for arg in "$@"; do
  case $arg in
    --target=*)
      TARGET="${arg#*=}"
      INSTALL_DIR="$(pwd)/libsrtp-install-${TARGET}"
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

# 检查libsrtp源码是否存在
if [ ! -d "$LIBSRTP_DIR" ]; then
    echo "错误: 未找到libsrtp源码目录: $LIBSRTP_DIR"
    exit 1
fi

# 检查OpenSSL是否存在
OPENSSL_DIR="$(pwd)/openssl-install-${TARGET}"
if [ ! -d "$OPENSSL_DIR" ]; then
    echo "错误: 未找到OpenSSL目录: $OPENSSL_DIR"
    echo "请先运行 build-openssl.sh --target=${TARGET} 编译OpenSSL"
    exit 1
fi

# 创建安装目录
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# 设置Zig CC环境变量
export CC="zig cc -target $TARGET"
export CXX="zig c++ -target $TARGET"
export AR="zig ar"
export RANLIB="zig ranlib"

# 设置Android特定参数
if [[ "$TARGET" == *"-android"* ]]; then
    echo "配置Android特定参数..."
    export CFLAGS="-D__ANDROID_API__=21"
    export CXXFLAGS="-D__ANDROID_API__=21"
fi

echo "=== 开始为 $TARGET 编译 libsrtp v2.4.2 ==="
echo "源码目录: $LIBSRTP_DIR"
echo "安装目录: $INSTALL_DIR"
echo "OpenSSL目录: $OPENSSL_DIR"

# 进入libsrtp源码目录
cd "$LIBSRTP_DIR"

# 清理之前的构建
if [ -f "Makefile" ]; then
    make clean || true
fi

# 配置libsrtp，启用OpenSSL
echo "配置libsrtp..."
./configure \
  --prefix="$INSTALL_DIR" \
  --enable-openssl \
  --with-openssl-dir="$OPENSSL_DIR"

# 编译libsrtp（只编译库，不编译测试程序）
echo "编译libsrtp..."
# 查看Makefile中的目标，找到只编译库的目标
make -j$(nproc) libsrtp2.a

# 手动安装libsrtp
echo "安装libsrtp..."
mkdir -p "$INSTALL_DIR/include/srtp2"
mkdir -p "$INSTALL_DIR/lib/pkgconfig"

# 安装头文件
cp ./include/srtp.h "$INSTALL_DIR/include/srtp2/"
cp ./crypto/include/cipher.h "$INSTALL_DIR/include/srtp2/"
cp ./crypto/include/auth.h "$INSTALL_DIR/include/srtp2/"
cp ./crypto/include/crypto_types.h "$INSTALL_DIR/include/srtp2/"

# 安装库文件
cp libsrtp2.a "$INSTALL_DIR/lib/"

# 生成pkgconfig文件
cat > "$INSTALL_DIR/lib/pkgconfig/libsrtp2.pc" << EOT
prefix=${INSTALL_DIR}
exec_prefix=${INSTALL_DIR}
libdir=${INSTALL_DIR}/lib
includedir=${INSTALL_DIR}/include

Name: libsrtp2
Version: 2.4.2
Description: Library for SRTP (Secure Realtime Transport Protocol)

Libs: -L\${libdir} -lsrtp2
Libs.private: -L${OPENSSL_DIR}/lib -lcrypto -ldl -pthread 
Cflags: -I\${includedir}
EOT

echo "=== libsrtp v2.4.2 编译完成 ==="
echo "安装目录: $INSTALL_DIR"
echo "库文件位置: $INSTALL_DIR/lib"
echo "头文件位置: $INSTALL_DIR/include" 