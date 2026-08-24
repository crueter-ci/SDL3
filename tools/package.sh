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

}

copy_cmake() {
	_group "Copying CMake artifacts"

    cp "$ROOTDIR"/CMakeLists.txt out

	_end
}

sums() {
	for file in "$@"; do
		if ! command -v sha512sum >/dev/null 2>&1; then
			must_install sha512
			sha512 "$file" | awk '{print $4}' | tr -d "\n" >"$file".sha512sum
		else
			must_install sha512sum
			sha512sum "$file" | cut -d " " -f1 | tr -d "\n" >"$file".sha512sum
		fi
	done
}

package() {
    _group "Packaging"
    mkdir -p "$ROOTDIR/artifacts"

	TARBALL=$FILENAME-$PLATFORM-$ARCH-$VERSION.tar

    cd out
    tar cf "$ROOTDIR/artifacts/$TARBALL" ./*

    cd "$ROOTDIR/artifacts"
    zstd -10 "$TARBALL"
    rm "$TARBALL"

    sums "$TARBALL.zst"
	_end
}

copy_build_artifacts
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in out"