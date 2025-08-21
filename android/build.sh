#!/bin/bash

set -e

. tools/common.sh || exit 1

[ -z "$OUT_DIR" ] && OUT_DIR=$PWD/out

# Android needs the NDK
[ -z "$ANDROID_NDK_ROOT" ] && echo "You must supply the ANDROID_NDK_ROOT environment variable." && exit 1
[ -z "$ARCH" ] && ARCH=arm64-v8a
[ -z "$BUILD_DIR" ] && BUILD_DIR=build
[ -z "$ANDROID_API" ] && ANDROID_API=23

build() {
    echo "Building..."

    export PATH="$ANDROID_NDK_ROOT:$PATH"

    declare hosts=("linux-x86_64" "linux-x86" "darwin-x86_64" "darwin-x86" "windows-x86_64")
    for host in "${hosts[@]}"; do
        if [ -d "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin" ]; then
            ANDROID_TOOLCHAIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host/bin"
            export PATH="$ANDROID_TOOLCHAIN:$PATH"
            break
        fi
    done

    sed -i "s/armeabi-v7a arm64-v8a x86 x86_64/$ARCH/" build-scripts/androidbuildlibs.sh
    sed -i 's/SDL2 SDL2_main/SDL2 SDL2_static/' build-scripts/androidbuildlibs.sh
    sed -i "s/android-16/android-$ANDROID_API/" build-scripts/androidbuildlibs.sh
    build-scripts/androidbuildlibs.sh -j$(nproc)
}

strip_libs() {
    # Change to match your library's names
    find . -name "*.so" -exec llvm-strip --strip-all {} \;
}

copy_build_artifacts() {
    mkdir "$OUT_DIR"/{lib,include}
    cp build/android/obj/local/$ARCH/libSDL2* "$OUT_DIR"/lib
    cp include/*.h "$OUT_DIR"/include
}

copy_cmake() {
    cp $ROOTDIR/CMakeLists.txt "$OUT_DIR"
    cp $ROOTDIR/unix/sdl2.cmake "$OUT_DIR"
}

package() {
    echo "Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=$FILENAME-android-$VERSION.tar

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

# You can change this for e.g. CMake
extract

pushd "$FILENAME-$VERSION-$ARCH"

# Delete existing build artifacts
rm -fr "$OUT_DIR"
mkdir -p "$OUT_DIR" || exit 1

build
strip_libs
copy_build_artifacts

copy_cmake
package

popd
popd
