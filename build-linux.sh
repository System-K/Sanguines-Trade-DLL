#!/bin/sh
# SKSE-Hotfixes Linux cross build (clang-cl + xwin) against CommonLibSSE-NG 11 (Address Library v5, Skyrim 1.7.104).
set -e
T=/mnt/h/dev/modding/toolchain
export PATH="$T/bin:$PATH" VCPKG_ROOT="$T/vcpkg" COMMONLIB_SSE_FOLDER="$T/commonlibsse-ng"
cmake -S . -B build/linux -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_MAKE_PROGRAM=/usr/bin/ninja \
  -DCMAKE_TOOLCHAIN_FILE="$T/vcpkg/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="$T/clang-cl-xwin.cmake" \
  -DVCPKG_TARGET_TRIPLET=x64-windows-static-xwin -DVCPKG_OVERLAY_TRIPLETS="$T/triplets" \
  -DVCPKG_OVERLAY_PORTS="$T/ports" -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded \
  -DXWIN_EXTRA_CXX_FLAGS="/permissive- /Zc:preprocessor -DNOMINMAX -DUNICODE -D_UNICODE -D_WIN32_WINNT=0x0A00" \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF -DBUILD_TESTS=OFF
cmake --build build/linux -j16
