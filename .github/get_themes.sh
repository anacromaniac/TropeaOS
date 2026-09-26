#!/bin/bash

# Repository hosting the themes (owner/repo).
# Defaults to the TropeaOS themes fork; override via env if needed, e.g.:
#   THEMES_REPO=OnionUI/Themes ./get_themes.sh
THEMES_REPO="${THEMES_REPO:-anacromaniac/TropeaOS-Themes}"
THEMES_BRANCH="${THEMES_BRANCH:-main}"

mkdir -p cache
cd cache

featured_url="https://raw.githubusercontent.com/${THEMES_REPO}/${THEMES_BRANCH}/.github/data/featured.txt"
if ! wget -O featured.txt "$featured_url" > /dev/null 2>&1; then
    echo "-- WARN: could not fetch featured themes list from ${THEMES_REPO} (building without themes)"
    rm -f ./featured.txt
    exit 0
fi
featured=`cat ./featured.txt`
rm -f ./featured.txt

if [ -z "$featured" ]; then
    echo "-- WARN: featured themes list is empty (building without themes)"
    exit 0
fi

readarray -t themes <<< "$featured"

f() { themes=("${BASH_ARGV[@]}"); }

shopt -s extdebug
f "${themes[@]}"
shopt -u extdebug

mkdir -p ../dist/Themes

for element in "${themes[@]}"
do
    zipfile="$element.zip"

    if [[ ! -f "$zipfile" ]]
    then
        echo "-- downloading theme: $element"
        if ! wget -O "$zipfile" "https://github.com/${THEMES_REPO}/raw/${THEMES_BRANCH}/release/$element.zip" -q --show-progress; then
            echo "-- WARN: failed to download theme '$element' (skipping)"
            rm -f "$zipfile"
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
done
