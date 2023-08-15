#!/usr/bin/env bash

# better read statements 
function get_input() {
    read -p "$1: " value
    echo $value
}
cols="$(tput cols)" # better than $COLUMNS
PLUGIN_NAME=$1

if [ -z "$PLUGIN_NAME" ]; then
    PLUGIN_NAME="$(get_input 'Enter plugin name')"
fi
if [[ "$PLUGIN_NAME" == "" ]]; then
    echo "You didn't enter plugin name" && exit 1
fi
SERVER="https://poggit.pmmp.io/releases.json"
S_NAME="$(curl -s $SERVER\?name\=$PLUGIN_NAME)"
IDS="$(echo "$S_NAME" |  jq .[].id | grep -o '[0-9]\+' | paste -s -d ' ')"
FROM="$(echo "$S_NAME" |  jq -r .[].api[].from)"
TO="$(echo "$S_NAME" | jq -r .[].api[].to)"
FROM=($FROM)
TO=($TO)

# If no plugin IDs were found, print error message and exit
if [[ "$IDS" == "" ]]; then
    echo "Plugin '$PLUGIN_NAME' not found"
    exit 1
fi

# Convert the list of IDs to an array
IDS=($IDS)

# Get selected plugin ID from command line argument, or prompt user to select from available IDs
if [[ -n "$2" ]]; then
    # User specified a plugin ID on the command line
    if (( $2 < 1 || $2 > ${#IDS[@]} )); then
        echo "Invalid plugin ID: $2"
        exit 1
    fi
    SELECTED_ID="${IDS[$(($2-1))]}"
else
    # Prompt user to select from available IDs
    echo "Found ${#IDS[@]} IDS matching '$PLUGIN_NAME':"
    printf "%-$((cols/2))s%$((cols/2))s" "IDs" "APIs"
    for i in "${!IDS[@]}"; do
        printf "%-$((cols/2))s%$((cols/2))s\n" "[$((i+1))] ${IDS[i]}" "${FROM[i]} - ${TO[i]}"
    done
    SELECTION="$(get_input 'Select a plugin ID (1-'${#IDS[@]}') ')"

    # Validate the user's selection
    if ! [[ $SELECTION =~ ^[0-9]+$ ]] || (( SELECTION < 1 || SELECTION > ${#IDS[@]} )); then
        echo "You must select a integer number from 1 to ${#IDS[@]}"
        exit 1
    fi

    # Use the selected plugin ID to fetch plugin data
    SELECTED_ID="${IDS[$(($SELECTION-1))]}"
fi
# Use the selected plugin ID to fetch plugin data
PLUGIN="$(curl -s $SERVER\?id\=$SELECTED_ID)"
getName="$(jq -r .[].name <<< $PLUGIN)"
getTagline="$(jq  .[].tagline <<< $PLUGIN)"
getFromAPI="$(jq -r .[].api[].from <<< $PLUGIN)"
getToAPI="$(jq -r .[].api[].to <<< $PLUGIN)"
getVer="$(jq -r .[].version <<< $PLUGIN)"
isOutdated="$(jq -r .[].is_outdated <<< $PLUGIN)"
DEPS="$(jq -r .[].deps[].name <<< $PLUGIN)"

for i in ${DEP[@]}; do
echo "$(jq -r .[].deps[$i].name <<< $PLUGIN)"
done

if [[ "$isOutdated" == "true" ]]; then
echo "Name: $getName ($getVer - OUTDATED)"
else
echo "Name: $getName ($getVer)"
fi
echo "Description: $getTagline"

echo "API: $getFromAPI-$getToAPI"


read -p "Process to install? [Y/N] " selectYN
case "$selectYN" in
  [Yy][Ee][ss]) echo "Installing $getName" && wget --quiet --show-progress https://poggit.pmmp.io/r/$SELECTED_ID/$getName.phar && echo "Plugin '$getName' installed sucessfully" exit 0;;
  [Yy]) echo "Installing $getName" && wget --show-progress --quiet https://poggit.pmmp.io/r/$SELECTED_ID/$getName.phar && echo "[*] Plugin '$getName' installed sucessfully" exit 0;;
  [Nn]) echo "Exiting.." && exit 0;;
  [Nn][Oo]) echo "Exiting.." && exit 0;;
  *) echo "Invaild options, Exiting..." && exit 1;;
esac 
 
