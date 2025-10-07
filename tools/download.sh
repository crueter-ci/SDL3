#!/bin/sh -e

# Downloads the specified version of the software.
# Requires: wget

# shellcheck disable=SC1091
. tools/common.sh

# This shouldn't need to be changed unless the software is on GitLab or otherwise
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ARTIFACT"

while true; do
   if [ ! -f "$ARTIFACT" ]; then
       wget "$DOWNLOAD_URL" -O "$ARTIFACT" && exit 0
       echo "Download failed, trying again in 5 seconds..."
       sleep 5
    else
        exit 0
    fi
done
