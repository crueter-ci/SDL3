#!/bin/sh -e

## Common variables ##

export TAG=3.4.14
export COMMIT=147a8ee32dbf9ac02f3794964490687b6bbda1bc
export PRETTY_NAME="SDL3"
export FILENAME="SDL3"
export REPO="libsdl-org/SDL"
export DIRECTORY="SDL-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

if [ -f TIMESTAMP ]; then
	TIMESTAMP="$(cat TIMESTAMP)"
else
	TIMESTAMP=$(date +"%s")
	echo "$TIMESTAMP" > TIMESTAMP
fi

export TIMESTAMP

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$TAG-$TIMESTAMP-$SHORTSHA"
