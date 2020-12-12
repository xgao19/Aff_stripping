#!/bin/bash

cfglist=`cat list/list_cfg_a`
path_in='data/stream_a/c2pt_4'
path_out="c2pt_cfgs/c2pt_a_src100"
mkdir -p $path_out 1>/dev/null 2>&1
gm='meson_g15'
bxplist=('bxp20_bxp20' 'bxp50_bxp50')
#bxplist=('CG52bxp30_CG52bxp30')
smlist=('SS' 'SP')
pxlist=(0 1 2 3 4 5 6 7 8 9 10 -1 -2 -3 -4 -5 -6 -7 -8 -9 -10)
pylist=(-2 -1 0 1 2)
pzlist=(-2 -1 0 1 2)
filesize="34M"

sample="sample"

# stripping function
stripping(){

   cfg=$1
   bxp=$2
   echo "cfg: $cfg, ibxp: $bxp"

   cfg_pathout="$path_out/$cfg/$bxp"
   mkdir $cfg_pathout 1>/dev/null 2>&1

   rm $cfg_pathout/temp_sample_paths.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_ex_files.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_sl_files.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_save_files.txt 1>/dev/null 2>&1

   for ism in ${smlist[*]} 
   do
      for ipx in ${pxlist[*]}
      do
         for ipy in ${pylist[*]}
         do
            for ipz in ${pzlist[*]}
            do
               #if [ $ipy -lt -1 -o $ipy -gt 1 -o $ipz -lt -1 -o $ipz -gt 1 ]
               #then
                  echo "/c2pt/$ism/$gm/PX${ipx}_PY${ipy}_PZ${ipz}" >> $cfg_pathout/temp_sample_paths.txt
                  echo "$cfg_pathout/$cfg.c2pt.$bxp.$ism.$gm.PX${ipx}_PY${ipy}_PZ${ipz}" >> $cfg_pathout/temp_save_files.txt
               #fi
            done
         done
      done
   done
   
   src_count=0
   for exsrc in `ls -lh $path_in/c2pt.$cfg.ex.$bxp.*.hyp1m140.CG45.aff | grep $filesize | awk '{print $9}' | cut -d "." -f5`
   do
      src_count=`expr $src_count + 1`
      echo "ex source $src_count: ${exsrc}"
      rm $cfg_pathout/temp_ex_paths_src${src_count}.txt 1>/dev/null 2>&1
      cp $cfg_pathout/temp_sample_paths.txt $cfg_pathout/temp_ex_paths_src${src_count}.txt
      sed -i "s/$sample/$exsrc/g" $cfg_pathout/temp_ex_paths_src${src_count}.txt
      echo "$path_in/c2pt.$cfg.ex.$bxp.${exsrc}.hyp1m140.CG45.aff,$cfg_pathout/temp_ex_paths_src${src_count}.txt" >> $cfg_pathout/temp_ex_files.txt
   done
  
   src_count=0
   for slsrc in `ls -lh $path_in/c2pt.$cfg.sl.$bxp.*.hyp1m140.CG45.aff | grep $filesize | awk '{print $9}' | cut -d "." -f5`
   do
      src_count=`expr $src_count + 1`
      echo "sl source $src_count: ${slsrc}"
      rm $cfg_pathout/temp_sl_paths_src${src_count}.txt 1>/dev/null 2>&1
      cp $cfg_pathout/temp_sample_paths.txt $cfg_pathout/temp_sl_paths_src${src_count}.txt
      sed -i "s/$exsrc/$slsrc/g" $cfg_pathout/temp_sl_paths_src${src_count}.txt
      echo "$path_in/c2pt.$cfg.sl.$bxp.${slsrc}.hyp1m140.CG45.aff,$cfg_pathout/temp_sl_paths_src${src_count}.txt" >> $cfg_pathout/temp_sl_files.txt
   done

   ./stripping.o ama $cfg_pathout/temp_ex_files.txt $cfg_pathout/temp_sl_files.txt $cfg_pathout/temp_save_files.txt
}


# stripping loop
for cfg in ${cfglist[*]}
do
   echo "CONFGRATION $cfg START"
   rm $cfg.START
   cfg_pathout="$path_out/$cfg"
   mkdir $cfg_pathout 1>/dev/null 2>&1
   for ibxp in ${bxplist[*]}
   do 
      echo "cfg: $cfg, ibxp: $ibxp"
      stripping $cfg $ibxp & 
   done
   wait
   rm $cfg.DONE
   echo "CONFGRATION $cfg DONE"
done 


