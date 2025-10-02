#!/bin/sh -ex

# Common variables (repo, artifact, etc) used by tools

# Pinned here because sdl2 lol
export VERSION="2.32.10"
export PRETTY_NAME="SDL2"
export FILENAME="SDL2"
export REPO="libsdl-org/SDL"
export DIRECTORY="SDL2-$VERSION"
export ARTIFACT="SDL2-$VERSION.zip"
export TAG="release-$VERSION"

extract() {
  echo "Extracting $PRETTY_NAME $VERSION"
  rm -fr $DIRECTORY
  unzip "$ROOTDIR/$ARTIFACT"

  mv "$FILENAME-$VERSION" "$FILENAME-$VERSION-$ARCH"
}