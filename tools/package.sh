#!/bin/sh -e

set -e

# shellcheck disable=SC1091

. tools/common.sh

ROOTDIR="$PWD"

copy_build_artifacts() {
	_group "Copying build artifacts"
	cmake --install build
	_end

	_group "Cleaning"
	rm -rf out/lib/pkgconfig
    rm -rf out/lib/cmake
    rm -rf out/cmake

	case "$PLATFORM" in
		windows|mingw)
			if ! command -v clang-cl >/dev/null 2>&1; then
				mv out/lib/libSDL3.a out/lib/libSDL3_static.lib
			else
				mv out/lib/SDL3-static.lib out/lib/libSDL3_static.lib
			fi
			;;
		*)
			rm -rf out/libdata
			rm -rf out/share
			find out/lib -type l -exec rm {} \;
			;;
	esac

	rm -rf out/bin
	_end
}

copy_build_artifacts
copy_cmake
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in out"