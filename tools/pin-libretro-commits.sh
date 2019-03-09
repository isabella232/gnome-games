#!/bin/bash

CORES_DIR="../flatpak/libretro-cores"

# A script pinning down commits of all libretro cores to be used before doing
# a stable release.

cd $CORES_DIR

for F in *.json; do
    echo "Processing $F"

    LINE_NUMBER=$(grep -Pn '\"type\"\s*:\s*\"git\"' $F | grep -Po '^\d+')

    if [[ "$LINE_NUMBER" == "" ]]; then
        echo "Cannot find line containing git source"
        exit 1
    fi

    # If one of the next 2 lines contains "commit" word in quotes, assume it's already pinned and skip it
    sed -n "$((LINE_NUMBER+2)),$((LINE_NUMBER+3))p" $F | grep '\"commit\"' > /dev/null
    if [[ "$?" == "0" ]]; then
        echo 'Already pinned, skipping'
        echo
        continue
    fi

    # Find every substring between two quotes, take the last one
    URL=`sed -n "$((LINE_NUMBER+1))p" $F | grep -Po '(?<=\")[^"]*(?=\")' | tail -n1`
    BRANCH='master'

    # Check for "branch" word on the next line. If it's present, get the branch the same way
    # as url and use it instead of master
    sed -n "$((LINE_NUMBER+2))p" $F | grep '\"branch\"' > /dev/null
    if [[ "$?" == "0" ]]; then
        BRANCH=`sed -n "$((LINE_NUMBER+2))p" $F | grep -Po '(?<=\")[^"]*(?=\")' | tail -n1`
        LINE_NUMBER=$((LINE_NUMBER+1))
    fi

    echo "Found git source: $URL $BRANCH"

    COMMIT=$(git ls-remote $URL $BRANCH | grep -Po '^\w+')
    echo "Pinning to $COMMIT"

    # Add a comma on the last line, and append "commit": "$COMMIT" after that
    sed -i "$((LINE_NUMBER+1))s/$/,/; $((LINE_NUMBER+1)) a \                    \"commit\": \"$COMMIT\"" $F

    echo
done
