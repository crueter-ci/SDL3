#!/bin/sh -e

## Common variables ##

# TAG/COMMIT must be set.

# In some projects you will want to fetch latest from gh/fj api
# TIMESTAMP="$(date +%s)"
# export TIMESTAMP
export PRETTY_NAME="SDL3"
export FILENAME="SDL3"
export REPO="libsdl-org/SDL"
export DIRECTORY="SDL-$COMMIT"
export ARTIFACT="$COMMIT.tar.gz"
export DOWNLOAD_URL="https://github.com/$REPO/archive/$ARTIFACT"

if [ -f TIMESTAMP ]; then
	TIMESTAMP="$(cat TIMESTAMP)"
else
	TIMESTAMP=0
fi

export TIMESTAMP

SHORTSHA=$(echo "$COMMIT" | cut -c1-10)
export VERSION="$TAG-$TIMESTAMP-$SHORTSHA"
