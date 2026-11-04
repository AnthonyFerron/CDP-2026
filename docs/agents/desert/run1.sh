. "$(dirname "$0")/env.sh"
cp $S/write_desert_tscn.py $D/write_desert_tscn.py
mkdir -p $D/tmpout/scenes/levels/desert
python $D/write_desert_tscn.py $D/tmpout
diff $D/tmpout/scenes/levels/desert/desert.tscn $F/scenes/levels/desert/desert.tscn && echo SAME
