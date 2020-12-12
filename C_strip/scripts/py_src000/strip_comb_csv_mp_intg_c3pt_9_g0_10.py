import os
import sys
import csv
import numpy as np
from multiprocessing import Pool as ThreadPool
import multiprocessing

data_in = ["c3pt_cfgs_integrated/c3pt_a_src000"]
cfg_file = ["list/list_cfg_a"]
data_out = "c3pt_comb/c3pt_a_src000"
#Nraw = 32
#Ncfg = 206

def normalize(dataset, factor):

    for i in range(0, len(dataset)):
        for j in range(1, len(dataset[0])):
            dataset[i][j] *= factor

    return dataset

def savecsv(dataset, savefile, describe=['csv']):
    with open(savefile, 'w') as outfile:
        writer = csv.writer(outfile)
        writer.writerow([describe])
        for raw in dataset:
            writer.writerows([raw])
        outfile.close()

def collectdata(fileline):

    if 'c2pt' in data_in[0]:
        #normfactor = 0.0637332 #48c64 0.038888
        #normfactor = 0.0635442 #64c64 0.033
        normfactor = 0.0640599 #64c64 0.049
    elif 'c3pt' in data_in[0]:
        #normfactor = 0.01608972 #48c64 0.038888
        #normfactor = 0.0160182  #64c64 0.033
        normfactor = 0.0162136 #64c64 0.049

    f_save = fileline[0]

    dataset = []
    for i in range(0, len(data_in)):

        f_read_sample = fileline[i+1][0]
        cfglist = fileline[i+1][1:]

        for icfg in cfglist:

            f_read_cfg = f_read_sample.replace('*', str(icfg))
            icfg_data = np.loadtxt(f_read_cfg)
            if i >= 0:
                icfg_data = normalize(icfg_data, normfactor)
            dataset += [icfg_data]

    data_real = []
    data_imag = []
    for i in range(0, len(icfg_data)):
 
        idata_real = [i]
        idata_imag = [i]

        for j in range(0, len(dataset)):

            idata_real += [dataset[j][i][1]]
            idata_imag += [dataset[j][i][2]]

        data_real += [idata_real]
        data_imag += [idata_imag]

    savecsv(data_real, f_save+'.real', 'csv, raws:'+str(len(icfg_data))+', cfgs:'+str(len(dataset)))
    savecsv(data_imag, f_save+'.imag', 'csv, raws:'+str(len(icfg_data))+', cfgs:'+str(len(dataset)))
    print(f_save,' saved.')

def collectdata_integrated(fileline):

    if 'c2pt' in data_in[0]:
        #normfactor = 0.0637332 #48c64 0.038888
        #normfactor = 0.0635442 #64c64 0.033
        normfactor = 0.0640599 #64c64 0.049
    elif 'c3pt' in data_in[0]:
        #normfactor = 1 # test
        #normfactor = 0.01608972 #48c64 0.038888
        #normfactor = 0.0160182  #64c64 0.033
        normfactor = 0.0162136 #64c64 0.049

    f_save = fileline[0]
    f_read = fileline[1]
    #print(len(f_save), f_save[0], f_save[-1])
   
    print('Read format:', f_read)
    dataset = []
    for i in range(0, len(f_read)):

        f_read_sample = f_read[i][0]
        cfglist = f_read[i][1:]

        for icfg in cfglist:
            f_read_cfg = f_read_sample.replace('*', str(icfg))
            icfg_data = np.loadtxt(f_read_cfg)
            if i >= 0:
                icfg_data = normalize(icfg_data, normfactor)
            dataset += [icfg_data]
            print('Read cfg:', icfg, 'from', data_in[i], 'done.')
    print(np.shape(dataset))

    len_tau = len(dataset[0])/len(f_save)
    if len_tau - int(len_tau) != 0:
        print('Bad data input! Length of tau is not the same!!!')
        sys.exit(1)
    else:
        len_tau = int(len_tau)
   
    for i_save in range(0, len(f_save)):
        
        data_real = []
        data_imag = []
       
        for i_tau in range(0, len_tau):

            itau_data_real = [i_tau]
            itau_data_imag = [i_tau]

            for i_cfg in range(0, len(dataset)):

                itau_data_real += [dataset[i_cfg][i_tau+i_save*len_tau][1]]
                itau_data_imag += [dataset[i_cfg][i_tau+i_save*len_tau][2]]

            data_real += [itau_data_real]
            data_imag += [itau_data_imag]

        savecsv(data_real, f_save[i_save]+'.real', 'csv, raws:'+str(len_tau)+', cfgs:'+str(len(dataset)))
        savecsv(data_imag, f_save[i_save]+'.imag', 'csv, raws:'+str(len_tau)+', cfgs:'+str(len(dataset)))
        print(f_save[i_save],' saved.')

if __name__ == "__main__":

    if "c2pt" in data_in[0]:

        cfglist = []
        for i in range(0, len(cfg_file)):
            i_cfglist = np.loadtxt(cfg_file[i],int)
            cfglist += [i_cfglist]   

        bxplist = ['CG52bxp30_CG52bxp30']
        smlist = ['SS','SP']
        glist = ['meson_g15']
        pxlist = [4,5]
        pylist = [-1,0,1]
        pzlist = [-1,0,1]
 
        filelist = []
        for ibxp in bxplist:
            for ism in smlist:
                for ig in glist:
                    for ipx in pxlist:
                        for ipy in pylist:
                            for ipz in pzlist:
                                f_read_sample = '/*/'+ibxp+'/*.c2pt.'+ibxp+'.'+ism+'.'+ig+'.PX'+str(ipx)+'_PY'+str(ipy)+'_PZ'+str(ipz)
                                f_save = data_out + '/' + 'c2pt.'+ibxp+'.'+ism+'.'+ig+'.PX'+str(ipx)+'_PY'+str(ipy)+'_PZ'+str(ipz)
              
                                f_p = [f_save]
                                for i in range(0, len(data_in)):
                                    f_read_sample_i = data_in[i]+f_read_sample
                                    f_i = [f_read_sample_i] + list(cfglist[i])
                                    f_p += [f_i]
                                filelist += [f_p]
                                #print(f_p)
                                #collectdata(f_p)
               
        # Make the Pool of workers
        print(filelist[0])
        pool = ThreadPool(2)
        results = pool.map(collectdata, filelist)
        # close the pool and wait for the work to finish
        pool.close()
        pool.join()
        print(filelist)

    elif "c3pt" in data_in[0] and "integrated" not in data_in[0]:
        print("Standard combination of c3pt data.")

        cfglist = []
        for i in range(0, len(cfg_file)):
            i_cfglist = np.loadtxt(cfg_file[i],int)
            cfglist += [i_cfglist]

        bxplist = ['CG52bxp00_CG52bxp00','CG52bxp00_CG52bxp00','CG52bxp20_CG52bxp20','CG52bxp20_CG52bxp20','CG52bxp30_CG52bxp30','CG52bxp30_CG52bxp30']
        hyp='_hyp'
        pxlist = [4,5]
        pylist = [0]
        pzlist = [0]
        tslist = [9,12,15,18]

        glist = ['g0','g1','g2','g4','g8']
        Xlist = [i for i in range(-32, 33)]
        qxlist = [-1,0,1]
        qylist = [-1,0,1]
        qzlist = [-1,0,1]
   
        filelist = []
        for ipx in pxlist:
            for ipy in pylist:
                for ipz in pzlist:
                    for its in tslist:
                        for ig in glist:
                            for iX in Xlist:
                                for iqx in qxlist: 
                                    for iqy in qylist:
                                        for iqz in qzlist:

                                            f_name_part1 = '*.qpdf.SS.meson.ama.PX'+str(ipx)+'_PY'+str(ipy)+'_PZ'+str(ipz)+'_dt'+str(its)
                                            f_name_part2 = '.X'+str(iX)+'.'+str(ig)+'.qx'+str(iqx)+'_qy'+str(iqy)+'_qz'+str(iqz)
                                            f_save = data_out + '/' + f_name_part1.replace('*.','') + f_name_part2
                                            f_save = f_save.replace('ama.','ama.'+str(bxplist[ipx])+hyp+'.')

                                            f_p = [f_save]
                                            for i in range(0, len(data_in)):
                                                f_dir_i = data_in[i]+'/*/'+ig+'/PX'+str(ipx)+'_PY'+str(ipy)+'_PZ'+str(ipz)+'_dt'+str(its)+'/'
                                                f_read_sample_i = f_dir_i+f_name_part1+f_name_part2
                                                f_i = [f_read_sample_i] + list(cfglist[i])
                                                f_p += [f_i]
                                            filelist += [f_p]

        # Make the Pool of workers
        pool = ThreadPool(1)
        results = pool.map(collectdata, filelist) 
        # close the pool and wait for the work to finish
        pool.close()
        pool.join()

    elif "c3pt" in data_in[0] and "integrated" in data_in[0]:
        print("Integrated combination of c3pt data.")

        cfglist = []
        for i in range(0, len(cfg_file)):
            i_cfglist = np.loadtxt(cfg_file[i],int)
            cfglist += [i_cfglist]
        bxplist = ['bxp20_bxp20', 'bxp20_bxp20', 'bxp20_bxp20', 'bxp20_bxp20', 'bxp50_bxp50', 'bxp50_bxp50', 'bxp50_bxp50', 'bxp50_bxp50', 'bxp50_bxp50', 'bxp50_bxp50']
        hyp='_hyp'
        pxlist = [9]
        #pxlist = [0,1,2,3,4,5,6,7,8,9]
        pylist = [0]
        pzlist = [0]
        tslist = [10]
        #tslist = [6,8,10]

        glist = ['g0']
        #glist = ['g0','g1','g2','g4','g8']
        Xlist = [-i for i in range(-32, 0)] + [i for i in range(-32, 1)]
        qxlist = [-2,-1,0,1,2]
        qylist = [-2,-1,0,1,2]
        qzlist = [-2,-1,0,1,2]
     
        collect_list = []    
        print('xlist:',Xlist)
        for ig in glist:
            for ipx in pxlist:
                for ipy in pylist:
                    for ipz in pzlist:
                        for its in tslist:

                            filelist = []
                            f_name_part1 = '*.qpdf.SS.meson.ama.PX'+str(ipx)+'_PY'+str(ipy)+'_PZ'+str(ipz)+'_dt'+str(its)
                            f_i = []
                            for i in range(0, len(data_in)):
                                f_dir_i = data_in[i]+'/*/'+ig+'/PX'+str(ipx)+'_PY'+str(ipy)+'_PZ'+str(ipz)+'_dt'+str(its)+'/'
                                f_read_sample_i = f_dir_i+f_name_part1+'.'+str(ig)
                                f_i += [[f_read_sample_i] + list(cfglist[i])]
                            #print('Read data:', f_i)
                             
                            f_save = [] 
                            for iX in Xlist:
                                for iqx in qxlist:
                                    for iqy in qylist:
                                        for iqz in qzlist:

                                            f_name_part2 = '.X'+str(iX)+'.'+str(ig)+'.qx'+str(iqx)+'_qy'+str(iqy)+'_qz'+str(iqz)
                                            i_f_save = data_out + '/' + ig + '/' + f_name_part1.replace('*.','') + f_name_part2
                                            i_f_save = i_f_save.replace('ama.','ama.'+str(bxplist[ipx])+hyp+'.')

                                            f_save += [i_f_save]
                            collect_list += [[f_save,f_i]]
                            collectdata_integrated([f_save,f_i])
        # Make the Pool of workers
        #pool = multiprocessing.Pool()
        #results = pool.map(collectdata_integrated, collect_list)
        # close the pool and wait for the work to finish
        #pool.close()
        #pool.join() 
