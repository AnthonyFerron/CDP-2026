#!/bin/bash
# Captures d'une liste de groupes puis planches de 20 : caps.sh <groupe> [<groupe> ...]
H=/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/hub
for group in "$@"; do rm -rf "$H/cap/$group"; done
HEADFUL=1 bash $H/run.sh $H/views_shots.gd caps.log "$@" > /dev/null
for group in "$@"; do
  count=$(ls "$H/cap/$group" 2>/dev/null | wc -l)
  first=0
  part=1
  while [ $first -lt $count ]; do
    bash $H/sheet.sh "cap/$group" "cap/${group}_$part.png" $first 20 > /dev/null
    echo "$group : planche $part ($first..$((first + 19)) sur $count)"
    first=$((first + 20))
    part=$((part + 1))
  done
done
