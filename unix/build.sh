#!/bin/bash -e

. tools/common.sh || exit 1

[ -z "$OUT_DIR" ] && OUT_DIR=$PWD/out
[ -z "$ARCH" ] && ARCH=amd64
[ -z "$BUILD_DIR" ] && BUILD_DIR=build
[ -z "$PLATFORM" ] && PLATFORM=linux

[ "$PLATFORM" == "freebsd" ] && EXTRA_CMAKE_FLAGS=(-DSDL_ALSA=OFF -DSDL_PULSEAUDIO=OFF -DSDL_PIPEWIRE=OFF -DSDL_DBUS=OFF -DSDL_LIBUDEV=OFF -DSDL_OSS=ON -DSDL_X11=ON -DSDL_WAYLAND=OFF -DTHREADS_PREFER_PTHREAD_FLAG=ON)
[ "$PLATFORM" == "solaris" ] && export PKG_CONFIG_PATH=/usr/lib/64/pkgconfig

[ "$PLATFORM" != "linux" ] && EXTRA_CMAKE_FLAGS=("${EXTRA_CMAKE_FLAGS[@]}" -DSDL_IBUS=OFF)

[ "$ARCH" != "amd64" ] && PLATFORM=$PLATFORM-$ARCH

configure() {
    log_file=$1

    cmake -S . -B "$BUILD_DIR" \
        -DSDL_WERROR=OFF \
        -DSDL_TEST=OFF \
        -DSDL_VENDOR_INFO="crueter's CI" \
        -DSDL2_DISABLE_INSTALL=OFF \
        -DSDL2_DISABLE_SDL2MAIN=ON \
        -DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DSDL_SHARED=ON \
        -DSDL_STATIC=ON \
        -G "Ninja" \
        -DCMAKE_BUILD_TYPE=Release \
        "${EXTRA_CMAKE_FLAGS[@]}"
}

build() {
    echo "Building..."

    cmake --build $BUILD_DIR --config Release --parallel
}

strip_libs() {
    find "$OUT_DIR" -name "*.so" -exec strip {} \;
}

copy_build_artifacts() {
    echo "Copying artifacts..."
    cmake --install $BUILD_DIR

    echo "Cleaning..."
    rm -rf "$OUT_DIR/bin"
    rm -rf "$OUT_DIR"/lib/cmake
    rm -rf "$OUT_DIR"/lib/pkgconfig
    rm -rf "$OUT_DIR"/libdata
    rm -rf "$OUT_DIR"/share
    find "$OUT_DIR/lib" -type l -exec rm {} \;
    mv "$OUT_DIR/lib"/*.so* "$OUT_DIR/lib/libSDL2.so"
}

copy_cmake() {
    cp $ROOTDIR/CMakeLists.txt "$OUT_DIR"
    cp $ROOTDIR/unix/sdl2.cmake "$OUT_DIR"
}

package() {
    echo "Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=$FILENAME-$PLATFORM-$VERSION.tar

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

strip_libs

package

echo "Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"

popd
popd
