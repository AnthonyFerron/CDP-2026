#!/bin/bash
# Grille de marche de toute la vallée, par régions de 80 m, pour un nombre de livres : grid_all.sh <livres> [régions...]
H=/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/hub
books=$1; shift
declare -A REGIONS=(
  [nw]="-110 -110 -30 -30 0 -32,-34;-50,-50;-60,-40"
  [n]="-30 -110 50 -30 0 0,-40;40,-44;0,-60;31,-55"
  [ne]="50 -110 130 -30 0 78,-30;52,-40;64,-60;80,-60"
  [w]="-110 -30 -30 50 0 -40,0;-60,10;-50,-20"
  [c]="-30 -30 50 50 0 0,8;20,20;-20,-20"
  [e]="50 -30 130 50 0 52,0;72,0;56,20;85,20"
  [sw]="-110 50 -30 115 0 -50,60;-66,52;-40,80"
  [s]="-30 50 50 115 0 0,52;12,72;-24,61"
  [se]="50 50 130 115 0 56,54;85,60;60,80"
  [bunker]="66 -8 90 8 -40 78,3"
)
list=("$@")
[ ${#list[@]} -eq 0 ] && list=(nw n ne w c e sw s se bunker)
for region in "${list[@]}"; do
  read -r x0 z0 x1 z1 y seeds <<< "${REGIONS[$region]}"
  HEADFUL=1 bash $H/run.sh $H/walk_grid.gd grid_${region}_${books}.log $books $region $x0 $z0 $x1 $z1 $y "$seeds" > /dev/null
  grep -h "RESUME" $H/grid_${region}_${books}.log || echo "ECHEC $region $books"
done
