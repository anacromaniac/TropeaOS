#!/bin/bash

# Repository hosting the themes (owner/repo).
# Defaults to the TropeaOS themes fork; override via env if needed, e.g.:
#   THEMES_REPO=OnionUI/Themes ./get_themes.sh
THEMES_REPO="${THEMES_REPO:-anacromaniac/TropeaOS-Themes}"
THEMES_BRANCH="${THEMES_BRANCH:-main}"

# When THEMES_STRICT=1, any failure to fetch themes aborts the build instead of
# degrading gracefully. Release workflows set this so a release never ships
# without themes; regular builds stay resilient to transient network errors.
THEMES_STRICT="${THEMES_STRICT:-0}"

had_error=0
err() {
    echo "-- ERROR: $*"
    had_error=1
}

mkdir -p cache
cd cache

featured_url="https://raw.githubusercontent.com/${THEMES_REPO}/${THEMES_BRANCH}/.github/data/featured.txt"
if ! wget -O featured.txt "$featured_url" > /dev/null 2>&1; then
    err "could not fetch featured themes list from ${THEMES_REPO}"
    rm -f ./featured.txt
    [ "$THEMES_STRICT" = "1" ] && exit 1
    exit 0
fi
featured=`cat ./featured.txt`
rm -f ./featured.txt

if [ -z "$featured" ]; then
    err "featured themes list is empty"
    [ "$THEMES_STRICT" = "1" ] && exit 1
    exit 0
fi

readarray -t themes <<< "$featured"

f() { themes=("${BASH_ARGV[@]}"); }

shopt -s extdebug
f "${themes[@]}"
shopt -u extdebug

mkdir -p ../dist/Themes

total=${#themes[@]}
processed=0
failed=0

for element in "${themes[@]}"
do
    zipfile="$element.zip"

    if [[ ! -f "$zipfile" ]]
    then
        echo "-- downloading theme: $element"
        if ! wget -O "$zipfile" "https://github.com/${THEMES_REPO}/raw/${THEMES_BRANCH}/release/$element.zip" -q --show-progress; then
            err "failed to download theme '$element' (skipping)"
            rm -f "$zipfile"
            failed=$((failed + 1))
            continue
        fi
    fi

    if [ "$element" == "Silky by DiMo" ]; then
        echo "-- extracting theme: $element"
        unzip -oq "$zipfile" -d ../dist/Themes
    else
        echo "-- copying theme: $element"
        cp "$zipfile" ../dist/Themes
    fi
    processed=$((processed + 1))
done

echo "-- themes: ${processed}/${total} processed, ${failed} failed"

if [ "$had_error" = "1" ] && [ "$THEMES_STRICT" = "1" ]; then
    exit 1
fi
