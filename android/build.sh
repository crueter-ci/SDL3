#!/bin/bash -e

# shellcheck disable=SC1091
. tools/common.sh

[ -z "$ANDROID_NDK_ROOT" ] && echo "You must supply the ANDROID_NDK_ROOT environment variable." && exit 1
OUT_DIR=${OUT_DIR:-"$PWD/out"}
ARCH=${ARCH:-arm64-v8a}
BUILD_DIR=${BUILD_DIR:-"$PWD/build"}
ANDROID_API=${ANDROID_API:-23}

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

    sed -i 's/SDL3/SDL3 SDL3_static/' build-scripts/androidbuildlibs.sh
    build-scripts/androidbuildlibs.sh -j"$(nproc)" APP_PLATFORM="$ANDROID_API" APP_ABI="$ARCH"
}

strip_libs() {
    find . -name "*.so" -exec llvm-strip --strip-all {} \;
}

copy_build_artifacts() {
    mkdir "$OUT_DIR"/{lib,include}
    cp build/android/obj/local/"$ARCH"/libSDL3* "$OUT_DIR"/lib
    cp -r include/SDL3 "$OUT_DIR"/include
}

copy_cmake() {
    cp "$ROOTDIR"/CMakeLists.txt "$OUT_DIR"
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

extract

pushd "$FILENAME-$VERSION-$ARCH"

rm -fr "$OUT_DIR"
mkdir -p "$OUT_DIR" || exit 1

build
strip_libs
copy_build_artifacts

copy_cmake
package

popd
popd
