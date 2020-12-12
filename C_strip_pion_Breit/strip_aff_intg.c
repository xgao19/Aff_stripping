#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <complex.h>
#include <math.h>
#include "stable.h"
#include "node.h"
#include "aff.h"

#define Nstr 200 //MAX number of inversion srcs

int linecount(char *filename);
char **readstring(char *filename, int strcount);
double ***sl_stripping(char *fileswithpath);
double ***bias_stripping(char *exfileswithpath);
double ***ama_stripping(double ***bias_matrix, double ***sl_matrix, int *matrixsize);
void save_stripping(double ***data_matrix, char **name_space, int *matrixsize);
void save_stripping_single(double ***data_matrix, char *name_space, int *matrixsize);
int read_datasize(const char *file_name, char **path_name, int path_size);
char *strrpc(char *str,char *oldstr,char *newstr);
int *read_matrixsize(char *fileswithpath);

static const char *type_name(enum AffNodeType_e t);
static void print_name(const char *name);
double _Complex *process_node(struct AffNode_s *n, struct AffReader_s *arg);
double _Complex **do_read(const char *file_name, char **path_name, int path_size);

int main(int argc, char *argv[])
{
    int i;

    if (argc == 1){
        printf("ex, sl, or ama stripping.\n");
        printf("Example command format:\n");
        printf("./run bias datafiles.txt namefile.txt\n");
        printf("./run ex datafiles.txt namefile.txt\n");
        printf("./run sl datafiles.txt namefile.txt\n");
        printf("./run ama exdatafiles sldatafiles.txt namefile.txt\n");
    }
    else if (!strcmp(argv[1],"ex") || !strcmp(argv[1],"sl")){
        if(argc != 4){
            printf("./run ex datafiles.txt namefile.txt\n");
            printf("./run sl datafiles.txt namefile.txt\n");
            return 0;
        }
        char *datafiles = argv[2];
        char *namefile = argv[3];
        int *matrixsize = read_matrixsize(datafiles);
        double ***ave_data = sl_stripping(datafiles);
        //char **name_space = readstring(namefile, matrixsize[0]);
        //save_stripping(ave_data, name_space, matrixsize);
        save_stripping_single(ave_data, namefile, matrixsize);
    }
    else if (!strcmp(argv[1],"bias")){
        if(argc != 4){
            printf("./run bias exdatafiles.txt namefile.txt\n");
            return 0;
        }
        char *exdatafiles = argv[2];
        char *namefile = argv[3];
        double ***bias_data = bias_stripping(exdatafiles);
        int *matrixsize = read_matrixsize(exdatafiles);
        //char **name_space = readstring(namefile, matrixsize[0]);
        //save_stripping(bias_data, name_space, matrixsize);
        save_stripping_single(bias_data, namefile, matrixsize);
    }
    else if (!strcmp(argv[1],"ama")){
        if(argc != 5){
           printf("./run ama exdatafiles sldatafiles.txt namefile.txt\n"); 
           return 0;
        }
        char *exdatafiles = argv[2];
        char *sldatafiles = argv[3];
        char *namefile = argv[4];
        double ***bias_data = bias_stripping(exdatafiles);
        double ***sl_data = sl_stripping(sldatafiles);
        int *matrixsize = read_matrixsize(exdatafiles);
        double ***ama_data = ama_stripping(bias_data, sl_data, matrixsize);
        
        //char **name_space = readstring(namefile, matrixsize[0]);
        //save_stripping(ama_data, name_space, matrixsize);
        save_stripping_single(ama_data, namefile, matrixsize);   
    }
    
    return 0;
}

void save_stripping(double ***data_matrix, char **name_space, int *matrixsize){
 
     int i,j;
     for(i=0;i<matrixsize[0];i++){
     
         FILE *fp = fopen(name_space[i],"w");
         for(j=0; j<matrixsize[1];j++){
             fprintf(fp, "%5d %25.16e %25.16e\n", j, data_matrix[i][j][0], data_matrix[i][j][1]); 
         }       
         fclose(fp);

     }    
   
}

void save_stripping_single(double ***data_matrix, char *name_space, int *matrixsize){
    
     int i,j;
     FILE *fp = fopen(name_space,"w");
     for(i=0;i<matrixsize[0];i++){

         for(j=0; j<matrixsize[1];j++){
             fprintf(fp, "%5d %25.16e %25.16e\n", j, data_matrix[i][j][0], data_matrix[i][j][1]);
         }
     }
     fclose(fp);

}


double ***ama_stripping(double ***bias_matrix, double ***sl_matrix, int *matrixsize){
    printf("---AMA matrix collecting begin!\n");
    int i,j,k;
    double ***ama_data = malloc(matrixsize[0] * sizeof (double **));
    for(i=0;i<matrixsize[0];i++){
        ama_data[i] = malloc(matrixsize[1] * sizeof (double *));
        for(j=0;j<matrixsize[1];j++){
            ama_data[i][j] = malloc(matrixsize[2] * sizeof (double));
            for(k=0;k<matrixsize[2];k++){
                ama_data[i][j][0] = bias_matrix[i][j][0] + sl_matrix[i][j][0];
                ama_data[i][j][1] = bias_matrix[i][j][1] + sl_matrix[i][j][1];
            }
        }
    }
    printf("---AMA matrix collecting done!\n");
    return ama_data;
 
}

double ***bias_stripping(char *exfileswithpath){

    printf("---Bias matrix between exact and sloppy collecting begin!\n");

    FILE *fp;
    char line[Nstr+1];
    char *temp;
    char *ex_aff;
    char *sl_aff;
    char *pathfile;
    char **paths;

    int aff_count = linecount(exfileswithpath);
    double _Complex ***ex_samples = malloc(aff_count * sizeof (double _Complex **));
    double _Complex ***sl_samples = malloc(aff_count * sizeof (double _Complex **));

    int i;
    int datasize = 0;
    int path_count = 0;

    if( (fp=fopen(exfileswithpath,"r")) == NULL ){
        printf("Cannot open file: %s\n", exfileswithpath);
        exit(1);
    }

    for(i=0; i<aff_count; i++){
        fgets(line, Nstr, fp);
        temp = strtok(line, ",");
        ex_aff = temp;
        temp = strtok(NULL, ",");
        pathfile = strtok(temp,"\n");
        printf("ex aff files %d in %d, %s\npathfile:%s\n",i+1,aff_count,ex_aff,pathfile);
        if(path_count == 0){
            path_count = linecount(pathfile);
        }
        paths = readstring(pathfile, path_count);
        if(datasize ==0){
            datasize = read_datasize(ex_aff, paths, path_count);
        }
        ex_samples[i] = do_read(ex_aff, paths, path_count);
        sl_aff = strrpc(ex_aff,"ex","sl");
        printf("sl_aff:%s\n",sl_aff);
        sl_samples[i] = do_read(sl_aff, paths, path_count);
        free(paths);
    }
    fclose(fp);
    
    int j,k;
    double ***bias_data = malloc(path_count * sizeof (double **));
    for(i=0;i<path_count;i++){
        bias_data[i] = malloc(datasize * sizeof (double *));
        for(j=0;j<datasize;j++){
            bias_data[i][j] = malloc(2 * sizeof (double));
            bias_data[i][j][0] = 0;
            bias_data[i][j][1] = 0;
            for(k=0;k<aff_count; k++){
                bias_data[i][j][0] += creal(ex_samples[k][i][j])-creal(sl_samples[k][i][j]);
                bias_data[i][j][1] += cimag(ex_samples[k][i][j])-cimag(sl_samples[k][i][j]);
            }
            bias_data[i][j][0] /= aff_count;
            bias_data[i][j][1] /= aff_count;
        }
    }

    printf("---Bias matrix between exact and sloppy collecting done!\n\n");

    return bias_data;
}




double ***sl_stripping(char *fileswithpath){
    printf("---Sloppy matrix collecting begin!\n");   
    FILE *fp;
    char line[Nstr+1];
    int aff_count = linecount(fileswithpath);
    char *temp;
    char *aff;
    char *pathfile;
    char **paths;
    double _Complex ***sl_samples = malloc(aff_count * sizeof (double _Complex **));
    int i;
    int datasize = 0;
    int path_count = 0;

    if( (fp=fopen(fileswithpath,"r")) == NULL ){
        printf("Cannot open file: %s\n", fileswithpath);
        exit(1);
    }
    for(i=0; i<aff_count; i++){
        fgets(line, Nstr, fp);
        temp = strtok(line, ",");
        aff = temp;
        temp = strtok(NULL, ",");
        pathfile = strtok(temp,"\n");
        printf("aff file:%s\npathfile:%s\n",aff,pathfile);
        if(path_count == 0){
            path_count = linecount(pathfile);
        }
        paths = readstring(pathfile, path_count);
        //printf("pathcheck:%s\n",paths[0]);
        if(datasize ==0){
            datasize = read_datasize(aff, paths, path_count);
        }
        sl_samples[i] = do_read(aff, paths, path_count);
        free(paths);
    }
    fclose(fp);
    printf("@@@Collecting information: aff_count:%d, path_count:%d, datasize:%d\n",aff_count,path_count,datasize);
    
    int j,k;
    double ***ave_data = malloc(path_count * sizeof (double **));
    for(i=0;i<path_count;i++){
        ave_data[i] = malloc(datasize * sizeof (double *));
        for(j=0;j<datasize;j++){
            ave_data[i][j] = malloc(2 * sizeof (double));
            ave_data[i][j][0] = 0;
            ave_data[i][j][1] = 0;
        }
    } 

    for(i=0;i<aff_count; i++){
        for(j=0;j<path_count; j++){
            for(k=0;k<datasize; k++){
            //    printf("   c[%5d]: %25.16e %25.16e\n", j, creal(sl_samples[i][j][k]),cimag(sl_samples[i][j][k]));
            ave_data[j][k][0] += creal(sl_samples[i][j][k]);
            ave_data[j][k][1] += cimag(sl_samples[i][j][k]);
            }
        }
    } 
    for(j=0;j<path_count; j++){
        for(k=0;k<datasize; k++){
            ave_data[j][k][0] /= aff_count;
            ave_data[j][k][1] /= aff_count;
            //printf("path[%5d] %25.16e %25.16e\n", j, ave_data[j][k][0], ave_data[j][k][1]);
        }
    }
    printf("---Sloppy matrix collecting done!\n\n");
    return ave_data;
}

int linecount(char *filename){

    FILE *fp;
    char path[Nstr+1];
    int count = 0;

    if( (fp=fopen(filename,"r")) == NULL ){
        printf("Ah, cannot open file: %s\n", filename);
        exit(1);
    }
    while(fgets(path, Nstr, fp) != NULL){
        //printf("%s", path);
        count++;   
    }
    fclose(fp);
    return count;
}

char **readstring(char *filename, int strcount){
   //printf("trying to open:%s\n",filename);

   char **strings = malloc(strcount * sizeof (char *));
   //char strings[strcount][Nstr+1];   

   FILE *fp;
   //char *str = malloc(Nstr * sizeof (char));
   int i;   

   if( (fp=fopen(filename,"r")) == NULL ){
       printf("Oops, cannot open file: %s\n", filename);
       exit(1);
   }
   for(i=0;i<strcount;i++){
       char *str = malloc(Nstr * sizeof (char));
       fgets(str, Nstr, fp);
       str = strtok(str,"\n");
       strings[i] = str;
       //printf("path read:%s\n",strings[i]);
   }
   fclose(fp);
   return strings;
}

int *read_matrixsize(char *fileswithpath){

    printf("---Read matrixsize for saving.."); 
    FILE *fp;
    char line[Nstr+1];
    char *temp;
    char *aff;
    char *pathfile;
    char **paths;
    int i;
    int datasize = 0;
    int path_count = 0;
    int *matrixsize = malloc(3 * sizeof (int));
    if( (fp=fopen(fileswithpath,"r")) == NULL ){
        printf("Cannot open file: %s\n", fileswithpath);
        exit(1);
    }
    fgets(line, Nstr, fp);
    temp = strtok(line, ",");
    aff = temp;
    temp = strtok(NULL, ",");
    pathfile = strtok(temp,"\n");
    //printf("aff file:%s\npathfile:%s\n",aff,pathfile);
    if(path_count == 0){
        path_count = linecount(pathfile);
    }
    paths = readstring(pathfile, path_count);
    if(datasize ==0){
        datasize = read_datasize(aff, paths, path_count);
    }
    free(paths);
    fclose(fp);
    printf("Matrixsize: path_count:%d, datasize:%d\n",path_count,datasize);
    matrixsize[0] = path_count;
    matrixsize[1] = datasize; 
    matrixsize[2] = 2;
    printf("---Read matrixsize done\n\n"); 
    return matrixsize;  
}


/*
 *  tools
 */
char *strrpc(char *str,char *oldstr,char *newstr){
    char *bstr = malloc(strlen(str) * sizeof(char));//转换缓冲区
    memset(bstr,0,sizeof(bstr));
    int i;
    for(i = 0;i < strlen(str);i++){
        //printf("debug %s %s\n",str,bstr);
        if(!strncmp(str+i,oldstr,strlen(oldstr))){//查找目标字符串
            strcat(bstr,newstr);
            i += strlen(oldstr) - 1;
        }else{
                strncat(bstr,str + i,1);//保存一字节进缓冲区
            }
    }
    //printf("debug %s %s\n",str,bstr);
    return bstr;
}









/*
 * aff read stuff
 */
static const char *
type_name(enum AffNodeType_e t)
{
    static char buffer[100];

    switch (t) {
    case affNodeVoid:    return "v";
    case affNodeChar:    return "s";
    case affNodeInt:     return "i";
    case affNodeDouble:  return "d";
    case affNodeComplex: return "c";
    default:
	sprintf(buffer, "[t%d]", t);
	return buffer;
    }
}

static void
print_name(const char *name)
{
    if (name == 0) {
	printf("NULL\n");
	return;
    }
    printf("\"");
    for (;*name; name++) {
	unsigned char v = *name;
	if (v < 32 || v > 126 || v == '\\' || v == '\"')
	    printf("\\x%02x", v);
	else
	    printf("%c", v);
    }
    printf("\"\n");
}

double _Complex *
process_node(struct AffNode_s *n, struct AffReader_s *arg)
{
    struct AffReader_s *f = arg;
    uint64_t n_id = aff_node_id(n);
    enum AffNodeType_e n_type = aff_node_type(n);
    uint64_t n_parent = aff_node_id(aff_node_parent(n));
    uint32_t n_size = aff_node_size(n);

    switch (n_type) {
    default:
	break;
    case affNodeComplex: {
        //double _Complex *t = new double _Complex [n_size];
	double _Complex *t = malloc(n_size * sizeof (double _Complex));
	uint32_t i;
	if (t == 0)
	    goto error;
	aff_node_get_complex(f, n, t, n_size);
    return t;
    }
    }
error:
    fprintf(stderr, "*** not enough memory\n");
    exit(1);
}


double _Complex **
do_read(const char *file_name, char **path_name, int path_size)
{
    struct AffNode_s *n;
    struct AffReader_s *f;
    const char *status;
    
    // Read the aff file
    printf("@@@Trying to read %s\n\n", file_name);
    f = aff_reader(file_name);
    status = aff_reader_errstr(f);
    if (status) {
	printf("reader open error: %s\n", status);
	aff_reader_close(f);
	//return;
    }
    n = aff_reader_root(f);

    // Collect all the complex data matrix
    int i;
    //double _Complex **datalist = new double _Complex *[path_size];
    double _Complex **datalist = malloc(path_size * sizeof (double _Complex *));
    struct AffNode_s *path_data;
    for (i=0; i<path_size; i++) {
        //printf("pathname: %s\n",path_name[i]);
        path_data = aff_reader_chpath(f, n, path_name[i]);
        //uint32_t n_size = aff_node_size(path_data);
        double _Complex *t = process_node(path_data,f);
        datalist[i] = t;
    }

    aff_reader_close(f);
    return datalist;
}

int read_datasize(const char *file_name, char **path_name, int path_size){
       
    struct AffNode_s *n;
    struct AffReader_s *f;
    const char *status;

    printf("\n@@@Trying to read the data size from one sample:%s\n", file_name);
    f = aff_reader(file_name);
    status = aff_reader_errstr(f);
    if (status) {
        printf("reader open error: %s\n", status);
        aff_reader_close(f);
        return;
        } 
        n = aff_reader_root(f);
    struct AffNode_s *path_data;
    path_data = aff_reader_chpath(f, n, path_name[0]);
    int datasize = aff_node_size(path_data);
    aff_reader_close(f);
    return datasize;
}
