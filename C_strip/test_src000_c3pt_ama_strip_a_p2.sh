#!/bin/bash
cfg=$1

path_in='data/stream_a/qpdf'
path_out='c3pt_cfgs_integrated/c3pt_a_src000'
mkdir -p $path_out 1>/dev/null 2>&1
qxyzlist_file='qgpd_qxqyqz_p2.txt'
sep_read_file='qpdf_sep_read.txt'
sep_save_file='qpdf_sep_save.txt'
gmlist='g0 g1 g2 g4 g8'
#gmlist='g0'
#gmlist='g4 g8 g2'
hyp='_hyp'
bxplist=('bxp20_bxp20' 'bxp20_bxp20' 'bxp20_bxp20' 'bxp20_bxp20' 'bxp50_bxp50' 'bxp50_bxp50' 'bxp50_bxp50' 'bxp50_bxp50' 'bxp50_bxp50' 'bxp50_bxp50')
#pxlist=(0)
pxlist=(0 1 2 3 4 5 6 7 8 9)
#pxlist=(9 8 7 6 5 4 3 2 1 0)
#dtlist=(6 8 10)
dtlist=(10)
filesize="67M"

# paramter reading
echo "pxlist ${pxlist[*]}"
echo "dtlist ${dtlist[*]}"
qxyzlist=(`cat $qxyzlist_file`)
sep_read=(`cat $sep_read_file`)
sep_save=(`cat $sep_save_file`)
echo ${sep_read[*]}
echo ${sep_save[*]}
echo ${qxyzlist[*]}
nsep=${#sep_read[*]}
nsep=`expr $nsep - 1`
zlist=$(seq 0 $nsep)
#cfglist=`cat $cfgfile`
#if [ ${#cfglist} -gt 0 ]
#then
#   echo "configurations:"
#   echo $cfglist
#else
#   echo "Bad input!!!"
#fi

sample="sample"

# stripping function
stripping(){

   cfg=$1
   gm=$2
   px=$3
   ts=$4
   #echo "cfg: $cfg, px: $px, ts: $ts"

   cfg_pathout="$path_out/$cfg/$gm/PX${px}_PY0_PZ0_dt${ts}"
   mkdir -p $cfg_pathout 1>/dev/null 2>&1

   rm $cfg_pathout/temp_sample_paths.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_ex_files.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_sl_files.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_save_files.txt 1>/dev/null 2>&1
   save_name=$cfg_pathout/$cfg.qpdf.SS.meson.ama.PX${px}_PY0_PZ0_dt${ts}.$gm

   for sep in ${zlist}
   do
      sepr="${sep_read[${sep}]}"
      seps="${sep_save[${sep}]}"
      for qxyz in ${qxyzlist[*]}
      do
         echo /qpdf/SS/meson/$sample/PX${px}_PY0_PZ0_dt${ts}/${sepr}/$gm/$qxyz >> $cfg_pathout/temp_sample_paths.txt
         echo $cfg_pathout/$cfg.qpdf.SS.meson.ama.PX${px}_PY0_PZ0_dt${ts}.${seps}.$gm.$qxyz >> $cfg_pathout/temp_save_files.txt
      done
   done
   
   src_count=0
   for exsrc in `ls -lh $path_in/qpdf.$cfg.ex.${bxplist[$px]}$hyp.*.PX${px}PY0PZ0dt${ts}.hyp1m140.CG45.aff | grep $filesize | awk '{print $9}' | cut -d "." -f5`
   do
      src_count=`expr $src_count + 1`
      echo "ex source $src_count: ${exsrc}"
      rm $cfg_pathout/temp_ex_paths_src${src_count}.txt 1>/dev/null 2>&1
      cp $cfg_pathout/temp_sample_paths.txt $cfg_pathout/temp_ex_paths_src${src_count}.txt
      sed -i "s/$sample/$exsrc/g" $cfg_pathout/temp_ex_paths_src${src_count}.txt
      echo "$path_in/qpdf.$cfg.ex.${bxplist[$px]}$hyp.${exsrc}.PX${px}PY0PZ0dt${ts}.hyp1m140.CG45.aff,$cfg_pathout/temp_ex_paths_src${src_count}.txt" >> $cfg_pathout/temp_ex_files.txt
   done
 
   src_count=0
   for slsrc in `ls -lh $path_in/qpdf.$cfg.sl.${bxplist[$px]}$hyp.*.PX${px}PY0PZ0dt${ts}.hyp1m140.CG45.aff  | grep $filesize | awk '{print $9}' | cut -d "." -f5`
   do
      src_count=`expr $src_count + 1`
      echo "sl source $src_count: ${slsrc}"
      rm $cfg_pathout/temp_sl_paths_src${src_count}.txt 1>/dev/null 2>&1
      cp $cfg_pathout/temp_sample_paths.txt $cfg_pathout/temp_sl_paths_src${src_count}.txt
      sed -i "s/$sample/$slsrc/g" $cfg_pathout/temp_sl_paths_src${src_count}.txt
      echo "$path_in/qpdf.$cfg.sl.${bxplist[$px]}$hyp.${slsrc}.PX${px}PY0PZ0dt${ts}.hyp1m140.CG45.aff,$cfg_pathout/temp_sl_paths_src${src_count}.txt" >> $cfg_pathout/temp_sl_files.txt
   done

   ./stripping_intg.o ama $cfg_pathout/temp_ex_files.txt $cfg_pathout/temp_sl_files.txt $save_name

   #rm $cfg_pathout/temp_sl_paths*
}


# stripping loop
echo "CONFGRATION $cfg START"
rm $cfg.START
cfg_pathout="$path_out/$cfg"
mkdir $cfg_pathout 1>/dev/null 2>&1
for gm in ${gmlist[*]}
do
   for px in ${pxlist[*]}
   do 
      echo "PX $px"
      for ts in ${dtlist[*]}
      do
         echo "cfg: $cfg, gm: $gm, px: $px, ts: $ts"
         stripping $cfg $gm $px $ts
      done 
      #wait
   done
done
#wait
rm $cfg.DONE
echo "CONFGRATION $cfg DONE"     
