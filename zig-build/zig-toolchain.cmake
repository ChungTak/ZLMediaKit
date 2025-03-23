# 设置CMake工具链文件，使用Zig作为C/C++编译器
# 此文件配置CMake使用Zig作为交叉编译工具链

# 系统名称和处理器架构
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# 指定Zig作为C/C++编译器
set(CMAKE_C_COMPILER zig cc)
set(CMAKE_CXX_COMPILER zig c++)

# 设置交叉编译目标
set(ZIG_TARGET_TRIPLE "x86_64-linux-gnu")
set(CMAKE_C_COMPILER_TARGET ${ZIG_TARGET_TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${ZIG_TARGET_TRIPLE})

# 添加ReleaseSmall构建类型
set(CMAKE_CXX_FLAGS_RELEASESMALL "-Oz -DNDEBUG  -flto  -ffunction-sections -fdata-sections" CACHE STRING "Flags used by the CXX compiler during ReleaseSmall builds." FORCE)
set(CMAKE_C_FLAGS_RELEASESMALL "-Oz -DNDEBUG  -flto  -ffunction-sections -fdata-sections" CACHE STRING "Flags used by the C compiler during ReleaseSmall builds." FORCE)
set(CMAKE_EXE_LINKER_FLAGS_RELEASESMALL "-Wl,--gc-sections -Wl,-s" CACHE STRING "Flags used for linking binaries during ReleaseSmall builds." FORCE)
set(CMAKE_SHARED_LINKER_FLAGS_RELEASESMALL "-Wl,--gc-sections -Wl,-s" CACHE STRING "Flags used for linking shared libraries during ReleaseSmall builds." FORCE)
set(CMAKE_MODULE_LINKER_FLAGS_RELEASESMALL "-Wl,--gc-sections -Wl,-s" CACHE STRING "Flags used for linking modules during ReleaseSmall builds." FORCE)

# 符号可见性设置
cmake_policy(SET CMP0063 NEW)
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

# 设置Zig作为archiver和ranlib工具
# set(CMAKE_AR "zig ar")
# set(CMAKE_RANLIB "zig ranlib")

# 配置根路径模式
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# 禁用编译器检查
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE) 

