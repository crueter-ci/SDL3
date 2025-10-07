#!/bin/sh -e

# Grabs the latest SDL version from the GitHub API.
# Requires: curl, jq, cut

API_URL=https://api.github.com/repos/libsdl-org/SDL/releases/latest

while true; do
    VERSION=$(curl $API_URL | jq -r '.tag_name' | cut -d "-" -f2)
    [ "$VERSION" != "null" ] && echo "$VERSION" && break
    sleep 5
done