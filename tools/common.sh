#!/bin/sh -e

# Common variables (repo, artifact, etc) used by tools

# shellcheck disable=SC1091
. tools/latest.sh

export VERSION
export PRETTY_NAME="SDL3"
export FILENAME="SDL3"
export REPO="libsdl-org/SDL"
export DIRECTORY="SDL3-$VERSION"
export ARTIFACT="SDL3-$VERSION.zip"
export TAG="release-$VERSION"

extract() {
  echo "-- Extracting $PRETTY_NAME $VERSION"
  rm -fr "$DIRECTORY"
  unzip "$ROOTDIR/$ARTIFACT"

  mv "$FILENAME-$VERSION" "$FILENAME-$VERSION-$ARCH"
}