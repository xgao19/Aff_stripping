cfgfile='list/list.cfg.breit.a3'
cfglist=(`cat $cfgfile`)
echo "configurations: ${cfglist[*]}"
for cfg in ${cfglist[*]}
do
   time bash scripts/c3pt_ama_strip_a3_2-10.sh $cfg
done
