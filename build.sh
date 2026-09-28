#!/bin/sh
# Builds avcdec.wasm: FFmpeg's H.264 decoder, and nothing else of FFmpeg, as
# a WebAssembly reactor module.
#
# Needs clang with a wasm32 backend, wasm-ld, and the WASI sysroot plus the
# wasm32 compiler-rt builtins from https://github.com/WebAssembly/wasi-sdk
# (its "wasi-sysroot" and "libclang_rt" release assets are enough).
# FFmpeg's sources (n7.1.1) are the ffmpeg submodule:
#
#   git submodule update --init
#   WASI_SYSROOT=/path/to/wasi-sysroot RESOURCE_DIR=/path/to/resource-dir ./build.sh
#
# RESOURCE_DIR holds lib/wasm32-unknown-wasip1/libclang_rt.builtins.a.
#
# FFmpeg's fast paths are assembly, which WebAssembly cannot take, so this
# is its C with the compiler's own SIMD128: about 2.8 ms for a 512x512
# picture and 10 ms for 720x1280, several times native FFmpeg.
#
# The module is LGPL 2.1 or later, as FFmpeg configured this way is.
set -eu

: "${CLANG:=clang-22}"
: "${AR:=llvm-ar-22}"
: "${RANLIB:=llvm-ranlib-22}"
: "${NM:=llvm-nm-22}"
: "${WASI_SYSROOT:?set WASI_SYSROOT}"
: "${RESOURCE_DIR:?set RESOURCE_DIR}"

here=$(cd "$(dirname "$0")" && pwd)
: "${FFMPEG:=$here/ffmpeg}"
target="--target=wasm32-wasip1 --sysroot=$WASI_SYSROOT -resource-dir $RESOURCE_DIR"
build="$here/build"

mkdir -p "$build"
cd "$build"
"$FFMPEG/configure" --enable-cross-compile --target-os=none --arch=wasm32 \
  --cc="$CLANG" --ar="$AR" --ranlib="$RANLIB" --nm="$NM" \
  --extra-cflags="$target -O3 -msimd128" --extra-ldflags="$target" \
  --disable-everything --enable-decoder=h264 \
  --disable-programs --disable-doc --disable-asm --disable-inline-asm \
  --disable-pthreads --disable-w32threads --disable-os2threads \
  --disable-network --disable-avdevice --disable-avformat --disable-swresample \
  --disable-swscale --disable-avfilter --disable-debug \
  --disable-runtime-cpudetect --disable-autodetect \
  --enable-static --disable-shared
make -j"$(nproc)"

# The shim is the only surface the host can reach. libavutil reads the
# process clock, which WASI has as an emulation.
"$CLANG" $target -O3 -msimd128 -mexec-model=reactor -D_WASI_EMULATED_PROCESS_CLOCKS \
  -I"$FFMPEG" -I"$build" \
  "$here/h264shim.c" "$build/libavcodec/libavcodec.a" "$build/libavutil/libavutil.a" \
  -lwasi-emulated-process-clocks \
  -o "$here/avcdec.wasm"

echo "built $here/avcdec.wasm"
