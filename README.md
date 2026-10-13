# libavcodec-wasm

`avcdec.wasm` is FFmpeg's H.264 decoder, and nothing else of FFmpeg, compiled
to a WebAssembly (WASI reactor) module. [komarugram](https://github.com/komarugif/komarugram-go)
loads it to play H.264 video on machines without FFmpeg.

## Contents

| File | What |
|---|---|
| `avcdec.wasm` | The module |
| `avcdec.wasm.zst` | The same module, zstd-compressed (`zstd --ultra -22`): what komarugram downloads |
| `h264shim.c` | The only surface the host can call: send a sample, receive pictures, read their planes |
| `build.sh` | How `avcdec.wasm` and `avcdec.wasm.zst` are built |
| `ffmpeg` | FFmpeg's sources, tag `n7.1.1`, as a git submodule of https://github.com/FFmpeg/FFmpeg, unmodified |

## Building

```sh
git clone --recurse-submodules --shallow-submodules https://github.com/komarugif/libavcodec-wasm
cd libavcodec-wasm
WASI_SYSROOT=/path/to/wasi-sysroot RESOURCE_DIR=/path/to/resource-dir ./build.sh
```

See the head of `build.sh` for the toolchain.

## License

The module contains [FFmpeg](https://ffmpeg.org) 7.1.1 (libavcodec and
libavutil), configured without `--enable-gpl`, `--enable-version3` or
`--enable-nonfree`, and is licensed under the GNU Lesser General Public
License, version 2.1 or later: see `COPYING.LGPLv2.1`. `h264shim.c` is under
the same license.

It also links WASI libc from [wasi-sdk](https://github.com/WebAssembly/wasi-sdk)
(musl and wasi-libc's own code) and the compiler-rt builtins of LLVM; their
notices are in `licenses/wasi-libc`.
