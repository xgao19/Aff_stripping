cfgfile='list/list_cfg_a'
cfglist=(`cat $cfgfile`)
echo "configurations: ${cfglist[*]}"
for cfg in ${cfglist[*]}
do
   time bash scripts/src001_c3pt_ama_strip_a_p2.sh $cfg
done
