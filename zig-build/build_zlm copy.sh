#!/bin/bash
# 使用Zig进行riscv64交叉编译的需要安装 apt gcc-riscv64-linux-gnu libc6-dev-riscv64-cross
# 1) cmake 命令添加  -DCMAKE_CXX_FLAGS="-I/usr/riscv64-linux-gnu/include/gnu/" 
# 2) include_directories(/usr/riscv64-linux-gnu/include/gnu/)
# 3) 代码修改 __DATE__  改为 build_date_disabled
# args["build_date"] = "build_date_disabled";
# const char kServerName[] =  "ZLMediaKit-8.0(build in "build_date_disabled" " __TIME__ ")";


# 出错时退出
set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 默认目标架构
TARGET="x86_64-linux-gnu"
# 默认不编译webrtc
ENABLE_WEBRTC=false

# 解析命令行参数
for arg in "$@"; do
  case $arg in
    --target=*)
      TARGET="${arg#*=}"
      shift
      ;;
    --enable-webrtc)
      ENABLE_WEBRTC=true
      shift
      ;;
    --help)
      echo "用法: $0 [选项]"
      echo "选项:"
      echo "  --target=<目标>    指定目标架构 (默认: x86_64-linux-gnu)"
      echo "  --enable-webrtc    启用WebRTC支持 (默认: 禁用)"
      echo "  --help             显示此帮助信息"
      echo ""
      echo "支持的目标架构示例:"
      echo "  x86_64-linux-gnu      - x86_64 Linux (GNU libc)"
      echo "  aarch64-linux-gnu     - ARM64 Linux (GNU libc)"
      echo "  aarch64-linux-android     - ARM64 Android"
      echo "  arm-linux-android         - ARM 32-bit Android"      
      echo "  x86_64-windows-gnu    - x86_64 Windows (MinGW)"
      echo "  x86_64-macos          - x86_64 macOS"
      echo "  aarch64-macos         - ARM64 macOS"
      exit 0
      ;;
  esac
done

# 检查Zig是否安装
if ! command -v zig &> /dev/null; then
    echo "错误: 未找到Zig。请安装Zig: https://ziglang.org/download/"
    exit 1
fi

# 检查CMake是否安装
if ! command -v cmake &> /dev/null; then
    echo "错误: 未找到CMake。请安装CMake: https://cmake.org/download/"
    exit 1
fi

# 检查OpenSSL依赖，如果不存在则自动构建
OPENSSL_INSTALL_DIR="$SCRIPT_DIR/install/openssl/${TARGET}"
if [[ ! -d "$OPENSSL_INSTALL_DIR" || -z "$(ls -A $OPENSSL_INSTALL_DIR)"  ]]; then
    echo "警告: 未找到OpenSSL安装目录: $OPENSSL_INSTALL_DIR"
    echo "自动执行构建OpenSSL脚本..."
    
    # 保存当前目录
    CURRENT_DIR=$(pwd)
    
    # 执行构建OpenSSL脚本
    cd "$SCRIPT_DIR"
    bash "$SCRIPT_DIR/build_openssl.sh" "--target=$TARGET"
    
    # 检查构建结果
    if [ ! -d "$OPENSSL_INSTALL_DIR" ]; then
        echo "错误: OpenSSL构建失败，目录仍不存在: $OPENSSL_INSTALL_DIR"
        exit 1
    fi
    
    # 返回原目录
    cd "$CURRENT_DIR"
    
    echo "OpenSSL构建成功!"
fi

# 如果启用了WebRTC，检查libsrtp依赖，如果不存在则自动构建
if [ "$ENABLE_WEBRTC" = true ]; then
    LIBSRTP_INSTALL_DIR="$SCRIPT_DIR/install/libsrtp/${TARGET}"
    if [[ ! -d "$LIBSRTP_INSTALL_DIR" || -z "$(ls -A $LIBSRTP_INSTALL_DIR)" ]]; then
        echo "警告: 未找到libsrtp安装目录: $LIBSRTP_INSTALL_DIR"
        echo "自动执行构建libsrtp脚本..."
        
        # 保存当前目录
        CURRENT_DIR=$(pwd)
        
        # 执行构建libsrtp脚本
        cd "$SCRIPT_DIR"
        bash "$SCRIPT_DIR/build_libsrtp.sh" "--target=$TARGET"
        
        # 检查构建结果
        if [ ! -d "$LIBSRTP_INSTALL_DIR" ]; then
            echo "错误: libsrtp构建失败，目录仍不存在: $LIBSRTP_INSTALL_DIR"
            exit 1
        fi
        
        # 返回原目录
        cd "$CURRENT_DIR"
        
        echo "libsrtp构建成功!"
    fi
fi

# 创建临时工具链文件
TOOLCHAIN_FILE="zig-build/zig-toolchain-${TARGET}.cmake"

# 加载Android环境变量（如果是Android目标）
if [[ "$TARGET" == *"-linux-android"* ]]; then
    source ./zig-build/build_android_env.sh
fi

# 生成CMake工具链文件
cat > "${TOOLCHAIN_FILE}" << EOT
# 自动生成的工具链文件 - 目标: ${TARGET}

# 根据目标设置系统名称
if ("\${TARGET}" MATCHES ".*-windows-.*")
  set(CMAKE_SYSTEM_NAME Windows)
elseif ("\${TARGET}" MATCHES ".*-macos.*")
  set(CMAKE_SYSTEM_NAME Darwin)
elseif ("\${TARGET}" MATCHES ".*-android.*")
  set(CMAKE_SYSTEM_NAME Android)
  set(CMAKE_SYSTEM_VERSION 21)
else()
  set(CMAKE_SYSTEM_NAME Linux)
endif()

# 设置处理器架构
if ("\${TARGET}" MATCHES "aarch64-.*")
  set(CMAKE_SYSTEM_PROCESSOR aarch64)
elseif ("\${TARGET}" MATCHES "x86_64-.*")
  set(CMAKE_SYSTEM_PROCESSOR x86_64)
elseif ("\${TARGET}" MATCHES "arm-.*")
  set(CMAKE_SYSTEM_PROCESSOR arm)
else()
  string(REGEX REPLACE "-.*$" "" CMAKE_SYSTEM_PROCESSOR "\${TARGET}")
endif()

# 指定编译器
if ("\${TARGET}" MATCHES ".*-android.*")
  # 使用Android NDK编译器
  set(CMAKE_C_COMPILER "$TOOLCHAIN/bin/\${CMAKE_SYSTEM_PROCESSOR}-linux-android$MIN_SDK_VERSION-clang")
  set(CMAKE_CXX_COMPILER "$TOOLCHAIN/bin/\${CMAKE_SYSTEM_PROCESSOR}-linux-android$MIN_SDK_VERSION-clang++")
  
  # 设置Android特定变量
  set(CMAKE_FIND_ROOT_PATH "$TOOLCHAIN/sysroot")
  set(CMAKE_ANDROID_NDK "$ANDROID_NDK_ROOT")
  set(CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION clang)
  set(CMAKE_ANDROID_STL_TYPE c++_shared)
  set(CMAKE_ANDROID_API $MIN_SDK_VERSION)
else
  # 使用Zig编译器
  set(CMAKE_C_COMPILER zig cc)
  set(CMAKE_CXX_COMPILER zig c++)
  
  # 设置交叉编译目标
  set(ZIG_TARGET_TRIPLE "${TARGET}")
  set(CMAKE_C_COMPILER_TARGET \${ZIG_TARGET_TRIPLE})
  set(CMAKE_CXX_COMPILER_TARGET \${ZIG_TARGET_TRIPLE})
endif()

# 添加ReleaseSmall构建类型
set(CMAKE_CXX_FLAGS_RELEASESMALL "-Oz -DNDEBUG" CACHE STRING "Flags used by the CXX compiler during ReleaseSmall builds." FORCE)
set(CMAKE_C_FLAGS_RELEASESMALL "-Oz -DNDEBUG" CACHE STRING "Flags used by the C compiler during ReleaseSmall builds." FORCE)
set(CMAKE_EXE_LINKER_FLAGS_RELEASESMALL "-Wl,--gc-sections -Wl,-s" CACHE STRING "Flags used for linking binaries during ReleaseSmall builds." FORCE)
set(CMAKE_SHARED_LINKER_FLAGS_RELEASESMALL "-Wl,--gc-sections -Wl,-s" CACHE STRING "Flags used for linking shared libraries during ReleaseSmall builds." FORCE)
set(CMAKE_MODULE_LINKER_FLAGS_RELEASESMALL "-Wl,--gc-sections -Wl,-s" CACHE STRING "Flags used for linking modules during ReleaseSmall builds." FORCE)

# 配置根路径模式
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# 禁用编译器检查
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)
EOT

# source ./zig-build/build_android_env.sh
# 创建并进入构建目录
BUILD_DIR="zig-build/build"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 使用Zig工具链配置CMake项目
echo "配置项目使用Zig作为交叉编译器，目标: ${TARGET}..."

# 基本CMake参数
CMAKE_ARGS=(
    -DDISABLE_REPORT=ON
    -DUSE_SOLUTION_FOLDERS=OFF
    -DOPENSSL_ROOT_DIR="$SCRIPT_DIR/install/openssl/${TARGET}/"
    -DOPENSSL_LIBRARIES="$SCRIPT_DIR/install/openssl/${TARGET}/lib/"
    -DEXECUTABLE_OUTPUT_PATH="$SCRIPT_DIR/install/ZLMediaKit/${TARGET}"
    -DCMAKE_BUILD_TYPE=ReleaseSmall
)

# 根据是否启用WebRTC添加相应参数
if [ "$ENABLE_WEBRTC" = true ]; then
    echo "启用WebRTC支持..."
    CMAKE_ARGS+=(
        -DENABLE_WEBRTC=ON
        -DENABLE_SCTP=ON
        -DSRTP_INCLUDE_DIRS="$SCRIPT_DIR/install/libsrtp/${TARGET}/include/"
        -DSRTP_LIBRARIES="$SCRIPT_DIR/install/libsrtp/${TARGET}/lib/libsrtp2.a"
    )
else
    echo "禁用WebRTC支持..."
    CMAKE_ARGS+=(
        -DENABLE_WEBRTC=OFF
        -DENABLE_SCTP=OFF
    )
fi

# 如果是Android目标，添加Android特定参数
if [[ "$TARGET" == *"-linux-android"* ]]; then
    echo "配置Android特定参数..."
    CMAKE_ARGS+=(
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake"
        -DANDROID_ABI=arm64-v8a
        -DANDROID_PLATFORM=android-$MIN_SDK_VERSION
        -DANDROID_STL=c++_shared
        -DCMAKE_CXX_FLAGS="-DHAVE_MMSG_HDR -DHAVE_SENDMMSG_API -DHAVE_RECVMMSG_API"
        -DCMAKE_C_FLAGS="-DHAVE_MMSG_HDR -DHAVE_SENDMMSG_API -DHAVE_RECVMMSG_API"
    )
else
    CMAKE_ARGS+=(
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}"
    )
fi

# 执行CMake配置
cmake ../.. "${CMAKE_ARGS[@]}"

# 编译项目 --parallel
echo "编译项目..."
cmake --build .

echo "交叉编译完成！目标架构: ${TARGET}"
echo "WebRTC支持: $([ "$ENABLE_WEBRTC" = true ] && echo "已启用" || echo "已禁用")"
