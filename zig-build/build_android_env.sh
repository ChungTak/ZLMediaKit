#!/bin/bash

export ANDROID_NDK_ROOT=/home/runner/work/ZLMediaKit/ZLMediaKit/android-ndk

HOST_TAG=linux-x86_64

MIN_SDK_VERSION=21

TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$HOST_TAG

PATH=$TOOLCHAIN/bin:$PATH

BUILD_DIR=$PWD/build/