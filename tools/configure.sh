#!/bin/sh

# shellcheck disable=SC1091

set -e

. tools/common.sh

OUT_DIR="$PWD/out"

cd "$DIRECTORY"

if android; then
	: "${ANDROID_NDK_ROOT:?-- You must supply the ANDROID_NDK_ROOT environment variable.}"
	: "${ANDROID_API:=23}"
	android_paths
fi

configure() {
	_group "Configuring $PRETTY_NAME"

	if linux || macos || ios; then
		set -- "$@" -DCMAKE_INSTALL_LIBDIR=lib
	fi

	if macos; then
		set -- "$@" -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0
	fi

	if ios; then
		: "${IOS_TARGET:=iphoneos}"
		set -- "$@" -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$IOS_TARGET"
	fi

	if android; then
		case "$ARCH" in
			amd64) ABI=x86_64 ;;
			aarch64) ABI=arm64 ;;
		esac

		set -- "$@" -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
			-DANDROID_ABI="$ABI" -DANDROID_PLATFORM="android-$ANDROID_API"
	fi

	if command -v sccache >/dev/null 2>&1 && [ -z "$SCCACHE_PATH" ]; then
		SCCACHE_PATH=$(command -v sccache)
	fi

	if [ -n "$SCCACHE_PATH" ]; then
		set -- "$@" -DCMAKE_C_COMPILER_LAUNCHER="${SCCACHE_PATH}" -DCMAKE_CXX_COMPILER_LAUNCHER="${SCCACHE_PATH}"
	fi

	cmake -S . -B ../build \
		-DSDL_WERROR=OFF \
		-DSDL_TEST_LIBRARY=OFF \
		-DSDL_VENDOR_INFO="crueter's CI" \
		-DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
		-DSDL_SHARED=OFF \
		-DSDL_STATIC=ON \
		-GNinja \
		-DCMAKE_BUILD_TYPE=Release \
		"$@"

	_end
}

configure