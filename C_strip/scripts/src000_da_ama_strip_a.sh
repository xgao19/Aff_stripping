#!/bin/bash

cfglist=`cat list/list_cfg_a`
path_in='data/stream_a/da'
path_out='da_cfgs_integrated/da_a_src000'
mkdir -p $path_out 1>/dev/null 2>&1
qxyzlist_file='da_qxqyqz.txt'
sep_read_file='qpdf_sep_read.txt'
sep_save_file='qpdf_sep_save.txt'
gmlist=('g14')
bxplist=('bxp20' 'bxp50')
hyp='_hyp'
filesize="20M"

# paramter reading
echo "pxlist ${pxlist[*]}"
qxyzlist=(`cat $qxyzlist_file`)
sep_read=(`cat $sep_read_file`)
sep_save=(`cat $sep_save_file`)
echo ${sep_read[*]}
echo ${sep_save[*]}
echo ${qxyzlist[*]}
nsep=${#sep_read[*]}
nsep=`expr $nsep - 1`
zlist=$(seq 0 $nsep)

sample="sample"

# stripping function
stripping(){

   cfg=$1
   gm=$2
   bxp=$3

   cfg_pathout="$path_out/$cfg/$bxp"
   mkdir -p $cfg_pathout 1>/dev/null 2>&1

   rm $cfg_pathout/temp_sample_paths.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_ex_files.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_sl_files.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_save_files.txt 1>/dev/null 2>&1
   save_name=$cfg_pathout/$cfg.da.SP.meson.ama.$bxp.$gm

   for sep in ${zlist}
   do
      sepr="${sep_read[${sep}]}"
      seps="${sep_save[${sep}]}"
      for qxyz in ${qxyzlist[*]}
      do
         echo /da/SP/meson/$sample/${sepr}/$gm/$qxyz >> $cfg_pathout/temp_sample_paths.txt
         echo $cfg_pathout/$cfg.da.SP.meson.ama.$bxp.$gm.${seps}.$qxyz >> $cfg_pathout/temp_save_files.txt
      done
   done
   
   src_count=0
   for exsrc in `ls -lh $path_in/da.$cfg.ex.${bxp}$hyp.*.hyp1m140.CG45.aff | grep $filesize | awk '{print $9}' | cut -d "." -f5`
   do
      src_count=`expr $src_count + 1`
      echo "ex source $src_count: ${exsrc}"
      rm $cfg_pathout/temp_ex_paths_src${src_count}.txt 1>/dev/null 2>&1
      cp $cfg_pathout/temp_sample_paths.txt $cfg_pathout/temp_ex_paths_src${src_count}.txt
      sed -i "s/$sample/$exsrc/g" $cfg_pathout/temp_ex_paths_src${src_count}.txt
      echo "$path_in/da.$cfg.ex.${bxp}$hyp.${exsrc}.hyp1m140.CG45.aff,$cfg_pathout/temp_ex_paths_src${src_count}.txt" >> $cfg_pathout/temp_ex_files.txt
   done
 
   src_count=0
   for slsrc in `ls -lh $path_in/da.$cfg.sl.${bxp}$hyp.*.hyp1m140.CG45.aff  | grep $filesize | awk '{print $9}' | cut -d "." -f5`
   do
      src_count=`expr $src_count + 1`
      echo "sl source $src_count: ${slsrc}"
      rm $cfg_pathout/temp_sl_paths_src${src_count}.txt 1>/dev/null 2>&1
      cp $cfg_pathout/temp_sample_paths.txt $cfg_pathout/temp_sl_paths_src${src_count}.txt
      sed -i "s/$sample/$slsrc/g" $cfg_pathout/temp_sl_paths_src${src_count}.txt
      echo "$path_in/da.$cfg.sl.${bxp}$hyp.${slsrc}.hyp1m140.CG45.aff,$cfg_pathout/temp_sl_paths_src${src_count}.txt" >> $cfg_pathout/temp_sl_files.txt
   done

   ./stripping_intg.o ama $cfg_pathout/temp_ex_files.txt $cfg_pathout/temp_sl_files.txt $save_name

   #rm $cfg_pathout/temp_sl_paths*
}


# stripping loop
for cfg in ${cfglist[*]}
do
   echo "CONFGRATION $cfg START"
   rm $cfg.START
   cfg_pathout="$path_out/$cfg"
   mkdir $cfg_pathout 1>/dev/null 2>&1
   for igm in ${gmlist[*]}
   do
      for ibxp in ${bxplist[*]}
      do
         echo "cfg: $cfg, igm: $igm, ibxp: $ibxp"
         stripping $cfg $igm $ibxp &
      done
   done
   wait
   rm $cfg.DONE
   echo "CONFGRATION $cfg DONE"
done
