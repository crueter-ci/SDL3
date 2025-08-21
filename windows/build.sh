#!/bin/bash

set -e

. tools/common.sh || exit 1

[ -z "$OUT_DIR" ] && OUT_DIR="$PWD/out"
[ -z "$ARCH" ] && ARCH=amd64
[ -z "$BUILD_DIR" ] && BUILD_DIR="$PWD/build"

configure() {
    # Configure here (e.g. cmake or the like)
    echo "Configuring $PRETTY_NAME..."

    # case "$ARCH" in
    #     (x86)
    #         TARGET="Win32"
    #         ;;
    #     (amd64|x64|x86_64)
    #         TARGET="x64"
    #         ;;
    #     (aarch64|arm|arm64)
    #         TARGET="ARM64"
    #         ;;
    # esac

    cmake -S . -B "$BUILD_DIR" \
        -DSDL_WERROR=OFF \
        -DSDL_TEST=OFF \
        -DSDL2_DISABLE_SDL2MAIN=ON \
        -DSDL_VENDOR_INFO="crueter's CI" \
        -DSDL2_DISABLE_INSTALL=OFF \
        -DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
        -DSDL_SHARED=ON \
        -DSDL_STATIC=ON \
        -G "Ninja" \
        -DCMAKE_BUILD_TYPE=Release
}

build() {
    echo "Building..."

    cmake --build $BUILD_DIR --config Release --parallel
}

copy_build_artifacts() {
    echo "Copying artifacts..."
    cmake --install $BUILD_DIR

    pushd "$OUT_DIR"
    rm -r lib/pkgconfig
    mv bin/SDL2.dll lib/libSDL2.dll

    if ! command -v clang-cl >/dev/null 2>&1
    then
        rm -r lib/cmake
        mv lib/libSDL2.a lib/libSDL2_static.lib
        mv lib/libSDL2.dll.a lib/libSDL2.lib
        rm -r bin
    else
        rm -r cmake
        mv lib/SDL2.lib lib/libSDL2.lib
        mv lib/SDL2-static.lib lib/libSDL2_static.lib
        rm -r bin
    fi

    popd
}

copy_cmake() {
    cp $ROOTDIR/CMakeLists.txt "$OUT_DIR"
    cp $ROOTDIR/windows/sdl2.cmake "$OUT_DIR"
}

package() {
    echo "Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=$FILENAME-windows-$ARCH-$VERSION.tar

    cd "$OUT_DIR"
    tar cf $ROOTDIR/artifacts/$TARBALL *

    cd "$ROOTDIR/artifacts"
    zstd -10 $TARBALL
    rm $TARBALL

    $ROOTDIR/tools/sums.sh $TARBALL.zst
}

ROOTDIR=$PWD

./tools/download.sh

[[ -e "$BUILD_DIR" ]] && rm -fr "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR"

extract

pushd "$FILENAME-$VERSION-$ARCH"

configure

# Delete existing build artifacts
rm -fr "$OUT_DIR"
mkdir -p "$OUT_DIR" || exit 1

build
copy_build_artifacts
copy_cmake

package

echo "Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"

popd
popd
