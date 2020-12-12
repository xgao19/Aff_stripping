#!/bin/bash
cfg=$1

path_in='data/stream_a3/qpdf_breit_new'
path_out='c3pt_cfgs/c3pt_a3'
mkdir -p $path_out 1>/dev/null 2>&1
qxyzlist_file='qgpd_qxqyqz_breit.txt'
sep_read_file='qpdf_sep_read_X24.txt'
sep_save_file='qpdf_sep_save_X24.txt'
gmlist='g0 g1 g2 g4 g8'
hyp='_hyp'
bxplist=('CG52bxp00_CG52bxp00' 'CG52bxp00_CG52bxp00' 'CG52bxp20_CG52bxp20' 'CG52bxp20_CG52bxp20' 'CG52bxp30_CG52bxp30' 'CG52bxp30_CG52bxp30')
pxlist=(2)
py=-1
pz=0
dtlist=(8 10 12)
filesize="M"

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

   cfg_pathout="$path_out/$cfg/$gm/PX${px}_PY${py}_PZ${pz}_dt${ts}"
   mkdir -p $cfg_pathout 1>/dev/null 2>&1

   rm $cfg_pathout/temp_sample_paths.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_ex_files.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_sl_files.txt 1>/dev/null 2>&1
   rm $cfg_pathout/temp_save_files.txt 1>/dev/null 2>&1
   save_name=$cfg_pathout/$cfg.qpdf.SS.meson.ama.PX${px}_PY${py}_PZ${pz}_dt${ts}.$gm

   for sep in ${zlist}
   do
      sepr="${sep_read[${sep}]}"
      seps="${sep_save[${sep}]}"
      for qxyz in ${qxyzlist[*]}
      do
         echo /qpdf/SS/meson/$sample/PX${px}_PY${py}_PZ${pz}_dt${ts}/${sepr}/$gm/$qxyz >> $cfg_pathout/temp_sample_paths.txt
         echo $cfg_pathout/$cfg.qpdf.SS.meson.ama.PX${px}_PY${py}_PZ${pz}_dt${ts}.${seps}.$gm.$qxyz >> $cfg_pathout/temp_save_files.txt
      done
   done
   
   src_count=0
   for exsrc in `ls -lh $path_in/qpdf.$cfg.ex.*.PX${px}PY${py}PZ${pz}dt${ts}.${bxplist[$px]}$hyp.aff | grep $filesize | awk '{print $9}' | cut -d "." -f4`
   do
      src_count=`expr $src_count + 1`
      echo "ex source $src_count: ${exsrc}"
      rm $cfg_pathout/temp_ex_paths_src${src_count}.txt 1>/dev/null 2>&1
      cp $cfg_pathout/temp_sample_paths.txt $cfg_pathout/temp_ex_paths_src${src_count}.txt
      sed -i "s/$sample/$exsrc/g" $cfg_pathout/temp_ex_paths_src${src_count}.txt
      echo "$path_in/qpdf.$cfg.ex.${exsrc}.PX${px}PY${py}PZ${pz}dt${ts}.${bxplist[$px]}$hyp.aff,$cfg_pathout/temp_ex_paths_src${src_count}.txt" >> $cfg_pathout/temp_ex_files.txt
   done
 
   src_count=0
   for slsrc in `ls -lh $path_in/qpdf.$cfg.sl.*.PX${px}PY${py}PZ${pz}dt${ts}.${bxplist[$px]}$hyp.aff  | grep $filesize | awk '{print $9}' | cut -d "." -f4`
   do
      src_count=`expr $src_count + 1`
      echo "sl source $src_count: ${slsrc}"
      rm $cfg_pathout/temp_sl_paths_src${src_count}.txt 1>/dev/null 2>&1
      cp $cfg_pathout/temp_sample_paths.txt $cfg_pathout/temp_sl_paths_src${src_count}.txt
      sed -i "s/$sample/$slsrc/g" $cfg_pathout/temp_sl_paths_src${src_count}.txt
      echo "$path_in/qpdf.$cfg.sl.${slsrc}.PX${px}PY${py}PZ${pz}dt${ts}.${bxplist[$px]}$hyp.aff,$cfg_pathout/temp_sl_paths_src${src_count}.txt" >> $cfg_pathout/temp_sl_files.txt
   done

   ./stripping_intg.o ama $cfg_pathout/temp_ex_files.txt $cfg_pathout/temp_sl_files.txt $save_name
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
         stripping $cfg $gm $px $ts &
      done
   done
done
wait
rm $cfg.DONE
echo "CONFGRATION $cfg DONE"     
