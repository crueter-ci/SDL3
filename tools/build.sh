#!/bin/bash -e

set -e

# shellcheck disable=SC1091

. tools/common.sh

## Buildtime/Input Variables ##

android() {
	[ "$PLATFORM" = android ]
}

ROOTDIR="$PWD"
if android; then
	: "${ANDROID_NDK_ROOT:?-- You must supply the ANDROID_NDK_ROOT environment variable.}"
	: "${ANDROID_API:=23}"
	DEFAULT_ARCH=aarch64
else
	DEFAULT_ARCH=amd64
fi

: "${PLATFORM:?-- You must supply the PLATFORM environment variable.}"
: "${ARCH:=$DEFAULT_ARCH}"
: "${OUT_DIR:=$PWD/out}"
: "${BUILD_DIR:=build}"

if android; then
	case "$ARCH" in
		aarch64) ABI=arm64-v8a ;;
		x86_64) ABI=x86_64 ;;
	esac
fi

## Platform Stuff ##

case "$PLATFORM" in
	freebsd) EXTRA_CMAKE_FLAGS=(-DSDL_ALSA=OFF -DSDL_PULSEAUDIO=OFF -DSDL_OSS=ON -DSDL_X11=ON -DTHREADS_PREFER_PTHREAD_FLAG=ON) ;;
	openbsd) EXTRA_CMAKE_FLAGS=(-DCMAKE_C_FLAGS="-L/usr/local/lib") ;;
	solaris)
		export PKG_CONFIG_PATH=/usr/lib/64/pkgconfig
		EXTRA_CMAKE_FLAGS=(-DSDL_HIDAPI=OFF) ;;
	macos) EXTRA_CMAKE_FLAGS=(-DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0) ;;
esac

case "$PLATFORM" in
	linux|macos) EXTRA_CMAKE_FLAGS+=(-DCMAKE_INSTALL_LIBDIR=lib) ;;
	ios)
		: "${IOS_TARGET:=iphoneos}"
		EXTRA_CMAKE_FLAGS+=(
			-DCMAKE_INSTALL_LIBDIR=lib
			-DCMAKE_SYSTEM_NAME=iOS
			-DCMAKE_OSX_SYSROOT="$IOS_TARGET"
			-DCMAKE_OSX_DEPLOYMENT_TARGET=16.0)
			;;
	windows | mingw) ;;
	*) EXTRA_CMAKE_FLAGS+=(-DCMAKE_INSTALL_LIBDIR=lib -DSDL_IBUS=OFF -DSDL_WAYLAND=OFF -DSDL_PIPEWIRE=OFF -DSDL_ALSA=OFF -DSDL_LIBUDEV=OFF -DSDL_DBUS=OFF) ;;
esac

## Build Functions ##

# cmake
configure() {
	[ "$PLATFORM" = android ] && return

	echo "-- Configuring..."

	cmake -S . -B "$BUILD_DIR" \
		-DSDL_WERROR=OFF \
		-DSDL_TEST_LIBRARY=OFF \
		-DSDL_VENDOR_INFO="crueter's CI" \
		-DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
		-DSDL_SHARED=ON \
		-DSDL_STATIC=ON \
		-DSDL_X11_XTEST=OFF \
		-G "Ninja" \
		-DCMAKE_BUILD_TYPE=Release \
		"${EXTRA_CMAKE_FLAGS[@]}"
}

build() {
	echo "-- Building..."

	if android; then
		export PATH="$ANDROID_NDK_ROOT:$PATH"

		android_paths

		sed -i 's/SDL3/SDL3 SDL3_static/' build-scripts/androidbuildlibs.sh

		# TODO(crueter): Just use CMake
		build-scripts/androidbuildlibs.sh -j"$(nproc)" APP_PLATFORM="$ANDROID_API" APP_ABI="$ABI"
	else
		cmake --build "$BUILD_DIR" --config Release --parallel
	fi
}

strip_libs() {
	echo "-- Stripping shared libraries..."

	case "$PLATFORM" in
		windows) ;;
		android) find "$OUT_DIR" -name "*.so" -exec llvm-strip --strip-all {} \; ;;
		*) find "$OUT_DIR" -name "*.$SHARED_SUFFIX" -exec strip {} \; ;;
	esac
}

## Packaging ##
copy_build_artifacts() {
    echo "-- Copying artifacts..."

	if android; then
	    mkdir "$OUT_DIR"/lib "$OUT_DIR"/include
		cp "build/android/lib/$ABI"/libSDL3* "$OUT_DIR"/lib
		cp -r include/SDL3 "$OUT_DIR"/include
		return
	fi

    cmake --install "$BUILD_DIR"

    echo "-- Cleaning..."
    rm -rf "$OUT_DIR"/lib/pkgconfig
    rm -rf "$OUT_DIR"/lib/cmake
    rm -rf "$OUT_DIR"/cmake

	case "$PLATFORM" in
		windows|mingw)
			mv "$OUT_DIR"/bin/SDL3.dll "$OUT_DIR"/lib/libSDL3.dll
			if ! command -v clang-cl >/dev/null 2>&1; then
				mv "$OUT_DIR"/lib/libSDL3.a "$OUT_DIR"/lib/libSDL3_static.lib
				mv "$OUT_DIR"/lib/libSDL3.dll.a "$OUT_DIR"/lib/libSDL3.lib
			else
				mv "$OUT_DIR"/lib/SDL3.lib "$OUT_DIR"/lib/libSDL3.lib
				mv "$OUT_DIR"/lib/SDL3-static.lib "$OUT_DIR"/lib/libSDL3_static.lib
			fi
			;;
		*)
			rm -rf "$OUT_DIR"/libdata
			rm -rf "$OUT_DIR"/share
			find "$OUT_DIR/lib" -type l -exec rm {} \;
			mv "$OUT_DIR/lib"/*."${SHARED_SUFFIX}"* "$OUT_DIR/lib/libSDL3.${SHARED_SUFFIX}"
			;;
	esac

	rm -rf "${OUT_DIR:?}/bin"
}

## Cleanup ##
rm -rf "$BUILD_DIR" "$OUT_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

## Download + Extract ##
download
cd "$BUILD_DIR"
extract

## Configure ##
cd "$DIRECTORY"
configure

## Build ##
build

## Package ##
copy_build_artifacts
copy_cmake

strip_libs
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in $OUT_DIR"
