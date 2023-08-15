#!/usr/bin/env bash
# jq '. | length'
PLUGIN="$(cat saved.json)"
DEP="$(jq -r '.[].deps | length' <<< $PLUGIN)"
DEP=${DEP[@]}
SERVER="https://poggit.pmmp.io/releases.json"
for (( i=0; i<$DEP; i++ )); do
DEP_ID="$(jq -r .[].deps[$i].depRelId <<< $PLUGIN)"
DEP_INFO="$(curl -s $SERVER/?id=$DEP_ID)"
echo $DEP_ID
echo "Installing: $(jq -r .[].name <<< $DEP_INFO) $(jq -r .[].deps[$i].version <<< $PLUGIN)"
wget "https://poggit.pmmp.io/r/$DEP_ID/$(jq -r .[].name <<< $DEP_INFO).phar"
done
