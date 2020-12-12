cfgfile='list/list_a_left_src000'
cfglist=(`cat $cfgfile`)
echo "configurations: ${cfglist[*]}"
for cfg in ${cfglist[*]}
do
   time bash scripts/src000_c3pt_ama_strip_a_p2.sh $cfg
done
