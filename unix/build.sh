#!/bin/bash -e

set -e

# shellcheck disable=SC1091
. tools/common.sh || exit 1

OUT_DIR=${OUT_DIR:-$PWD/out}
ARCH=${ARCH:-amd64}
BUILD_DIR=${BUILD_DIR:-build}
PLATFORM=${PLATFORM:-linux}

[ "$PLATFORM" = "freebsd" ] && EXTRA_CMAKE_FLAGS=(-DSDL_ALSA=OFF -DSDL_PULSEAUDIO=OFF -DSDL_OSS=ON -DSDL_X11=ON -DTHREADS_PREFER_PTHREAD_FLAG=ON)
[ "$PLATFORM" = "openbsd" ] && EXTRA_CMAKE_FLAGS=(-DCMAKE_C_FLAGS="-L/usr/local/lib")
[ "$PLATFORM" = "solaris" ] && export PKG_CONFIG_PATH=/usr/lib/64/pkgconfig && EXTRA_CMAKE_FLAGS=(-DSDL_HIDAPI=OFF)
[ "$PLATFORM" != "linux" ] && EXTRA_CMAKE_FLAGS+=(-DSDL_IBUS=OFF -DSDL_WAYLAND=OFF -DSDL_PIPEWIRE=OFF -DSDL_ALSA=OFF -DSDL_LIBUDEV=OFF -DSDL_DBUS=OFF)

configure() {
	echo "-- Configuring..."
    # thanks solaris
    sed 's/LINUX OR FREEBSD/LINUX/' CMakeLists.txt > cmake.tmp && mv cmake.tmp CMakeLists.txt

    cmake -S . -B "$BUILD_DIR" \
        -DSDL_WERROR=OFF \
        -DSDL_TEST_LIBRARY=OFF \
        -DSDL_VENDOR_INFO="crueter's CI" \
        -DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DSDL_SHARED=ON \
        -DSDL_STATIC=ON \
        -G "Ninja" \
        -DCMAKE_BUILD_TYPE=Release \
        "${EXTRA_CMAKE_FLAGS[@]}"
}

build() {
    echo "-- Building..."

    cmake --build "$BUILD_DIR" --config Release --parallel
}

strip_libs() {
    find "$OUT_DIR" -name "*.so" -exec strip {} \;
}

copy_build_artifacts() {
    echo "-- Copying artifacts..."
    cmake --install "$BUILD_DIR"

    echo "-- Cleaning..."
    rm -rf "${OUT_DIR:?}/bin"
    rm -rf "$OUT_DIR"/lib/cmake
    rm -rf "$OUT_DIR"/lib/pkgconfig
    rm -rf "$OUT_DIR"/share
    find "$OUT_DIR/lib" -type l -exec rm {} \;
    mv "$OUT_DIR/lib"/*.so* "$OUT_DIR/lib/libSDL3.so"
}

copy_cmake() {
    cp "$ROOTDIR"/CMakeLists.txt "$OUT_DIR"
}

package() {
    echo "-- Packaging..."
    mkdir -p "$ROOTDIR/artifacts"

    TARBALL=$FILENAME-$PLATFORM-$ARCH-$VERSION.tar

    cd "$OUT_DIR"
    tar cf "$ROOTDIR"/artifacts/"$TARBALL" *

    cd "$ROOTDIR/artifacts"
    zstd -10 "$TARBALL"
    rm "$TARBALL"

    "$ROOTDIR"/tools/sums.sh "$TARBALL".zst
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

popd >/dev/null
popd >/dev/null
