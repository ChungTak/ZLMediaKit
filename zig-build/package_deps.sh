# Build and Package All Targets
# 定义目标列表
targets=("x86_64-linux-gnu" "aarch64-linux-gnu" "aarch64-linux-android" "arm-linux-android" "riscv64-linux-gnu" "x86_64-windows-gnu")
chmod +x ./zig-build/*.sh

rm -rf zig-build/artifacts
mkdir -p zig-build/artifacts

# 循环处理每个目标
for target in "${targets[@]}"; do
    echo "==============================="
    echo "Building target: $target"
    echo "==============================="


    # 确定输出目录
    openssl_output_dir="zig-build/install/openssl/"
    libsrtp_output_dir="zig-build/install/libsrtp/"

    # 处理产物
    if [ -d "$openssl_output_dir" ]; then
        artifact_name="openssl-3.0.16-${target}"
        tar -czvf "zig-build/artifacts/${artifact_name}.tar.gz" -C "$openssl_output_dir" "$target"
    else
        echo "::error::Output directory $openssl_output_dir not found for $target!"
        exit 1
    fi

    if [ -d "$libsrtp_output_dir" ]; then
        artifact_name="libsrtp-2.4.2-${target}"
        mkdir -p zig-build/artifacts
        tar -czvf "zig-build/artifacts/${artifact_name}.tar.gz" -C "$libsrtp_output_dir" "$target"
    else
        echo "::error::Output directory $libsrtp_output_dir not found for $target!"
        exit 1
    fi
done