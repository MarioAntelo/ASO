/*
*
* Martín Piñas Ayala 	Grupo 2.1
* Jonatan Romera Millán Grupo 2.1
*
*/

// Shell `simplesh`
#define _XOPEN_SOURCE 500 

#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include <pwd.h> 	//Práctica - Boletín 2 - Ejercicio 2. Definida para getcwd()
#include <libgen.h>     //Práctica - Boletín 2 - Ejercicio 2. Definida para "basename()" POSIX
#include <errno.h>      //Práctica - Boletín 2 - Ejercicio 5. Definida para los errores de chdir()
#include <getopt.h>     //Práctica - Boletin 3. Definida para getopt()
#include <time.h>       //Práctica - Boletin 3. Definida para Opcional
#include <ftw.h> 	//Práctica - Boletin 4. Definida para nftw
#include <inttypes.h>   //Práctica - Boletin 4. Definida para abs

// Libreadline
#include <readline/readline.h>
#include <readline/history.h>

// Tipos presentes en la estructura `cmd`, campo `type`.
#define EXEC  1
#define REDIR 2
#define PIPE  3
#define LIST  4
#define BACK  5

#define MAXARGS 15
#define MAXPATH 2048 	//Práctica - Definida para tamaño maximo currentDir
#define SIZE_BUFFER 512 //Práctica - Definida para tamaño maximo buffer del read
#define BLOCK_SIZE 512  //Práctica - Definida para tamaño del bloque Boletin 4

//Práctica - Variables Globales
long long size_Bytes = 0;	//Práctica - Boletin 4. Definida para almacenar el tamaño de un fichero o de un directorio en el comando du
int size_File = 0; 		//Práctica - Boletin 4. Definida para almacenar el argumento de -t del comando du
int cont_Signal_Handler = 0;	//Práctica - Boletin 5. Definida para almacenar el número de veces que se llama al manejador de CHLD

// Estructuras
// -----

// La estructura `cmd` se utiliza para almacenar la información que
// servirá al shell para guardar la información necesaria para
// ejecutar las diferentes tipos de órdenes (tuberías, redirecciones,
// etc.)
//
// El formato es el siguiente:
//
//     |----------+--------------+--------------|
//     | (1 byte) | ...          | ...          |
//     |----------+--------------+--------------|
//     | type     | otros campos | otros campos |
//     |----------+--------------+--------------|
//
// Nótese cómo las estructuras `cmd` comparten el primer campo `type`
// para identificar el tipo de la estructura, y luego se obtendrá un
// tipo derivado a través de *casting* forzado de tipo. Se obtiene así
// un polimorfismo básico en C.
struct cmd {
    int type;
};

// Ejecución de un comando con sus parámetros
struct execcmd {
    int type;
    char * argv[MAXARGS];
    char * eargv[MAXARGS];
};

// Ejecución de un comando de redirección
struct redircmd {
    int type;
    struct cmd *cmd;
    char *file;
    char *efile;
    int mode;
    int fd;
};

// Ejecución de un comando de tubería
struct pipecmd {
    int type;
    struct cmd *left;
    struct cmd *right;
};

// Lista de órdenes
struct listcmd {
    int type;
    struct cmd *left;
    struct cmd *right;
};

// Tarea en segundo plano (background) con `&`.
struct backcmd {
    int type;
    struct cmd *cmd;
};

// Declaración de funciones necesarias
int fork1(void);  // Fork but panics on failure.
void panic(char*);
struct cmd *parse_cmd(char*);

//Funciones definidas para la práctica 

/*
* Práctica - Boletín 2. Ejercicio 3
* Función para determinar en el directorio en que 
* nos encontramos actualmente. 
*/
void run_pwd(){
	//Salida de error
	fprintf(stderr, "%s", "simplesh: pwd: ");

	//Conseguir directorio actual
    	char currentDirPath[MAXPATH];
    	if (getcwd(currentDirPath, MAXPATH) == NULL){
		perror("getcwd");
		exit(EXIT_FAILURE);
    	}

	//Salida stdout
	fprintf(stdout, "%s\n", currentDirPath);
}

/*
* Práctica - Boletín 2. Ejercicio 4
* Función que determina si un comando es un comando ejecutable y
* si es el comando "exit".
*/
int is_Exec_Command_Exit(struct cmd *cmd){
    	struct execcmd *ecmd;
 	switch(cmd->type){
    		case EXEC:
        		ecmd = (struct execcmd*)cmd;
			if (strcmp("exit", ecmd->argv[0]) == 0)
				return 0;
			break;
    	}
	return 1;	
}

/*
* Práctica - Boletín 2. Ejercicio 5
* Función que determina si un comando es un comando ejecutable y
* si es el comando "cd".
*/
int is_Exec_Command_Cd(struct cmd *cmd){
    	struct execcmd *ecmd;
 	switch(cmd->type){
    		case EXEC:
        		ecmd = (struct execcmd*)cmd;
			if(strcmp("cd", ecmd->argv[0]) == 0)
				return 0;
			break;
    	}
	return 1;	
}


/*
* Práctica - Boletín 2. Ejercicio 5
* Función que se va a encargar de cambiar a un directorio dado, o 
* al directorio $HOME si no se ha introducido ningún directorio. 
*/
void run_cd(struct cmd *cmd){

	struct execcmd *ecmd;
	ecmd = (struct execcmd*)cmd;

	char *dir;

	if(ecmd->argv[1] == NULL){
		if (getenv("HOME") == NULL){
			perror("getenv");
			exit(EXIT_FAILURE);
		}
		else{
			dir = getenv("HOME");
			if (dir == NULL){
				perror("getenv");
				exit(EXIT_FAILURE);
			}
		}
	}
	else{
		dir = ecmd->argv[1];
	}
	
	if(chdir(dir) == -1){
		perror("chdir");
		exit(EXIT_FAILURE);
	}
}

/*
* Práctica - Boletín 3
* Función que se va a encargar de ejecutar el comando tee
* el cual se encarga de copiar la entrada estándar STDIN
* a cada uno de los ficheros que se le indique y a la
* salida estándar STDOUT.
*/
void run_tee(struct cmd *cmd){
	struct execcmd *ecmd;
	ecmd = (struct execcmd*)cmd;

	int aflag = 0;
	int hflag = 0;
	int c;

	int num_Arg;
	for (num_Arg = 0; ecmd->argv[num_Arg] != NULL; num_Arg++);

	while ((c = getopt(num_Arg, ecmd->argv, "ha")) != -1){
		switch (c){
			case 'h':
				hflag = 1;
				break;
			case 'a':
				aflag = 1;
				break;
			default:
				perror("getopt");
				exit(EXIT_FAILURE);
		}
	}

	if(hflag == 1){
		printf("Uso: tee [-h] [-a] [FICHERO] ...\n");
		printf("\tCopia stdin a cada FICHERO y a stdout.\n");
		printf("\tOpciones:\n");
		printf("\t-a Añade al final de cada FICHERO\n");
		printf("\t--h help\n");
	}

	int index_num_files;
	int num_files = num_Arg - optind;

	int files_opened[num_files+1];  //Array que almacena los descriptores de fichero de cada fichero que pueda ser abierto. 
				        //Reservamos memoria para el número de fichero que hemos introducido +1 (salida STDOUT)

	files_opened[0] = 1;		//El primer elemento del array de files_opened es la salida STDOUT
	int num_files_opened = 1;       //Determina el numero de ficheros abiertos Inicializamos a 1 ya que como minimo tendrá la salida STDOUT
	
	//Recorremos los ficheros, y si pueden ser abiertos se añaden, su descriptor se añade al array files_opened.
	for (optind; optind < num_Arg; optind++){
		char *nameFile = ecmd->argv[optind];
		//open
		int fd;
		if (aflag == 1){
			fd = open(nameFile, O_RDWR|O_CREAT|O_APPEND, S_IRWXU);
		}
		else{
			fd = open(nameFile, O_RDWR|O_CREAT|O_TRUNC, S_IRWXU);
		}

		if (fd < 0){
			fprintf(stderr, "open %s failed\n", nameFile);
		}
		else{
			files_opened[num_files_opened] = fd;
			num_files_opened++;
		}		
	}

	/*
	* En el bucle de lectura y escritura lo que vamos a hacer es leer de la entrada STDIN y almacenarlo en un buffer, y dicho buffer
	* hay que escribirlo en cada uno de los ficheros indicados por el usuario y en la salida STDOUT. Por tanto, cada vez que leamos de
	* la entrada tenemos que recorrer el array de ficheros abiertos, que recordemos que tenía los descriptores de los ficheros 
	* abiertos, y escribir el contenido del buffer. 
	*/
	char buf[SIZE_BUFFER];
	//read
	int num_bytes_read = 0;
	int total_bytes_read = 0;;
	int i;
	while ((num_bytes_read = read(0, buf, SIZE_BUFFER)) > 0){
		if (num_bytes_read < 0){
			perror("read");
			exit(EXIT_FAILURE);
		}
			
		for (i = 0; i < num_files_opened; i++){
			//write
			if (write(files_opened[i], buf, num_bytes_read) < 0){
				perror("write");
				exit(EXIT_FAILURE);			
			}
		}
		total_bytes_read+=num_bytes_read;
	}

	//fsync
	for (i = 1; i < num_files_opened; i++){
		if (fsync(files_opened[i]) < 0){
			perror("fsync");
			exit(EXIT_FAILURE);
		}
	}

	//close	
	for (i = 1; i < num_files_opened; i++){
		if (close(files_opened[i]) < 0){
			perror("close");
			exit(EXIT_FAILURE);
		}
	}




	//Opcional. Añadir linea a fichero $HOME/.tee.log tras cada ejecucion 
	char *log = malloc(512);
	char *log_part = malloc(512);

	time_t t;
  	struct tm *tm;

  	t=time(NULL);
  	tm=localtime(&t);

	tm->tm_year;
	tm->tm_mon;
	tm->tm_mday;

	tm->tm_hour;
	tm->tm_min;	
	tm->tm_sec;

	pid_t pid = getpid();
	uid_t euid = geteuid();

	int num_files_opened_log = num_files_opened-1;

 	strftime(log,32,"%Y-%m-%d %H:%M:%S:",tm);
    	snprintf (log_part, 512, "PID %d:EUID: %d:%d byte(s):%d file(s)\n", pid, euid, total_bytes_read, num_files_opened_log );

	strcat(log, log_part);

	char *path_Home = malloc(sizeof(char)*64);
	if (getenv("HOME") == NULL){
			perror("getenv");
			exit(EXIT_FAILURE);
	}
	else{
		path_Home = getenv("HOME");
		if (path_Home == NULL){
			perror("getenv");
			exit(EXIT_FAILURE);
		}		

		char *path_File_Log = path_Home;
		char *name_File_Log = ".tee.log";

		strcat(path_File_Log, "/");
		strcat(path_File_Log, name_File_Log);

		int fd_log = open(path_File_Log, O_RDWR|O_CREAT|O_APPEND, S_IRWXU);

		if (fd_log < 0){
			fprintf(stderr, "open %s failed\n", path_File_Log);
		}
		else{
			//write
			if (write(fd_log, log, strlen(log)*sizeof(char)) < 0){
				perror("write");
				exit(EXIT_FAILURE);
			}
		}
	}	
	free(log);
	free(log_part);
}

/*
* Práctica - Boletín 4.
* Función que se va a encargar de sumar el tamaño del fichero que se pasa por parámetro
* a la variable global size_Bytes.
*/
 int aux_Size (const char * fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf){
	if (tflag == FTW_F){
		size_Bytes += sb->st_size;
	}
	return 0;
}

/*
* Práctica - Boletín 4.
* Función que se va a encargar de, además de sumar el tamaño del fichero que se pasa por parámetro
* a la variable global size_Bytes, imprimir el nombre del fichero/directorio y el tamaño de 
* éste, en caso de que corresponda a un fichero (en bytes).
*/
 int aux_Size_Flag_v (const char * fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf){
	int i;
	for (i=0; i<ftwbuf->level; i++){
		printf("\t");
	}

	if (tflag == FTW_D){
		printf("%s\n", fpath);
	}
	else if (tflag == FTW_F){
		printf("%s: %lld\n", fpath, (unsigned long long) sb->st_size);
		size_Bytes += sb->st_size;
	}
	return 0;
}

/*
* Práctica - Boletín 4.
* Función que se va a encargar de, además de sumar el tamaño del fichero que se pasa por parámetro
* a la variable global size_Bytes, imprimir el nombre del fichero/directorio y el tamaño de 
* éste, en caso de que corresponda a un fichero (en bloques).
*/
 int aux_Size_Flag_v_b (const char * fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf){
	for (int i=0; i<ftwbuf->level; i++){
		printf("\t");
	}

	if (tflag == FTW_D){
		printf("%s\n", fpath);
	}
	else if (tflag == FTW_F){
		printf("%s: %lld\n", fpath, (unsigned long long) sb->st_size/BLOCK_SIZE);
		size_Bytes += sb->st_size;
	}
	return 0;
}

/*
* Práctica - Boletín 4.
* Función que se va a encargar de sumar el tamaño del fichero que se pasa por parámetro
* a la variable global size_Bytes, sólo si se cumple la condición impuesta por el 
* parámetro -t.
*/
int aux_Size_Flag_t (const char * fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf){
	if (tflag == FTW_F){
		if (size_File < 0){
			int a = sb->st_size;
			if (a <= abs(size_File)){
				
				size_Bytes += sb->st_size;
			}
		}
		else if (size_File > 0){
			if (sb->st_size >= abs(size_File)){
				size_Bytes += sb->st_size;
			}
		}
	}
	return 0;
}

/*
* Práctica - Boletín 4.
* Función que se va a encargar de sumar el tamaño del fichero que se pasa por parámetro
* a la variable global size_Bytes, sólo si se cumple la condición impuesta por el 
* parámetro -t, y de imprimir los datos por la salida estándar conforme al parámetro -v (en bytes).
*/
int aux_Size_Flag_t_v (const char * fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf){

	int numTabs = 0;
	for (numTabs; numTabs < ftwbuf->level; numTabs++);

	if (tflag == FTW_D){
		while (numTabs > 0){
		 	printf("\t");
			numTabs--;
		}
		printf("%s\n", fpath);
	}
	else if (tflag == FTW_F){
		if (size_File < 0){
			if (sb->st_size <= abs(size_File)){
				size_Bytes += sb->st_size;		
				while (numTabs > 0){
		 			printf("\t");
					numTabs--;
				}
				printf("%s: %lld\n", fpath, (unsigned long long) sb->st_size);
			}
		}
		else if (size_File > 0){
			if (sb->st_size >= abs(size_File)){
				size_Bytes += sb->st_size;
				while (numTabs > 0){
		 			printf("\t");
					numTabs--;
				}
				printf("%s: %lld\n", fpath, (unsigned long long) sb->st_size);
			}
		}
		else printf("%s: %lld\n", fpath, (unsigned long long) sb->st_size);
	}
	return 0;
}

/*
* Práctica - Boletín 4.
* Función que se va a encargar de sumar el tamaño del fichero que se pasa por parámetro
* a la variable global size_Bytes, sólo si se cumple la condición impuesta por el 
* parámetro -t, y de imprimir los datos por la salida estándar conforme al parámetro -v (en bloques).
*/
int aux_Size_Flag_t_b_v (const char * fpath, const struct stat *sb, int tflag, struct FTW *ftwbuf){
	int numTabs = 0;
	for (numTabs; numTabs<ftwbuf->level; numTabs++);

	if (tflag == FTW_D){
		while (numTabs > 0){
		 	printf("\t");
			numTabs--;
		}
		printf("%s\n", fpath);
	}
	else if (tflag == FTW_F){
		if (size_File < 0){
			if (sb->st_size <= abs(size_File)){
				size_Bytes += sb->st_size;
				while (numTabs > 0){
		 			printf("\t");
					numTabs--;
				}
				printf("%s: %lld\n", fpath, (unsigned long long) sb->st_size/BLOCK_SIZE);
			}
		}
		else if (size_File > 0){
			if (sb->st_size >= abs(size_File)){
				size_Bytes += sb->st_size;
				while (numTabs > 0){
		 			printf("\t");
					numTabs--;
				}
				printf("%s: %lld\n", fpath, (unsigned long long) sb->st_size/BLOCK_SIZE);
			}
		}
		else printf("%s: %lld\n", fpath, (unsigned long long) sb->st_size/BLOCK_SIZE);
	}
	return 0;
}

/*
* Práctica - Boletín 4.
* Función que se va a encargar de determinar si el parámetro pasado a -t es un número. 
*/
int is_Number(char *size_File_Exclude){
	char *array_Num = "0123456789";
	int char_is_number = 0;
	int i;
	int j;
	if (size_File_Exclude[0] == '-'){
		i = 1;
	}else{
		i = 0;
	}
	
	for (i; i<strlen(size_File_Exclude); i++){
		for (j = 0; j < strlen(array_Num); j++){
			if (size_File_Exclude[i] == array_Num[j]){
				char_is_number = 1;
				break;
			}
		}
		if(char_is_number == 1){
			char_is_number = 0;
		}
		else return 0;
	}
	return 1;
}

void print_du(char *nameFileDir, int bflag, int vflag, int tflag){
	struct stat st;
	if (stat(nameFileDir, &st) == -1){
		perror("stat");
		exit(EXIT_FAILURE);
	}

	char *dirOrFile;
	if(S_ISDIR(st.st_mode))
    		dirOrFile = "(D)";
  	else
    		dirOrFile = "(F)";
	
	if (vflag == 1 && S_ISDIR(st.st_mode) == 1){
		if (bflag == 1){
			if (tflag == 1){
				if (nftw(nameFileDir, aux_Size_Flag_t_b_v, 20, 0) == -1){
					fprintf(stderr, "No se puede acceder a directorio/fichero %s.\n", nameFileDir);	
				}
				else printf("%s %s: %lld\n", dirOrFile, nameFileDir, (unsigned long long) size_Bytes/BLOCK_SIZE);
			}
			else {
				if (nftw(nameFileDir, aux_Size_Flag_v_b, 20, 0) == -1){
					fprintf(stderr, "No se puede acceder a directorio/fichero %s.\n", nameFileDir);		
				}
				else printf("%s %s: %lld\n", dirOrFile, nameFileDir, (unsigned long long) size_Bytes/BLOCK_SIZE);
			}
		}
		else {
			if (tflag == 1){
				if (nftw(nameFileDir, aux_Size_Flag_t_v, 20, 0) == -1){	
					fprintf(stderr, "No se puede acceder a directorio/fichero %s.\n", nameFileDir);	
				}		
				else printf("%s %s: %lld\n", dirOrFile, nameFileDir, (unsigned long long) size_Bytes);
			}
			else{
				if (nftw(nameFileDir, aux_Size_Flag_v, 20, 0) == -1){	
					fprintf(stderr, "No se puede acceder a directorio/fichero %s.\n", nameFileDir);		
				}		
				else printf("%s %s: %lld\n", dirOrFile, nameFileDir, (unsigned long long) size_Bytes);
			}
		}
	}
	else{
		if (bflag == 1){
			if (tflag == 1){
				if (nftw(nameFileDir, aux_Size_Flag_t, 20, 0) == -1){	
					fprintf(stderr, "No se puede acceder a directorio/fichero %s.\n", nameFileDir);	
				}		
				else if (size_Bytes > 0) 
					printf("%s %s: %lld\n", dirOrFile, nameFileDir, (unsigned long long) size_Bytes/BLOCK_SIZE);
			}
			else {
				if (nftw(nameFileDir, aux_Size, 20, 0) == -1){	
					fprintf(stderr, "No se puede acceder a directorio/fichero %s.\n", nameFileDir);	
				}		
				else printf("%s %s: %lld\n", dirOrFile, nameFileDir, (unsigned long long) size_Bytes/BLOCK_SIZE);
			}
		}
		else if (tflag == 1){
			if (nftw(nameFileDir, aux_Size_Flag_t, 20, 0) == -1){	
				fprintf(stderr, "No se puede acceder a directorio/fichero %s.\n", nameFileDir);		
			}		
			else if (size_Bytes > 0) 
				printf("%s %s: %lld\n", dirOrFile, nameFileDir, (unsigned long long) size_Bytes);
		}
		else {
			if (nftw(nameFileDir, aux_Size, 20, 0) == -1){	
					fprintf(stderr, "No se puede acceder a directorio/fichero %s.\n", nameFileDir);	
			}		
			else printf("%s %s: %lld\n", dirOrFile, nameFileDir, (unsigned long long) size_Bytes);
			
		}
	}
}

/*
* Práctica - Boletín 4.
* Función que se va a encargar de ejecutar el comando du.
*/
void run_du(struct cmd *cmd){
	struct execcmd *ecmd;
	ecmd = (struct execcmd*)cmd;

	int bflag = 0;
	int hflag = 0;
	int tflag = 0;
	int vflag = 0;
	int c;

	int num_Arg;
	for( num_Arg = 0; ecmd->argv[num_Arg] != NULL; num_Arg++);

	while ((c = getopt(num_Arg, ecmd->argv, "bhvt:")) != -1){
		switch (c){
			case 'b':
				bflag = 1;
				break;
			case 'h':
				hflag = 1;
				break;
			case 'v':
				vflag = 1;
				break;
			case 't':
				tflag = 1;
				char *size_File_Exclude = optarg;
				if (is_Number(size_File_Exclude) == 1){
					size_File = atoi(size_File_Exclude);
				}
				else{
        				fprintf(stderr, "Argumento de -t debe ser un número.\n");
					exit(EXIT_FAILURE);
				}
				break;
			default:
				perror("getopt");
				exit(EXIT_FAILURE);
				
		}
	}

	if (hflag == 1){
		printf("Uso: du [-h] [-b] [-t SIZE] [FICHERO|DIRECTORIO] ...\n");
		printf("Para cada fichero fichero, imprime su tamaño\n");
		
		printf("\tOpciones:\n");
		printf("\t-b Imprime el tamaño ocupado en disco por todos los bloques del fichero.\n");
		printf("\t-t SIZE Excluye todos los ficheros más pequeños que SIZE bytes, si es\n");
		printf("\t   positivo, o más grandes que SIZE bytes, si es negativo, cuando se\n");
		printf("\t   procesa un directorio.\n");
		printf("\t--h help\n");
		printf("Nota: Todos los tamaños están expresados en bytes.\n");
	}
	
	int numFilesDirs = num_Arg - optind;
	if (numFilesDirs == 0 && hflag == 0){
		print_du(".", bflag, vflag, tflag);
	}
	else{
		//Recorremos los ficheros o directorios
		for (optind; optind < num_Arg; optind++){
			char *nameFileDir = ecmd->argv[optind];
			print_du(nameFileDir, bflag, vflag, tflag);
			size_Bytes = 0;
		}
	}
}


// Ejecuta un `cmd`. Nunca retorna, ya que siempre se ejecuta en un
// hijo lanzado con `fork()`.
void
run_cmd(struct cmd *cmd)
{
    int p[2];
    struct backcmd *bcmd;
    struct execcmd *ecmd;
    struct listcmd *lcmd;
    struct pipecmd *pcmd;
    struct redircmd *rcmd;

    if(cmd == 0)
        exit(0);

    switch(cmd->type)
    {
    default:
        panic("run_cmd");

        // Ejecución de una única orden.
    case EXEC:
        ecmd = (struct execcmd*)cmd;
        if (ecmd->argv[0] == 0)
            exit(0);

	//Práctica - Boletín 2 - Ejercicio 3
	if(strcmp("pwd", ecmd->argv[0]) == 0){
		run_pwd();
	} 
	//Práctica - Boletín 2 - Ejercicio 4
	else if(strcmp("exit", ecmd->argv[0]) == 0){
		exit(0);
	}	
	//Pŕactica - Boletin 3
	else if(strcmp("tee", ecmd->argv[0]) == 0){
		run_tee(cmd);
	}
	//Pŕactica - Boletin 4
	else if(strcmp("du", ecmd->argv[0]) == 0){
		//msleep(6);
		run_du(cmd);
	}
    	else{
        	execvp(ecmd->argv[0], ecmd->argv);
        	// Si se llega aquí algo falló
        	fprintf(stderr, "exec %s failed\n", ecmd->argv[0]);
        	exit (1);
	}

        break;

    case REDIR:
        rcmd = (struct redircmd*)cmd;
        close(rcmd->fd);
        if (open(rcmd->file, rcmd->mode, S_IRWXU) < 0)
        {
            fprintf(stderr, "open %s failed\n", rcmd->file);
            exit(1);
        }
        run_cmd(rcmd->cmd);
        break;

    case LIST:
        lcmd = (struct listcmd*)cmd;
        if (fork1() == 0)
            run_cmd(lcmd->left);
        wait(NULL);
        run_cmd(lcmd->right);
        break;

    case PIPE:
        pcmd = (struct pipecmd*)cmd;
        if (pipe(p) < 0)
            panic("pipe");

        // Ejecución del hijo de la izquierda
        if (fork1() == 0)
        {
            close(1);
            dup(p[1]);
            close(p[0]);
            close(p[1]);
            run_cmd(pcmd->left);
        }

        // Ejecución del hijo de la derecha
        if (fork1() == 0)
        {
            close(0);
            dup(p[0]);
            close(p[0]);
            close(p[1]);
            run_cmd(pcmd->right);
        }
        close(p[0]);
        close(p[1]);

        // Esperar a ambos hijos
        wait(NULL);
        wait(NULL);
        break;

    case BACK:
        bcmd = (struct backcmd*)cmd;
        if (fork1() == 0)
            run_cmd(bcmd->cmd);
        break;
    }

    // Salida normal, código 0.
    exit(0);
}

// Muestra un *prompt* y lee lo que el usuario escribe usando la
// librería readline. Ésta permite almacenar en el historial, utilizar
// las flechas para acceder a las órdenes previas, búsquedas de
// órdenes, etc.
char*
getcmd()
{
    //Práctica. Boletín 2- Ejercicio 2.

    //Conseguir "usuario"
    uid_t uid = getuid();
    
    struct passwd* pw;
    if ((pw = getpwuid(uid)) == NULL) {
       perror("getpwuid");
       exit(EXIT_FAILURE);
    }
  
    //Conseguir directorio actual
    char currentDirPath[MAXPATH];
    if (getcwd(currentDirPath, MAXPATH) == NULL){
	perror("getcwd");
	exit(EXIT_FAILURE);
    }
    char *currentDir;
    currentDir = basename(currentDirPath);

    char *prompt = malloc(sizeof(char)*256);
    snprintf ( prompt, 100, "%s@%s$ ", pw->pw_name, currentDir );

    char *buf;

    int retval = 0;

    // Lee la entrada del usuario
    buf = readline (prompt);

    // Si el usuario ha escrito algo, almacenarlo en la historia.
    if(buf)
        add_history (buf);

    free(prompt);
    return buf;
}

/*
* Práctica. Boletin 5. Manejador de señal CHLD
*/
void func_Signal_Handler(){
	cont_Signal_Handler++;
}

// Función `main()`.
// ----

int
main(void)
{
    char* buf;

    //Práctica. Boletin 5. Bloqueo señal SIGINT y SIGCHLD
    sigset_t blocked_signals;
    sigemptyset(&blocked_signals);
    sigaddset(&blocked_signals, SIGINT);
    sigaddset(&blocked_signals, SIGCHLD);

    if (sigprocmask(SIG_BLOCK, &blocked_signals, NULL) == -1){
	perror("sigprocmask");
	exit(EXIT_FAILURE);
    }


    //Práctica. Boletin 5. Estructura timespec que será pasada como argumento a la función sigtimedwait
    struct timespec timeout;
    timeout.tv_nsec = 0;
    timeout.tv_sec = 5;

    //Práctica. Boletin 5. Estructura sigset_t (máscara) que será pasada como argumento a la función sigtimedwait
    sigset_t mask_chld;
    sigemptyset(&mask_chld);    
    sigaddset(&mask_chld, SIGCHLD);

    //Práctica. Boletin 5. Estructura siginfo_t que será pasada como argumento a la función sigtimedwait
    siginfo_t info;

    //Práctica. Boletin 5. Instalar manejador de señal para señal SIGCHLD
    struct sigaction sigHandler;
    sigHandler.sa_handler = func_Signal_Handler;
    sigaction(SIGCHLD, &sigHandler, NULL);	

    // Bucle de lectura y ejecución de órdenes.
    while (NULL != (buf = getcmd()))
    {	
	if (strcmp("", buf) != 0){ //Práctica - Para evitar errores al pulsar Intro vacio 
		struct cmd *cmd;
		cmd = parse_cmd(buf);
		if(is_Exec_Command_Exit(cmd) == 0){
			exit(0);
		}
		else if(is_Exec_Command_Cd(cmd) == 0){
			run_cd(cmd);
		}
		else{
			int pid;
			pid = fork1();
			// Crear siempre un hijo para ejecutar el comando leído
			if(pid == 0)
			    run_cmd(cmd);
			else{
				if (sigtimedwait(&mask_chld, &info, &timeout) < 0){
						if (errno == EINTR) {
							/* Interrumpido por una señal diferente a SIGCHLD. */
							continue;
						}
						else if (errno == EAGAIN) {
							sigprocmask(SIG_UNBLOCK, &mask_chld, NULL); /*Desbloqueamos la señal SIGCHLD*/
							kill(pid, SIGKILL); /*Matamos al hijo*/
							fprintf(stderr, "simplesh: [%d] Matado hijo con PID %d\n", cont_Signal_Handler+1, pid);
						}
						else {
							perror ("sigtimedwait");
							exit(EXIT_FAILURE);
						}
				}
			}

			//Práctica. Boletin 5. Esperar al hijo creado
			if (waitpid(pid, NULL, 0) < 0){
				perror("waitpid");
				exit(EXIT_FAILURE);
			}

    			//Práctica. Boletin 5. Volvemos a bloquear la señal SIGCHLD
			if (sigprocmask(SIG_BLOCK, &mask_chld, NULL) == -1){
				perror("sigprocmask");
				exit(EXIT_FAILURE);
			}
		}
		free ((void*)buf);
	}
    }

    return 0;
}

void
panic(char *s)
{
    fprintf(stderr, "%s\n", s);
    exit(-1);
}

// Como `fork()` salvo que muestra un mensaje de error si no se puede
// crear el hijo.
int
fork1(void)
{
    int pid;

    pid = fork();
    if(pid == -1)
        panic("fork");
    return pid;
}

// Constructores de las estructuras `cmd`.
// ----

// Construye una estructura `EXEC`.
struct cmd*
execcmd(void)
{
    struct execcmd *cmd;

    cmd = malloc(sizeof(*cmd));
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = EXEC;
    return (struct cmd*)cmd;
}

// Construye una estructura de redirección.
struct cmd*
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
    struct redircmd *cmd;

    cmd = malloc(sizeof(*cmd));
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = REDIR;
    cmd->cmd = subcmd;
    cmd->file = file;
    cmd->efile = efile;
    cmd->mode = mode;
    cmd->fd = fd;
    return (struct cmd*)cmd;
}

// Construye una estructura de tubería (*pipe*).
struct cmd*
pipecmd(struct cmd *left, struct cmd *right)
{
    struct pipecmd *cmd;

    cmd = malloc(sizeof(*cmd));
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = PIPE;
    cmd->left = left;
    cmd->right = right;
    return (struct cmd*)cmd;
}

// Construye una estructura de lista de órdenes.
struct cmd*
listcmd(struct cmd *left, struct cmd *right)
{
    struct listcmd *cmd;

    cmd = malloc(sizeof(*cmd));
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = LIST;
    cmd->left = left;
    cmd->right = right;
    return (struct cmd*)cmd;
}

// Construye una estructura de ejecución que incluye una ejecución en
// segundo plano.
struct cmd*
backcmd(struct cmd *subcmd)
{
    struct backcmd *cmd;

    cmd = malloc(sizeof(*cmd));
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = BACK;
    cmd->cmd = subcmd;
    return (struct cmd*)cmd;
}

// Parsing
// ----

const char whitespace[] = " \t\r\n\v";
const char symbols[] = "<|>&;()";

// Obtiene un *token* de la cadena de entrada `ps`, y hace que `q` apunte a
// él (si no es `NULL`).
int
gettoken(char **ps, char *end_of_str, char **q, char **eq)
{
    char *s;
    int ret;

    s = *ps;
    while (s < end_of_str && strchr(whitespace, *s))
        s++;
    if (q)
        *q = s;
    ret = *s;
    switch (*s)
    {
    case 0:
        break;
    case '|':
    case '(':
    case ')':
    case ';':
    case '&':
    case '<':
        s++;
        break;
    case '>':
        s++;
        if (*s == '>')
        {
            ret = '+';
            s++;
        }
        break;

    default:
        // El caso por defecto (no hay caracteres especiales) es el de un
        // argumento de programa. Se retorna el valor `'a'`, `q` apunta al
        // mismo (si no era `NULL`), y `ps` se avanza hasta que salta todos
        // los espacios **después** del argumento. `eq` se hace apuntar a
        // donde termina el argumento. Así, si `ret` es `'a'`:
        //
        //     |-----------+---+---+---+---+---+---+---+---+---+-----------|
        //     | (espacio) | a | r | g | u | m | e | n | t | o | (espacio) |
        //     |-----------+---+---+---+---+---+---+---+---+---+-----------|
        //                   ^                                   ^
        //                   |q                                  |eq
        //
        ret = 'a';
        while (s < end_of_str && !strchr(whitespace, *s) && !strchr(symbols, *s))
            s++;
        break;
    }

    // Apuntar `eq` (si no es `NULL`) al final del argumento.
    if (eq)
        *eq = s;

    // Y finalmente saltar los espacios en blanco y actualizar `ps`.
    while(s < end_of_str && strchr(whitespace, *s))
        s++;
    *ps = s;

    return ret;
}

// La función `peek()` recibe un puntero a una cadena, `ps`, y un final de
// cadena, `end_of_str`, y un conjunto de tokens (`toks`). El puntero
// pasado, `ps`, es llevado hasta el primer carácter que no es un espacio y
// posicionado ahí. La función retorna distinto de `NULL` si encuentra el
// conjunto de caracteres pasado en `toks` justo después de los posibles
// espacios.
int
peek(char **ps, char *end_of_str, char *toks)
{
    char *s;

    s = *ps;
    while(s < end_of_str && strchr(whitespace, *s))
        s++;
    *ps = s;

    return *s && strchr(toks, *s);
}

// Definiciones adelantadas de funciones.
struct cmd *parse_line(char**, char*);
struct cmd *parse_pipe(char**, char*);
struct cmd *parse_exec(char**, char*);
struct cmd *nulterminate(struct cmd*);

// Función principal que hace el *parsing* de una línea de órdenes dada por
// el usuario. Llama a la función `parse_line()` para obtener la estructura
// `cmd`.
struct cmd*
parse_cmd(char *s)
{
    char *end_of_str;
    struct cmd *cmd;

    end_of_str = s + strlen(s);
    cmd = parse_line(&s, end_of_str);

    peek(&s, end_of_str, "");
    if (s != end_of_str)
    {
        fprintf(stderr, "restante: %s\n", s);
        panic("syntax");
    }

    // Termina en `'\0'` todas las cadenas de caracteres de `cmd`.
    nulterminate(cmd);

    return cmd;
}

// *Parsing* de una línea. Se comprueba primero si la línea contiene alguna
// tubería. Si no, puede ser un comando en ejecución con posibles
// redirecciones o un bloque. A continuación puede especificarse que se
// ejecuta en segundo plano (con `&`) o simplemente una lista de órdenes
// (con `;`).
struct cmd*
parse_line(char **ps, char *end_of_str)
{
    struct cmd *cmd;

    cmd = parse_pipe(ps, end_of_str);
    while (peek(ps, end_of_str, "&"))
    {
        gettoken(ps, end_of_str, 0, 0);
        cmd = backcmd(cmd);
    }

    if (peek(ps, end_of_str, ";"))
    {
        gettoken(ps, end_of_str, 0, 0);
        cmd = listcmd(cmd, parse_line(ps, end_of_str));
    }

    return cmd;
}

// *Parsing* de una posible tubería con un número de órdenes.
// `parse_exec()` comprobará la orden, y si al volver el siguiente *token*
// es un `'|'`, significa que se puede ir construyendo una tubería.
struct cmd*
parse_pipe(char **ps, char *end_of_str)
{
    struct cmd *cmd;

    cmd = parse_exec(ps, end_of_str);
    if (peek(ps, end_of_str, "|"))
    {
        gettoken(ps, end_of_str, 0, 0);
        cmd = pipecmd(cmd, parse_pipe(ps, end_of_str));
    }

    return cmd;
}


// Construye los comandos de redirección si encuentra alguno de los
// caracteres de redirección.
struct cmd*
parse_redirs(struct cmd *cmd, char **ps, char *end_of_str)
{
    int tok;
    char *q, *eq;

    // Si lo siguiente que hay a continuación es una redirección...
    while (peek(ps, end_of_str, "<>"))
    {
        // La elimina de la entrada
        tok = gettoken(ps, end_of_str, 0, 0);

        // Si es un argumento, será el nombre del fichero de la
        // redirección. `q` y `eq` tienen su posición.
        if (gettoken(ps, end_of_str, &q, &eq) != 'a')
            panic("missing file for redirection");

        switch(tok)
        {
        case '<':
            cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
            break;
        case '>': //Práctica - Boletin 2 - Ejercicio 1
            cmd = redircmd(cmd, q, eq, O_RDWR|O_CREAT|O_TRUNC, 1);
            break;
        case '+':  // >> Práctica - Boletin 2 - Ejercicio 1
            cmd = redircmd(cmd, q, eq, O_RDWR|O_CREAT|O_APPEND, 1);
            break;
        }
    }

    return cmd;
}

// *Parsing* de un bloque de órdenes delimitadas por paréntesis.
struct cmd*
parse_block(char **ps, char *end_of_str)
{
    struct cmd *cmd;

    // Esperar e ignorar el paréntesis
    if (!peek(ps, end_of_str, "("))
        panic("parse_block");
    gettoken(ps, end_of_str, 0, 0);

    // Parse de toda la línea hsta el paréntesis de cierre
    cmd = parse_line(ps, end_of_str);

    // Elimina el paréntesis de cierre
    if (!peek(ps, end_of_str, ")"))
        panic("syntax - missing )");
    gettoken(ps, end_of_str, 0, 0);

    // ¿Posibles redirecciones?
    cmd = parse_redirs(cmd, ps, end_of_str);

    return cmd;
}

// Hace en *parsing* de una orden, a no ser que la expresión comience por
// un paréntesis. En ese caso, se inicia un grupo de órdenes para ejecutar
// las órdenes de dentro del paréntesis (llamando a `parse_block()`).
struct cmd*
parse_exec(char **ps, char *end_of_str)
{
    char *q, *eq;
    int tok, argc;
    struct execcmd *cmd;
    struct cmd *ret;

    // ¿Inicio de un bloque?
    if (peek(ps, end_of_str, "("))
        return parse_block(ps, end_of_str);

    // Si no, lo primero que hay una línea siempre es una orden. Se
    // construye el `cmd` usando la estructura `execcmd`.
    ret = execcmd();
    cmd = (struct execcmd*)ret;

    // Bucle para separar los argumentos de las posibles redirecciones.
    argc = 0;
    ret = parse_redirs(ret, ps, end_of_str);
    while (!peek(ps, end_of_str, "|)&;"))
    {
        if ((tok=gettoken(ps, end_of_str, &q, &eq)) == 0)
            break;

        // Aquí tiene que reconocerse un argumento, ya que el bucle para
        // cuando hay un separador
        if (tok != 'a')
            panic("syntax");

        // Apuntar el siguiente argumento reconocido. El primero será la
        // orden a ejecutar.
        cmd->argv[argc] = q;
        cmd->eargv[argc] = eq;
        argc++;
        if (argc >= MAXARGS)
            panic("too many args");

        // Y de nuevo apuntar posibles redirecciones
        ret = parse_redirs(ret, ps, end_of_str);
    }

    // Finalizar las líneas de órdenes
    cmd->argv[argc] = 0;
    cmd->eargv[argc] = 0;

    return ret;
}

// Termina en NUL todas las cadenas de `cmd`.
struct cmd*
nulterminate(struct cmd *cmd)
{
    int i;
    struct backcmd *bcmd;
    struct execcmd *ecmd;
    struct listcmd *lcmd;
    struct pipecmd *pcmd;
    struct redircmd *rcmd;

    if(cmd == 0)
        return 0;

    switch(cmd->type)
    {
    case EXEC:
        ecmd = (struct execcmd*)cmd;
        for(i=0; ecmd->argv[i]; i++)
            *ecmd->eargv[i] = 0;
        break;

    case REDIR:
        rcmd = (struct redircmd*)cmd;
        nulterminate(rcmd->cmd);
        *rcmd->efile = 0;
        break;

    case PIPE:
        pcmd = (struct pipecmd*)cmd;
        nulterminate(pcmd->left);
        nulterminate(pcmd->right);
        break;

    case LIST:
        lcmd = (struct listcmd*)cmd;
        nulterminate(lcmd->left);
        nulterminate(lcmd->right);
        break;

    case BACK:
        bcmd = (struct backcmd*)cmd;
        nulterminate(bcmd->cmd);
        break;
    }

    return cmd;
}

/*
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 75
 * eval: (auto-fill-mode t)
 * End:
 */
