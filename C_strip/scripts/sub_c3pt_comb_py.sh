#!/bin/bash
# Begin LSF Directives
#BSUB -J comb.src110
#BSUB -P PHY138HOT
#BSUB -W 6:00
#BSUB -nnodes 1
#BSUB -alloc_flags gpumps
#BSUB -q batch-hm

cd /ccs/home/xiangg/phy138hot_share/data/l64c64a076/C_strip/

export OMP_NUM_THREADS=4

#jsrun -o /ccs/home/xiangg/phy138hot_share/data/l64c64a076/C_strip/logs/src001_c3pt_a.o -k /ccs/home/xiangg/phy138hot_share/data/l64c64a076/C_strip/logs/src001_c3pt_a.e -n 1 -c 42 bash scripts/src001_c3pt_ama_strip_loop_a.sh
jsrun -o /ccs/home/xiangg/phy138hot_share/data/l64c64a076/C_strip/logs/src001_c3pt_a_comb.o -k /ccs/home/xiangg/phy138hot_share/data/l64c64a076/C_strip/logs/src001_c3pt_a_comb.e -n 40 -c 1 /ccs/home/xiangg/software/install/python3.5.8/bin/python3 strip_comb_csv_mp_intg.py  
