/*
 * Shell `simplesh` (basado en el shell de xv6)
 *
 * Ampliación de Sistemas Operativos
 * Departamento de Ingeniería y Tecnología de Computadores
 * Facultad de Informática de la Universidad de Murcia
 *
 * Alumnos: Sanchez Martinez, Alberto.
 *          Martinez Cascales, Alberto.
 *
 * Convocatoria: FEBRERO
 */


/*
 * Ficheros de cabecera
 */


//#define NDEBUG // Translate asserts and DMACROS into no ops

#define _XOPEN_SOURCE 700
#define _GNU_SOURCE
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <pwd.h>
#include <linux/limits.h>
#include <libgen.h>
#include <unistd.h>
#include <signal.h>



// Librería readline
#include <readline/readline.h>
#include <readline/history.h>


/******************************************************************************
 * Constantes, macros y variables globales
 ******************************************************************************/


static const char* VERSION = "0.17";

//Tamaño maximo de un buffer
#define MAX_BUFFER 4096


// Niveles de depuración
#define DBG_CMD   (1 << 0)
#define DBG_TRACE (1 << 1)
// . . .
static int g_dbg_level = 0;

#ifndef NDEBUG
#define DPRINTF(dbg_level, fmt, ...)                            \
    do {                                                        \
        if (dbg_level & g_dbg_level)                            \
            fprintf(stderr, "%s:%d:%s(): " fmt,                 \
                    __FILE__, __LINE__, __func__, ##__VA_ARGS__);       \
    } while ( 0 )

#define DBLOCK(dbg_level, block)                                \
    do {                                                        \
        if (dbg_level & g_dbg_level)                            \
            block;                                              \
    } while( 0 );
#else
#define DPRINTF(dbg_level, fmt, ...)
#define DBLOCK(dbg_level, block)http://www.um.es/informatica/
#endif

#define TRY(x)                                                  \
    do {                                                        \
        int __rc = (x);                                         \
        if( __rc < 0 ) {                                        \
            fprintf(stderr, "%s:%d:%s: TRY(%s) failed\n",       \
                    __FILE__, __LINE__, __func__, #x);          \
            fprintf(stderr, "ERROR: rc=%d errno=%d (%s)\n",     \
                    __rc, errno, strerror(errno));              \
            exit(EXIT_FAILURE);                                 \
        }                                                       \
    } while( 0 )


// Número máximo de argumentos de un comando
#define MAXARGS 16


static const char WHITESPACE[] = " \t\r\n\v";
//Simbolos que nos sirven como delimitadores en el args
static const char SYMBOLS[] = "<|>&;()";
//Array que contiene los pids de los procesos que podemos tener en ejecucion
static pid_t backPids [MAX_BUFFER];

/******************************************************************************
 * Funciones auxiliares
 ******************************************************************************/


// Imprime el mensaje de error
void error(const char *fmt, ...)
{
    va_list arg;

    fprintf(stderr, "%s: ", __FILE__);
    va_start(arg, fmt);
    vfprintf(stderr, fmt, arg);http://www.um.es/informatica/
    va_end(arg);
}


// Imprime el mensaje de error y aborta la ejecución
void panic(const char *fmt, ...)
{
    va_list arg;

    fprintf(stderr, "%s: ", __FILE__);
    va_start(arg, fmt);
    vfprintf(stderr, fmt, arg);
    va_end(arg);

    exit(EXIT_FAILURE);
}


// `fork()` que muestra un mensaje de error si no se puede crear el hijo
int fork_or_panic(const char* s)
{
    int pid;

    pid = fork();
    if(pid == -1)
        panic("%s failed: errno %d (%s)", s, errno, strerror(errno));
    return pid;
}

/******************************************************************************
 * Manejador de señales
 ******************************************************************************/

static void signal_handler(int sig)
{
	if (sig == SIGCHLD) {
		pid_t pid;
		int saved_errno = errno;
		//Esperamos al pid que ha provocado la señal
		//WNOHANG es un flag para el caso de que no haya procesos hijos, se retorne inmediatamente
 		while ((pid = waitpid((pid_t)(-1), 0, WNOHANG)) > 0) {

			//Acciones para cambiar el pid de un int a un char*, ya que es lo que necesita la funcion write
			//Usamos dicha funcion porque se trata de una segura la cual podemos usar en el manejador
			char buffer[sizeof(pid_t)];
			int copypid = pid;
			int j = sizeof(pid);
			while (j > 0){
				buffer[j-1] = copypid % 10 + '0';
				copypid = copypid / 10;
				j--;
    		}
	
			//Mostramos el pid del proceso con el formato correcto
			while(write(STDOUT_FILENO, "[", sizeof(char)) < sizeof(char)){};
			while(write(STDOUT_FILENO, buffer, sizeof(buffer)) < sizeof(buffer)) {};
			while(write(STDOUT_FILENO, "]\n", sizeof(char)+1) < sizeof(char)+1){}

			//Buscamos el pid que ha provocado la llamada al manejador en el array de pids
			int i = 0;
			while (	backPids[i] != pid && i < MAX_BUFFER) {
				i++;
			}
			//Cunado lo encontramos lo eliminamos
			backPids[i] = 0;
		}
		errno = saved_errno;
		
	}
}

/******************************************************************************
 * Estructuras de datos `cmd`												  
 ******************************************************************************/


// Las estructuras `cmd` se utilizan para almacenar información que servirá a
// simplesh para ejecutar líneas de órdenes con redirecciones, tuberías, listas
// de comandos y tareas en segundo plano. El formato es el siguiente:

//     |----------+--------------+--------------|
//     | (1 byte) | ...          | ...          |
//     |----------+--------------+--------------|
//     | type     | otros campos | otros campos |
//     |----------+--------------+--------------|

// Nótese cómo las estructuras `cmd` comparten el primer campo `type` para
// identificar su tipo. A partir de él se obtiene un tipo derivado a través de
// *casting* forzado de tipo. Se consigue así polimorfismo básico en C.

// Valores del campo `type` de las estructuras de datos `cmd`

enum cmd_type { EXEC=1, REDR=2, PIPE=3, LIST=4, BACK=5, SUBS=6, INV=7};

struct cmd { enum cmd_type type; };


// Comando con sus parámetros
struct execcmd {
    enum cmd_type type;
    char* argv[MAXARGS];
    char* eargv[MAXARGS];
};

// Comando con redirección
struct redrcmd {
    enum cmd_type type;
    struct cmd* cmd;
    char* file;
    char* efile;
    int flags;
    int modo;
    int fd;
};

// Comandos con tubería
struct pipecmd {
    enum cmd_type type;
    struct cmd* left;
    struct cmd* right;
};

// Lista de órdenes
struct listcmd {
    enum cmd_type type;
    struct cmd* left;
    struct cmd* right;
};

// Tarea en segundo plano (background) con `&`
struct backcmd {
    enum cmd_type type;
    struct cmd* cmd;
};

// Subshell
struct subscmd {
    enum cmd_type type;
    struct cmd* cmd;
};



/******************************************************************************
 * Funciones para construir las estructuras de datos `cmd`
 ******************************************************************************/

// Construye una estructura `cmd` de tipo `EXEC`
struct cmd* execcmd(void)
{
    struct execcmd* cmd;

    if ((cmd = malloc(sizeof(*cmd))) == NULL)
    {
        perror("execcmd: malloc");
        exit(EXIT_FAILURE);
    }
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = EXEC;

    return (struct cmd*) cmd;
}

// Construye una estructura `cmd` de tipo `REDR`
struct cmd* redrcmd(struct cmd* subcmd,
        char* file, char* efile,
        int flags, int modo, int fd)
{
    struct redrcmd* cmd;

    if ((cmd = malloc(sizeof(*cmd))) == NULL)
    {
        perror("redrcmd: malloc");
        exit(EXIT_FAILURE);
    }
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = REDR;
    cmd->cmd = subcmd;
    cmd->file = file;
    cmd->efile = efile;
    cmd->flags = flags;
    cmd->modo = modo;
    cmd->fd = fd;

    return (struct cmd*) cmd;
}

// Construye una estructura `cmd` de tipo `PIPE`
struct cmd* pipecmd(struct cmd* left, struct cmd* right)
{
    struct pipecmd* cmd;

    if ((cmd = malloc(sizeof(*cmd))) == NULL)
    {
        perror("pipecmd: malloc");
        exit(EXIT_FAILURE);
    }
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = PIPE;
    cmd->left = left;
    cmd->right = right;

    return (struct cmd*) cmd;
}

// Construye una estructura `cmd` de tipo `LIST`
struct cmd* listcmd(struct cmd* left, struct cmd* right)
{
    struct listcmd* cmd;

    if ((cmd = malloc(sizeof(*cmd))) == NULL)
    {
        perror("listcmd: malloc");
        exit(EXIT_FAILURE);
    }
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = LIST;
    cmd->left = left;
    cmd->right = right;

    return (struct cmd*)cmd;
}

// Construye una estructura `cmd` de tipo `BACK`
struct cmd* backcmd(struct cmd* subcmd)
{
    struct backcmd* cmd;

    if ((cmd = malloc(sizeof(*cmd))) == NULL)
    {
        perror("backcmd: malloc");
        exit(EXIT_FAILURE);
    }
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = BACK;
    cmd->cmd = subcmd;

    return (struct cmd*)cmd;
}

// Construye una estructura `cmd` de tipo `SUB`
struct cmd* subscmd(struct cmd* subcmd)
{
    struct subscmd* cmd;

    if ((cmd = malloc(sizeof(*cmd))) == NULL)
    {
        perror("subscmd: malloc");
        exit(EXIT_FAILURE);
    }
    memset(cmd, 0, sizeof(*cmd));
    cmd->type = SUBS;
    cmd->cmd = subcmd;

    return (struct cmd*) cmd;
}


/******************************************************************************
 * Funciones para realizar el análisis sintáctico de la línea de órdenes
 ******************************************************************************/


// `get_token` recibe un puntero al principio de una cadena (`start_of_str`),
// otro puntero al final de esa cadena (`end_of_str`) y, opcionalmente, dos
// punteros para guardar el principio y el final del token, respectivamente.
//
// `get_token` devuelve un *token* de la cadena de entrada.

int get_token(char** start_of_str, char* end_of_str,
        char** start_of_token, char** end_of_token)
{
    char* s;
    int ret;

    // Salta los espacios en blanco
    s = *start_of_str;
    while (s < end_of_str && strchr(WHITESPACE, *s))
        s++;

    // `start_of_token` apunta al principio del argumento (si no es NULL)
    if (start_of_token)
        *start_of_token = s;

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

            // El caso por defecto (cuando no hay caracteres especiales) es el
            // de un argumento de un comando. `get_token` devuelve el valor
            // `'a'`, `start_of_token` apunta al argumento (si no es `NULL`),
            // `end_of_token` apunta al final del argumento (si no es `NULL`) y
            // `start_of_str` avanza hasta que salta todos los espacios
            // *después* del argumento. Por ejemplo:
            //
            //     |-----------+---+---+---+---+---+---+---+---+---+-----------|
            //     | (espacio) | a | r | g | u | m | e | n | t | o | (espacio)
            //     |
            //     |-----------+---+---+---+---+---+---+---+---+---+-----------|
            //                   ^                                   ^
            //            start_o|f_token                       end_o|f_token

            ret = 'a';
            while (s < end_of_str &&
                    !strchr(WHITESPACE, *s) &&
                    !strchr(SYMBOLS, *s))
                s++;
            break;
    }

    // `end_of_token` apunta al final del argumento (si no es `NULL`)
    if (end_of_token)
        *end_of_token = s;

    // Salta los espacios en blanco
    while (s < end_of_str && strchr(WHITESPACE, *s))
        s++;

    // Actualiza `start_of_str`
    *start_of_str = s;

    return ret;
}


// `peek` recibe un puntero al principio de una cadena (`start_of_str`), otro
// puntero al final de esa cadena (`end_of_str`) y un conjunto de caracteres
// (`delimiter`).
//
// El primer puntero pasado como parámero (`start_of_str`) avanza hasta el
// primer carácter que no está en el conjunto de caracteres `WHITESPACE`.
//
// `peek` devuelve un valor distinto de `NULL` si encuentra alguno de los
// caracteres en `delimiter` justo después de los caracteres en `WHITESPACE`.

int peek(char** start_of_str, char* end_of_str, char* delimiter)
{
    char* s;

    s = *start_of_str;
    while (s < end_of_str && strchr(WHITESPACE, *s))
        s++;
    *start_of_str = s;

    return *s && strchr(delimiter, *s);
}


// Definiciones adelantadas de funciones
struct cmd* parse_line(char**, char*);
struct cmd* parse_pipe(char**, char*);
struct cmd* parse_exec(char**, char*);
struct cmd* parse_subs(char**, char*);
struct cmd* parse_redr(struct cmd*, char**, char*);
struct cmd* null_terminate(struct cmd*);
void free_cmd(struct cmd* cmd);


// `parse_cmd` realiza el *análisis sintáctico* de la línea de órdenes
// introducida por el usuario.
//
// `parse_cmd` utiliza `parse_line` para obtener una estructura `cmd`.

struct cmd* parse_cmd(char* start_of_str)
{
    char* end_of_str;
    struct cmd* cmd;

    DPRINTF(DBG_TRACE, "STR\n");

    end_of_str = start_of_str + strlen(start_of_str);

    cmd = parse_line(&start_of_str, end_of_str);

    // Comprueba que se ha alcanzado el final de la línea de órdenes
    peek(&start_of_str, end_of_str, "");
    if (start_of_str != end_of_str)
        error("%s: error sintáctico: %s\n", __func__);

    DPRINTF(DBG_TRACE, "END\n");

    return cmd;
}


// `parse_line` realiza el análisis sintáctico de la línea de órdenes
// introducida por el usuario.
//
// `parse_line` comprueba en primer lugar si la línea contiene alguna tubería.
// Para ello `parse_line` llama a `parse_pipe` que a su vez verifica si hay
// bloques de órdenes y/o redirecciones.  A continuación, `parse_line`
// comprueba si la ejecución de la línea se realiza en segundo plano (con `&`)
// o si la línea de órdenes contiene una lista de órdenes (con `;`).

struct cmd* parse_line(char** start_of_str, char* end_of_str)
{
    struct cmd* cmd;
    int delimiter;

    cmd = parse_pipe(start_of_str, end_of_str);

    while (peek(start_of_str, end_of_str, "&"))
    {
        // Consume el delimitador de tarea en segundo plano
        delimiter = get_token(start_of_str, end_of_str, 0, 0);
        assert(delimiter == '&');

        // Construye el `cmd` para la tarea en segundo plano
        cmd = backcmd(cmd);
    }

    if (peek(start_of_str, end_of_str, ";"))
    {
        if (cmd->type == EXEC && ((struct execcmd*) cmd)->argv[0] == 0)
            error("%s: error sintáctico: no se encontró comando\n", __func__);

        // Consume el delimitador de lista de órdenes
        delimiter = get_token(start_of_str, end_of_str, 0, 0);
        assert(delimiter == ';');

        // Construye el `cmd` para la lista
        cmd = listcmd(cmd, parse_line(start_of_str, end_of_str));
    }

    return cmd;
}


// `parse_pipe` realiza el análisis sintáctico de una tubería de manera
// recursiva si encuentra el delimitador de tuberías '|'.
//
// `parse_pipe` llama a `parse_exec` y `parse_pipe` de manera recursiva para
// realizar el análisis sintáctico de todos los componentes de la tubería.

struct cmd* parse_pipe(char** start_of_str, char* end_of_str)
{
    struct cmd* cmd;
    int delimiter;

    cmd = parse_exec(start_of_str, end_of_str);

    if (peek(start_of_str, end_of_str, "|"))
    {
        if (cmd->type == EXEC && ((struct execcmd*) cmd)->argv[0] == 0)
            error("%s: error sintáctico: no se encontró comando\n", __func__);

        // Consume el delimitador de tubería
        delimiter = get_token(start_of_str, end_of_str, 0, 0);
        assert(delimiter == '|');

        // Construye el `cmd` para la tubería
        cmd = pipecmd(cmd, parse_pipe(start_of_str, end_of_str));
    }

    return cmd;
}


// `parse_exec` realiza el análisis sintáctico de un comando a no ser que la
// expresión comience por un paréntesis, en cuyo caso se llama a `parse_subs`.
//
// `parse_exec` reconoce las redirecciones antes y después del comando.

struct cmd* parse_exec(char** start_of_str, char* end_of_str)
{
    char* start_of_token;
    char* end_of_token;
    int token, argc;
    struct execcmd* cmd;
    struct cmd* ret;

    // ¿Inicio de un bloque?
    if (peek(start_of_str, end_of_str, "("))
        return parse_subs(start_of_str, end_of_str);

    // Si no, lo primero que hay en una línea de órdenes es un comando

    // Construye el `cmd` para el comando
    ret = execcmd();
    cmd = (struct execcmd*) ret;

    // ¿Redirecciones antes del comando?
    ret = parse_redr(ret, start_of_str, end_of_str);

    // Bucle para separar los argumentos de las posibles redirecciones
    argc = 0;
    while (!peek(start_of_str, end_of_str, "|)&;"))
    {
        if ((token = get_token(start_of_str, end_of_str,
                        &start_of_token, &end_of_token)) == 0)
            break;

        // El siguiente token debe ser un argumento porque el bucle
        // para en los delimitadores
        if (token != 'a')
            error("%s: error sintáctico: se esperaba un argumento\n", __func__);

        // Almacena el siguiente argumento reconocido. El primero es
        // el comando
        cmd->argv[argc] = start_of_token;
        cmd->eargv[argc] = end_of_token;
        argc++;
        if (argc >= MAXARGS)
            panic("%s: demasiados argumentos\n", __func__);

        // ¿Redirecciones después del comando?
        ret = parse_redr(ret, start_of_str, end_of_str);
    }

    // El comando no tiene más parámetros
    cmd->argv[argc] = 0;
    cmd->eargv[argc] = 0;

    return ret;
}


// `parse_subs` realiza el análisis sintáctico de un bloque de órdenes
// delimitadas por paréntesis o `subshell` llamando a `parse_line`.
//
// `parse_subs` reconoce las redirecciones después del bloque de órdenes.

struct cmd* parse_subs(char** start_of_str, char* end_of_str)
{
    int delimiter;
    struct cmd* cmd;
    struct cmd* scmd;

    // Consume el paréntesis de apertura
    if (!peek(start_of_str, end_of_str, "("))
        error("%s: error sintáctico: se esperaba '('", __func__);
    delimiter = get_token(start_of_str, end_of_str, 0, 0);
    assert(delimiter == '(');

    // Realiza el análisis sintáctico hasta el paréntesis de cierre
    scmd = parse_line(start_of_str, end_of_str);

    // Construye el `cmd` para el bloque de órdenes
    cmd = subscmd(scmd);

    // Consume el paréntesis de cierre
    if (!peek(start_of_str, end_of_str, ")"))
        error("%s: error sintáctico: se esperaba ')'", __func__);
    delimiter = get_token(start_of_str, end_of_str, 0, 0);
    assert(delimiter == ')');

    // ¿Redirecciones después del bloque de órdenes?
    cmd = parse_redr(cmd, start_of_str, end_of_str);

    return cmd;
}


// `parse_redr` realiza el análisis sintáctico de órdenes con
// redirecciones si encuentra alguno de los delimitadores de
// redirección ('<' o '>').

struct cmd* parse_redr(struct cmd* cmd, char** start_of_str, char* end_of_str)
{
    int delimiter;
    char* start_of_token;
    char* end_of_token;

    // Si lo siguiente que hay a continuación es delimitador de
    // redirección...
    while (peek(start_of_str, end_of_str, "<>"))
    {
        // Consume el delimitador de redirección
        delimiter = get_token(start_of_str, end_of_str, 0, 0);
        assert(delimiter == '<' || delimiter == '>' || delimiter == '+');

        // El siguiente token tiene que ser el nombre del fichero de la
        // redirección entre `start_of_token` y `end_of_token`.
        if ('a' != get_token(start_of_str, end_of_str, &start_of_token, &end_of_token))
            error("%s: error sintáctico: se esperaba un fichero", __func__);

        // Construye el `cmd` para la redirección
        switch(delimiter)
        {
            case '<':
                cmd = redrcmd(cmd, start_of_token, end_of_token, O_RDONLY, S_IRWXU, 0);
                break;
            case '>':
                cmd = redrcmd(cmd, start_of_token, end_of_token, O_RDWR|O_CREAT|O_TRUNC, S_IRWXU, 1);
                break;
            case '+': // >>
                cmd = redrcmd(cmd, start_of_token, end_of_token, O_RDWR|O_CREAT|O_APPEND, S_IRWXU, 1);
                break;
        }
    }

    return cmd;
}


// Termina en NULL todas las cadenas de las estructuras `cmd`
struct cmd* null_terminate(struct cmd* cmd)
{
    struct execcmd* ecmd;
    struct redrcmd* rcmd;
    struct pipecmd* pcmd;
    struct listcmd* lcmd;
    struct backcmd* bcmd;
    struct subscmd* scmd;
    int i;

    if(cmd == 0)
        return 0;

    switch(cmd->type)
    {
        case EXEC:
            ecmd = (struct execcmd*) cmd;
            for(i = 0; ecmd->argv[i]; i++)
                *ecmd->eargv[i] = 0;
            break;

        case REDR:
            rcmd = (struct redrcmd*) cmd;
            null_terminate(rcmd->cmd);
            *rcmd->efile = 0;
            break;

        case PIPE:
            pcmd = (struct pipecmd*) cmd;
            null_terminate(pcmd->left);
            null_terminate(pcmd->right);
            break;

        case LIST:
            lcmd = (struct listcmd*) cmd;
            null_terminate(lcmd->left);
            null_terminate(lcmd->right);
            break;

        case BACK:
            bcmd = (struct backcmd*) cmd;
            null_terminate(bcmd->cmd);
            break;

        case SUBS:
            scmd = (struct subscmd*) cmd;
            null_terminate(scmd->cmd);
            break;

        case INV:
        default:
            panic("%s: estructura `cmd` desconocida\n", __func__);
    }

    return cmd;
}


/******************************************************************************
 * Funciones para la ejecución de la línea de órdenes
 ******************************************************************************/

//FUNCION CWD
//Cuando escribes cwd te devuelve el directorio en el que estas

void run_cwd() {

    uid_t user;
	struct passwd *pwd;
	char *ruta = malloc(PATH_MAX);

	//Obtenemos el uid del usuario.
    user = getuid();
	//Devuelve un puntero a la entrada de /etc/passwd de user
	pwd = getpwuid(user);
	//Comprobacion de que user existe
	if (!pwd){
		panic("getpwuid"); 
	}
	
	//Obtenemos la ruta completa en ruta
	ruta = getcwd(ruta, PATH_MAX);
	//Comprobacion de que existe la ruta
	if (!ruta){
		panic("getcwd");
	}

	//Salida de error que es "simplesh: cwd: "
	fprintf( stderr, "simplesh: cwd: "); 
	//Ruta del directorio actual
	printf("%s\n", ruta);
	
	free(ruta);
			
}

void run_exit(struct execcmd* ecmd) {

	assert(ecmd->type == EXEC);

    if (ecmd->argv[0] == 0) exit(EXIT_SUCCESS);
	
	//Liberamos estructura cmd
	free_cmd((struct cmd *) ecmd);
	free(ecmd);

	//Salida
	_exit(EXIT_SUCCESS);
}

void run_cd(struct execcmd* ecmd){

	assert(ecmd->type == EXEC);

    if (ecmd->argv[0] == 0) exit(EXIT_SUCCESS);
	
	int ret;
	char *ruta = malloc(PATH_MAX);

	//Sin parametros
	if (ecmd->argv[1] == NULL){
		//Obtenemos la ruta actual
		ruta = getcwd(ruta, PATH_MAX);
		//Comprobacion
		if (!ruta){
			panic("getcwd");
		}
		//En OLDPWD guardamos el directorio actual
		setenv("OLDPWD", ruta,1);

		//Cambio efectivo de directorio y comprobacion
		ret = chdir(getenv("HOME"));
		if (ret != 0)
			printf("run_cd: No existe el directorio: %s\n", ecmd->argv[1]);
		else{
			//Establecemos en la variable PWD (directorio actual) la ruta a HOME
			setenv("PWD",getenv("HOME"),1);
		}
	}
	//Ruta anterior
	else if (strcmp(ecmd->argv[1],"-") == 0){
		//Si no ejecutamos directamente el -, es decir, si nos hemos movido previamente del directorio
		if (strcmp(getenv("OLDPWD") ,"") != 0){

			//Ruta antigua
			char *pwd = getenv("OLDPWD");
			//Obtener directorio actual
			ruta = getcwd(ruta, PATH_MAX);
			//Comprobacion de que es una ruta valida
			if (!ruta){
				panic("getcwd");
			}
			//Estableces como directorio antiguo el actual
			setenv("OLDPWD", ruta,1);

			//Cambio efectivo de directorio y comprobacion
			ret = chdir(pwd);
			if (ret != 0)
				printf("run_cd: No existe el directorio: %s\n", pwd);
			else{
				//Cambias la variable PWD por el directorio antiguo (que ahora es el actual)
				setenv("PWD", pwd, 1);
			}
		//Si se ejecutase directamente el cd -
		}else printf("run_cd: Variable $OLDPWD no está definida\n");
					
	}	
	
	//Si es un cd normal
	else {
		//Obtenemos la ruta actual
		ruta = getcwd(ruta, PATH_MAX);
		//Comprobacion
		if (!ruta){
			panic("getcwd");
		}
		
		//Cambio efectivo de directorio, por el argumento a continuacion de cd
		ret = chdir(ecmd->argv[1]);
		//Comprobacion
		if (ret != 0)
			printf("run_cd: No existe el directorio '%s'\n", ecmd->argv[1]);
		else{
			//En OLDPWD guardamos el directorio anteriror
			setenv("OLDPWD", ruta,1);
			ruta = getcwd(ruta, PATH_MAX);
			//Comprobacion
			if (!ruta){
				panic("getcwd");
			}
			//La nueva variable PWD
			setenv("PWD", ruta, 1);
			
		}
	}
	
	free(ruta);
	
}


void imprimirAyudaArgs(){
	printf("Uso : args [- d DELIMS ] [ -p NPROCS ] [-h] [ COMANDO [ PARAMETROS ] ]\n");
	printf("\t Opciones :\n");
	printf("\t -d DELIMS Caracteres delimitadores entre cadenas para COMANDO ( defecto : \" \\t\\r\\n\\v\")\n");
	printf("\t -p NPROCS Número máximo de ejecuciones en paralelo de COMANDO ( defecto : 1)\n");
	printf("\t -h help\n");
}

void run_args(struct execcmd* ecmd){
	
	assert(ecmd->type == EXEC);         
	
    if (ecmd->argv[0] == 0) exit(EXIT_SUCCESS);
    
    int opt, cont=0;
	//Saber el numero de parametros que se le pasa a args (lo que va detras de la tuberia)
    while (ecmd->argv[cont]!=NULL){
		cont++;
	}
	
	char *delimit = (char *) WHITESPACE;

	int nProces = 1;
	int flag = 0;
	int inicio = 0;
	//Analisis de parametros:
	while ((opt = getopt(cont, ecmd->argv, "d:p:h")) != -1) {
		switch (opt) {
			//Cambio de delimitadores
			case 'd':
				delimit = optarg;
				break;
			//Cambio del numero de procesos (no implementado)
			case 'p':
				nProces = atoi(optarg);
				break;
			//Mostrar las opciones de la ayuda
			case 'h':
				flag = 1;
				imprimirAyudaArgs();
				break;
			}
		}

	//Si no es el caso de la ayuda
	if(flag != 1){
		inicio = optind;
		//si no ha leido ningun parametro el comando por defecto es echo.
		if (optind == cont){
			ecmd->argv[optind] = "echo";
			optind++;
		} else
		///Mientras optind sea menor que el numero de argumentos (lo que va detras de la tuberia)
		while (optind < cont){
			optind++;
		}

	//Como vamos a leer de char en char solo necesitamos espacio para guardar uno.
	char* buffer = malloc(sizeof(char));
	int numbytes = 0;
	//Cadena donde guardamos la entrada estandar.
	char* entrada = malloc(MAX_BUFFER);
	int indice = 0;

	//Si hay que ejecutar args concurrentemente
	if (nProces > 1){
		int procesos = nProces;
		while ((numbytes = read(STDIN_FILENO, buffer, sizeof(char))) > 0 ){
		//Si no es un delimitador y no es el final del comando:
		if (strchr(delimit, buffer[0]) == NULL && buffer[0] != '\n' ){
			//Almacenamos en entrada el caracter leido y avanzamos la posicion en la cadena que nos lleva el caracter leido
			entrada[indice] = buffer[0];
			indice++;
		}
		//En el caso de que sea uno de los delimitadores
		else{
			//Sustituimos es dielimitador por el '\0'
			entrada[indice] = '\0';
			//La cadena leida se la pasamos a ecmd->argv[optind]
			ecmd->argv[optind] = entrada;

			//Crear el proceso hijo y llamar al exec
			if (fork_or_panic("fork EXEC") == 0){
				//Le pasamos el puntero a la cadena procesada
				execvp(ecmd->argv[inicio], &ecmd->argv[inicio]);
				panic("no se encontró el comando '%s'\n", ecmd->argv[optind]);
			}
			//Inicializamos de nuevo el buffer a 0.
			memset(entrada, 0, sizeof(&entrada));	
			indice = 0;	
			procesos--;
			// si no puedo ejecutar mas procesos de forma concurrente, espero a que acaben los que estan en ejecucion.
			if (procesos == 0){
				int status = 0;
				for(int i = 0; i< nProces; i++){
					//Esperamos a que se procese el comando
					TRY( wait(&status) );
				   	if (status != 0 ) exit(EXIT_SUCCESS);
				}
				
			}
			procesos = nProces;
		}
	}
	//En el caso de que sea el ultimo directorio y ya no haya un delimitador detras
		if (indice > 0 ){
			//Sustituimos es dielimitador por el '\0'
			entrada[indice] = '\0';
			//La cadena leida se la pasamos a ecmd->argv[optind]
			ecmd->argv[optind] = entrada;

			//Crear el proceso hijo y llamar al exec
			if (fork_or_panic("fork EXEC") == 0){
				//Le pasamos el puntero a la cadena procesada
				execvp(ecmd->argv[inicio], &ecmd->argv[inicio]);
				panic("no se encontró el comando '%s'\n", ecmd->argv[optind]);
				}
			procesos--;

			if (procesos == 0){
				int status = 0;
				for(int i = 0; i< nProces; i++){
					//Esperamos a que se procese el comando
					TRY( wait(&status) );
				   	if (status != 0 ) exit(EXIT_SUCCESS);
				}
				
			}
		}

	} else {
	//En numbytes tenemos el numero de bytes que van despues del echo
	while ((numbytes = read(STDIN_FILENO, buffer, sizeof(char))) > 0){
		//Si no es un delimitador y no es el final del comando:
		if (strchr(delimit, buffer[0]) == NULL && buffer[0] != '\n' ){
			//Almacenamos en entrada el caracter leido y avanzamos la posicion en la cadena que nos lleva el caracter leido
			entrada[indice] = buffer[0];
			indice++;
		}
		//En el caso de que sea uno de los delimitadores
		else{
			//Sustituimos es dielimitador por el '\0'
			entrada[indice] = '\0';
			//La cadena leida se la pasamos a ecmd->argv[optind]
			ecmd->argv[optind] = entrada;

			//Crear el proceso hijo y llamar al exec
			if (fork_or_panic("fork EXEC") == 0){
				//Le pasamos el puntero a la cadena procesada
				execvp(ecmd->argv[inicio], &ecmd->argv[inicio]);
				panic("no se encontró el comando '%s'\n", ecmd->argv[optind]);
				}
			int status = 0;
			//Esperamos a que se procese el comando
			TRY( wait(&status) );
		   	if (status != 0 ) exit(EXIT_SUCCESS);

			//Inicializamos de nuevo el buffer a 0.
			memset(entrada, 0, sizeof(&entrada));	
			indice = 0;
		}
		
	}
		
		//En el caso de que sea el ultimo directorio y ya no haya un delimitador detras
		if (indice > 0 ){
			//Sustituimos es dielimitador por el '\0'
			entrada[indice] = '\0';
			//La cadena leida se la pasamos a ecmd->argv[optind]
			ecmd->argv[optind] = entrada;

			//Crear el proceso hijo y llamar al exec
			if (fork_or_panic("fork EXEC") == 0){
				//Le pasamos el puntero a la cadena procesada
				execvp(ecmd->argv[inicio], &ecmd->argv[inicio]);
				panic("no se encontró el comando '%s'\n", ecmd->argv[optind]);
				}
			//Esperamos al hijo creado
			TRY( wait(NULL) );
		}
	}
	
	optind = 1;
	free(buffer);
	free(entrada);
	}
}

void imprimirAyudaTrod(){
	printf("Uso : trod [- t TAMAÑO ] [-d] [-c] SET1 [SET2]\n");
	printf("\tSET1 y SET2 son conjuntos de caracteres.\n");
	printf("\t Opciones :\n");
	printf("\t -t TAMAÑO en bytes de los bloques le í dos de ‘ stdin ’\n");
	printf("\t -d Borra los caracteres de SET1\n");
	printf("\t -c Comprime los caracteres de SET1\n");
	printf("\t -h help\n");
}

int restriccionesTrod(int cont, int optind, int flagDelete, int flagCompress, int tamano, char* set1, char * set2){
	
	if(tamano < 1 || tamano > 1048576){
		printf("run_trod: Tamaño no válido \n");
		return 1;
	}	

	if(flagDelete && flagCompress){
		printf("run_trod: Parámetros incompatibles \n");
		return 1;
	}
		
	if(flagDelete && cont-optind != 1){
		printf("run_trod: Se debe especificar sólo SET1 \n");
		return 1;
	}

	if(flagCompress && cont-optind != 1){
		printf("run_trod: Se debe especificar sólo SET1 \n");
		return 1;
	}

	if(!flagDelete && !flagCompress && cont-optind != 2){
		printf("run_trod: Se debe especificar tanto SET1 como SET2\n");
		return 1;
	}
		
	if(!flagDelete && !flagCompress && strlen(set1) != strlen(set2)){
		printf("run_trod: SET1 y SET2 deben tener el mismo tamaño\n");
		return 1;
	}

	return 0;
}


void run_trod(struct execcmd* ecmd){
	
	assert(ecmd->type == EXEC);          
	
    if (ecmd->argv[0] == 0) exit(EXIT_SUCCESS);
    
    int opt, cont=0;
	//Saber el numero de parametros que se le pasa a trod (lo que va detras de la tuberia)
    while (ecmd->argv[cont]!=NULL){
		cont++;
	}

	int tamano = 1;
	int flagHelp = 0;	
	int flagDelete = 0;
	int flagCompress = 0;
	//Analisis de parametros:
	while ((opt = getopt(cont, ecmd->argv, "cdt:h")) != -1) {
		switch (opt) {
			//Borra los caracteres de SET1
			case 'd':
				flagDelete = 1;
				break;
			//Establece el tamaño en bytes de los bloques leidos de stdin
			case 't':
				tamano = atoi(optarg);
				break;
			case 'c':
				flagCompress = 1;
				break;
			//Mostrar las opciones de la ayuda
			case 'h':
				flagHelp = 1;
				imprimirAyudaTrod();
				break;
			}
	}
	
	char *set1;
	char *set2;
	//Si no es el caso de la ayuda
	if(flagHelp != 1){
		//Si no cumple las restricciones no hago nada.
		if (!restriccionesTrod(cont, optind, flagDelete, flagCompress, tamano, ecmd->argv[optind], ecmd->argv[optind+1])){
			//Primer prametro despues de trod
			set1 = ecmd->argv[optind++];
			//Segundo prametro despues de trod
			set2 = ecmd->argv[optind];
			
			char * buffer = malloc(tamano);
			int numbytes = 0;
			char *cadena = malloc(tamano);
			memset(cadena, 0, sizeof(&cadena));
			//Caso -d
			if(flagDelete){
				while((numbytes = read(STDIN_FILENO, buffer, tamano)) > 0){
					//Recorro los caracteres que he leido para comprobar si los tengo que eliminar
					int longitud = 0;
					for (int i = 0; i < numbytes; i++){				
						char *indice = strchr(set1, buffer[i]);
						//Si los caracteres que queremos borrar no estan es SET1 los imprimos
						if (indice == NULL && buffer[i] != '\n') {
							cadena[i] = buffer[i];
							longitud++;
							}
						//Si estan en set1 no hacemos nada, el cual es el mismo efecto que eliminarlos
					}

					//Imprimimos por pantalla la cadena resultante
					while(write(STDOUT_FILENO, cadena, longitud) < longitud){}
					if ( fsync(STDOUT_FILENO) != 0){
						if ( errno != EINVAL ) panic("Error en sincronizacion fsync");
					}
					//Inicializamos de nuevo el buffer a 0;
					memset(buffer, 0, sizeof(&buffer));
					memset(cadena, 0, sizeof(&cadena));
				}
			}
			//Caso -c
			else if(flagCompress){
				int indiceAnterior = -1;
				while((numbytes = read(STDIN_FILENO, buffer, tamano)) > 0){
					//Recorremos los caracteres que he leido para comprobar si los tengo que comprimir	
					int longitud = 0;		
					for (int i = 0; i < numbytes; i++){				
						char *indice = strchr(set1, buffer[i]);
						//Si no estan en set1 los imprimimos
						if (indice == NULL){
							cadena[longitud] = buffer[i];
							longitud++;
						//Si estan, comprobamos que sean distintos al que hemos añadido justo antes
						}else if (strlen(set1)-strlen(indice) != indiceAnterior){
							cadena[longitud] = buffer[i];
							longitud++;
							indiceAnterior = strlen(set1)-strlen(indice);
						}
						//En el caso de que sean los mismos, no los imprimimos
						
					}

					//Los mostramos
					while(write(STDOUT_FILENO, cadena, longitud) < longitud){}
					if ( fsync(STDOUT_FILENO) != 0){
						if ( errno != EINVAL ) panic("Error en sincronizacion fsync");
					}
					//Inicializamos el buffer a 0;
					memset(buffer, 0, sizeof(&buffer));
					memset(cadena, 0, sizeof(&cadena));		
				}

			}
			//Caso sin parametros
			else {

				int bytesLeidos = 0;
				while((numbytes = read(STDIN_FILENO, buffer, tamano)) > 0){
					//Recorro los caracteres que he leido para comprobar si los tengo que cambiar	
					bytesLeidos += numbytes;
					//printf("Ha leido %d bytes\n", bytesLeidos);			
					int i = 0;					
					for (i; i < numbytes; i++){
						//Comprobamos el caracter leido y el el primer conjunto
						char *indice = strchr(set1, buffer[i]);
						//Si no estan en set1 lo imprimo.
						if (indice == NULL){						
							cadena[i] = buffer[i];
						//Si esta, en set1 tenemos que intercambiarlo por el correspondiente en set2.
						}else{
							cadena[i] = set2[strlen(set1)-strlen(indice)];
						}
					}
				
					//Los mostramos por pantalla
					while( write(STDOUT_FILENO, cadena, numbytes) < numbytes){}
					if ( fsync(STDOUT_FILENO) != 0){
						if ( errno != EINVAL ) panic("Error en sincronizacion fsync");
					}

					//Inicializamos de nuevo el buffer
					memset(buffer, 0, sizeof(&buffer));
					memset(cadena, 0, sizeof(&cadena));
				
			}			
		}	
	free(buffer);
	free(cadena);	
	}
	optind = 1;	
	}
	
}


void imprimirAyudaBjobs(){
printf("Uso: bjobs [-k] [-h]\n\tOpciones:\n\t-k Mata  todos  los  procesos  en  segundo  plano\n\t-h help\n");
}

void run_bjobs(struct execcmd* ecmd){
	assert(ecmd->type == EXEC);          
	
    if (ecmd->argv[0] == 0) exit(EXIT_SUCCESS);
    
    int opt, cont=0;
	//Saber el numero de parametros que se le pasa a trod (lo que va detras de la tuberia)
    while (ecmd->argv[cont]!=NULL){
		cont++;
	}

	int flagHelp=0;
	int flagKill=0;
	//Analisis de parametros:
	while ((opt = getopt(cont, ecmd->argv, "hk")) != -1) {
		switch (opt) {
			case 'k':
				flagKill = 1;
				break;
			//Mostrar las opciones de la ayuda
			case 'h':
				flagHelp = 1;
				imprimirAyudaBjobs();
				break;
			}
	}
	if (flagHelp != 1) {
		if (flagKill) {
			int i=0;
			//Para enviar la señal SIGKILL a todos los procesos en segundo plano
			while (backPids[i] != 0 && i<MAX_BUFFER){
				kill(backPids[i], SIGKILL);
				i++;
			}
		}

	
	else {
		int i=0;
		//Para imprimir los pids en segundo plano
		while (backPids[i] != 0 && i<MAX_BUFFER){
			printf("[%d]\n", backPids[i]);
			i++;
		}
	}

	}
	
	optind =1;
}

/*Funcion para indicar si la estrucctura ecmd pasada en el parametro es de
tipo comando interno*/
int isComandoInterno(struct execcmd* ecmd){
	if (strcmp(ecmd->argv[0], "cwd") == 0 ){
		return 0;
	}

	if (strcmp(ecmd->argv[0], "exit") == 0){
		return 0;
	}

	if (strcmp(ecmd->argv[0], "cd") == 0){
		return 0;
	}

	if (strcmp(ecmd->argv[0], "args") == 0){
		return 0;
	}

	if (strcmp(ecmd->argv[0], "trod") == 0){
		return 0;
	}

	if (strcmp(ecmd->argv[0], "bjobs") == 0){
		return 0;
	}

	return 1;

}

/*Funcion para ejecutar un comando interno*/
int comandoInterno(struct execcmd* ecmd){

	if (strcmp(ecmd->argv[0], "cwd") == 0 ){
		run_cwd();
		return 0;
	}

	if (strcmp(ecmd->argv[0], "exit") == 0){
		run_exit(ecmd);	
		return 0;
	}

	if (strcmp(ecmd->argv[0], "cd") == 0){
		run_cd(ecmd);
		return 0;
	}

	if (strcmp(ecmd->argv[0], "args") == 0){
		run_args(ecmd);
		return 0;
	}

	if (strcmp(ecmd->argv[0], "trod") == 0){
		run_trod(ecmd);
		return 0;
	}

	if (strcmp(ecmd->argv[0], "bjobs") == 0){
		run_bjobs(ecmd);
		return 0;
	}

	return 1;
}

/*Funcion para ejecutar un comando de tipo EXEC*/
void exec_cmd(struct execcmd* ecmd)
{
    assert(ecmd->type == EXEC);

    if (ecmd->argv[0] == 0) exit(EXIT_SUCCESS);

	execvp(ecmd->argv[0], ecmd->argv);
	panic("no se encontró el comando '%s'\n", ecmd->argv[0]);
}


void run_cmd(struct cmd* cmd)
{
	
    struct execcmd* ecmd;
    struct redrcmd* rcmd;
    struct listcmd* lcmd;
    struct pipecmd* pcmd;
    struct backcmd* bcmd;
    struct subscmd* scmd;
	int p[2];
    int fd;

	pid_t pid = 0;
	pid_t pidr;
	pid_t pidl;

    DPRINTF(DBG_TRACE, "STR\n");

    if(cmd == 0) return;
	
	/*Conjunto de señales que contiene la señal SIGCHLD. En todos los casos
	excepto en el caso de un comando BACK, con la funcion sigprocmask se bloqueara
	o desbloqueara este conjunto.*/
	sigset_t blocked_chld;
	sigemptyset(&blocked_chld);
	sigaddset(&blocked_chld, SIGCHLD);
	
    switch(cmd->type)

    {
       case EXEC:
            ecmd = (struct execcmd*) cmd;
			
			//Si se le pasa algun parametro
			if (ecmd->argv[0] != NULL){
				//Si no es un comando interno
				if (comandoInterno(ecmd) != 0){
					//Con la funcion sigprocmask y el parametro SIG_BLOCK se bloquean las señales
					//que pertenezcan a la union entre las ya bloqueadas y el nuevo conjunto. De esta
					//forma conseguimos bloquear la señal SIGCHLD.
					if (sigprocmask(SIG_BLOCK, &blocked_chld, NULL) == -1) {
						perror("sigprocmask");
						exit(EXIT_FAILURE);
					}
				
					//Creamos el proceso hijo
					pid = fork_or_panic("fork EXEC");
					if (pid == 0)
	          			exec_cmd(ecmd);
				
					//Esperamos el proceso en cuestion
					TRY( waitpid(pid, NULL, 0) );	
				
					//Tras acabar la ejecución de nuevo se desbloquea la señal con el parametro SIG_UNBLOCK
					if (sigprocmask(SIG_UNBLOCK, &blocked_chld, NULL) == -1) {
						perror("sigprocmask");
						exit(EXIT_FAILURE);
					}
			}
		}
		
        break;

        case REDR:
            rcmd = (struct redrcmd*) cmd;
				
				//Si es un comando interno
				if (isComandoInterno((struct execcmd*) rcmd->cmd)==0){

					//Nos hacemos una copia de stdout
					int fich = dup(STDOUT_FILENO);
					if (fich == -1)  panic("Error en copia de fd\n");

					//Cerramos la salida estandar
					TRY( close(rcmd->fd) );
				
					//Creamos el fichero donde va a ir la redireccion
					if ((fd = open(rcmd->file, rcmd->flags, rcmd->modo)) < 0)
					{
						perror("open");
						exit(EXIT_FAILURE);
					}
					//Ejecutamos el comando interno
					comandoInterno((struct execcmd*) rcmd->cmd);

					//Cerramos el fichero donde se ha escrito la redireccion
					TRY( close (fd) );
					//Recuperamos la salida estandar gracias a la copia que nos hicimos
					int ret = dup2(fich, fd);
					if (ret == -1) panic("Error en copia de fd\n");
					//Cerramos el fichero creado al inicio
					TRY( close (fich) );
					
				
				//En el caso de que no sea un comando interno
				} else {
					// Bloqueamos la señal SIGCHLD
					if (sigprocmask(SIG_BLOCK, &blocked_chld, NULL) == -1) {
						perror("sigprocmask");
						exit(EXIT_FAILURE);
					}
					if ((pid = fork_or_panic("fork REDR")) == 0) {
						// Cerramos stdout
						TRY( close(rcmd->fd) );
						// Abrimos el fichero donde redirigimos la salida.
						if ((fd = open(rcmd->file, rcmd->flags, rcmd->modo)) < 0)
						{
							perror("open");
							exit(EXIT_FAILURE);
						}
							if (rcmd->cmd->type == EXEC)
								exec_cmd((struct execcmd*) rcmd->cmd);
				       		else
				          	  	run_cmd(rcmd->cmd);
							exit(EXIT_SUCCESS);
				    }
					TRY( waitpid(pid, NULL, 0) );

					// Desbloqueamos la señal.
					if (sigprocmask(SIG_UNBLOCK, &blocked_chld, NULL) == -1) {
						perror("sigprocmask");
						exit(EXIT_FAILURE);
					}
				}
			
            break;

        case LIST:
            lcmd = (struct listcmd*) cmd;
            run_cmd(lcmd->left);
            run_cmd(lcmd->right);
            break;

        case PIPE:
			
            pcmd = (struct pipecmd*)cmd;
            if (pipe(p) < 0)
            {
                perror("pipe");
                exit(EXIT_FAILURE);
            }
			// Bloqueamos la señal SIGCHLD para las dos tuberias.
			if (sigprocmask(SIG_BLOCK, &blocked_chld, NULL) == -1) {
				perror("sigprocmask");
				exit(EXIT_FAILURE);
			}
	            // Ejecución del hijo de la izquierda
            	if ((pidl = fork_or_panic("fork PIPE left")) == 0)
            	{
					
                	TRY( close(1) );
                	TRY( dup(p[1]) );
                	TRY( close(p[0]) );
                	TRY( close(p[1]) );
                	if (pcmd->left->type == EXEC){
						//Si ademas es un comando interno
						if (comandoInterno((struct execcmd*) pcmd->left) != 0)
                	    	exec_cmd((struct execcmd*) pcmd->left);
                	}else
                	    run_cmd(pcmd->left);
                	exit(EXIT_SUCCESS);
            	}
				
            // Ejecución del hijo de la derecha
			
           		if ((pidr = fork_or_panic("fork PIPE right")) == 0)
            	{
            	    TRY( close(0) );
            	    TRY( dup(p[0]) );
            	    TRY( close(p[0]) );
            	    TRY( close(p[1]) );
            	    if (pcmd->right->type == EXEC){
						//Si ademas es un comando interno
						if (comandoInterno((struct execcmd*) pcmd->right) != 0)
            	       	 exec_cmd((struct execcmd*) pcmd->right);
            	    }else
            	        run_cmd(pcmd->right);
            	    exit(EXIT_SUCCESS);
            	}
            	TRY( close(p[0]) );
            	TRY( close(p[1]) );

            // Esperar a ambos hijos	
			TRY( waitpid(pidl, NULL, 0) );
			TRY( waitpid(pidr, NULL, 0) );

			// Desbloqueamos la señal.
			if (sigprocmask(SIG_UNBLOCK, &blocked_chld, NULL) == -1) {
				perror("sigprocmask");
				exit(EXIT_FAILURE);
			}
            break;

        case BACK:
            bcmd = (struct backcmd*)cmd;
			//Si es el caso especial del exit, cuando este acabe no tiene que saltar el manejador
			//de la señal. Por lo tanto se bloquea.
			if (strcmp(((struct execcmd*)bcmd->cmd)->argv[0],"exit") == 0){
				if (sigprocmask(SIG_BLOCK, &blocked_chld, NULL) == -1) {
					perror("sigprocmask");
					exit(EXIT_FAILURE);
				}
			}
			pid = fork_or_panic("fork BACK");
		    if (pid == 0){	
				if (bcmd->cmd->type == EXEC){					
					//Si es un coamdo interno
					if (comandoInterno((struct execcmd*) bcmd->cmd) != 0)
					   exec_cmd((struct execcmd*) bcmd->cmd);
				   }else
				       run_cmd(bcmd->cmd);
				
				exit(EXIT_SUCCESS);
		    }
					
			//Mostramos el PID del proceso hijo que se ha ejecutado en seguando plano
			//Y lo almacenamos en la tabla de procesos en segundo plano.
			int indice = 0;
			while (backPids[indice] != 0 && indice < MAX_BUFFER) indice ++;
			backPids[indice] = pid;
			printf("[%d]\n", pid);
	
		    break;

        case SUBS:
            scmd = (struct subscmd*) cmd;
			//Bloqueamos la señal SIGCHLD
			if (sigprocmask(SIG_BLOCK, &blocked_chld, NULL) == -1) {
				perror("sigprocmask");
				exit(EXIT_FAILURE);
			}

            if ((pid = fork_or_panic("fork SUBS")) == 0)
            {
                run_cmd(scmd->cmd);
                exit(EXIT_SUCCESS);
            }

       		TRY( waitpid(pid, NULL, 0) );
			//Desbloqueamos la señal SIGCHLD.
			if (sigprocmask(SIG_UNBLOCK, &blocked_chld, NULL) == -1) {
				perror("sigprocmask");
				exit(EXIT_FAILURE);
			}			

            break;

        case INV:
        default:
            panic("%s: estructura `cmd` desconocida\n", __func__);
    }

    DPRINTF(DBG_TRACE, "END\n");
}


void print_cmd(struct cmd* cmd)
{
    struct execcmd* ecmd;
    struct redrcmd* rcmd;
    struct listcmd* lcmd;
    struct pipecmd* pcmd;
    struct backcmd* bcmd;
    struct subscmd* scmd;

    if(cmd == 0) return;

    switch(cmd->type)
    {
        default:
            panic("%s: estructura `cmd` desconocida\n", __func__);

        case EXEC:
            ecmd = (struct execcmd*) cmd;
            if (ecmd->argv[0] != 0)
                printf("fork( exec( %s ) )", ecmd->argv[0]);
            break;

        case REDR:
            rcmd = (struct redrcmd*) cmd;
            printf("fork( ");
            if (rcmd->cmd->type == EXEC)
                printf("exec ( %s )", ((struct execcmd*) rcmd->cmd)->argv[0]);
            else
                print_cmd(rcmd->cmd);
            printf(" )");
            break;

        case LIST:
            lcmd = (struct listcmd*) cmd;
            print_cmd(lcmd->left);
            printf(" ; ");
            print_cmd(lcmd->right);
            break;

        case PIPE:
            pcmd = (struct pipecmd*) cmd;
            printf("fork( ");
            if (pcmd->left->type == EXEC)
                printf("exec ( %s )", ((struct execcmd*) pcmd->left)->argv[0]);
            else
                print_cmd(pcmd->left);
            printf(" ) => fork( ");
            if (pcmd->right->type == EXEC)
                printf("exec ( %s )", ((struct execcmd*) pcmd->right)->argv[0]);
            else
                print_cmd(pcmd->right);
            printf(" )");
            break;

        case BACK:
            bcmd = (struct backcmd*) cmd;
            printf("fork( ");
            if (bcmd->cmd->type == EXEC)
                printf("exec ( %s )", ((struct execcmd*) bcmd->cmd)->argv[0]);
            else
                print_cmd(bcmd->cmd);
            printf(" )");
            break;

        case SUBS:
            scmd = (struct subscmd*) cmd;
            printf("fork( ");
            print_cmd(scmd->cmd);
            printf(" )");
            break;
    }
}


void free_cmd(struct cmd* cmd)
{
    struct execcmd* ecmd;
    struct redrcmd* rcmd;
    struct listcmd* lcmd;
    struct pipecmd* pcmd;
    struct backcmd* bcmd;
    struct subscmd* scmd;

    if(cmd == 0) return;

    switch(cmd->type)
    {
        case EXEC:
	   
            break;

        case REDR:
            rcmd = (struct redrcmd*) cmd;
            free_cmd(rcmd->cmd);

            free(rcmd->cmd);
            break;

        case LIST:
            lcmd = (struct listcmd*) cmd;

            free_cmd(lcmd->left);
            free_cmd(lcmd->right);

            free(lcmd->right);
            free(lcmd->left);
            break;

        case PIPE:
            pcmd = (struct pipecmd*) cmd;

            free_cmd(pcmd->left);
            free_cmd(pcmd->right);

            free(pcmd->right);
            free(pcmd->left);
            break;

        case BACK:
            bcmd = (struct backcmd*) cmd;

            free_cmd(bcmd->cmd);

            free(bcmd->cmd);
            break;

        case SUBS:
            scmd = (struct subscmd*) cmd;

            free_cmd(scmd->cmd);

            free(scmd->cmd);
            break;

        case INV:
        default:
            panic("%s: estructura `cmd` desconocida\n", __func__);
    }
}


/******************************************************************************
 * Lectura de la línea de órdenes con la librería libreadline
 ******************************************************************************/


// `get_cmd` muestra un *prompt* y lee lo que el usuario escribe usando la
// librería readline. Ésta permite mantener el historial, utilizar las flechas
// para acceder a las órdenes previas del historial, búsquedas de órdenes, etc.

char* get_cmd()
{
    char* buf;
    uid_t user;
	struct passwd *pwd;
	char *ruta = malloc(PATH_MAX);
	char *directorio = malloc(PATH_MAX);
	char *prompt;

	//uid del usuario
    user = getuid();
	//Puntero a la entrada de dicho usuario
	pwd = getpwuid(user);
	//Comprobacion
	if (!pwd){
		panic("getpwuid"); 
	}
	
	//Directorio actual
	ruta = getcwd(ruta, PATH_MAX);
	//Comprobacion
	if (!ruta){
		panic("getcwd");
	}

	//Copio en la cadena directorio el nombre del directorio.
	sprintf(directorio, "%s", basename(ruta));

	//Reservo memoria para el prompt: tamaño del nombre + '@' + tamaño directorio + '>' + ' ' + '\0'.
	prompt = malloc(strlen(pwd->pw_name)+strlen(directorio)+4 *sizeof(char));
	//Lo mostramos por pantalla
	sprintf(prompt,"%s@%s> ", pwd->pw_name, directorio);

    // Lee la orden tecleada por el usuario
    buf = readline (prompt);

    // Si el usuario ha escrito una orden, almacenarla en la historia.
    if(buf)
        add_history (buf);
	
	free(directorio);
	free(ruta);
	free(prompt);
	
    return buf;

	
}


/******************************************************************************
 * Bucle principal de `simplesh`
 ******************************************************************************/


void help(int argc, char **argv)
{
    fprintf(stdout, "Usage: %s [-d N] [-h]\n\
            shell simplesh v%s\n\
            Options: \n\
            -d set debug level to N\n\
            -h help\n\n",
            argv[0], VERSION);
}


void parse_args(int argc, char** argv)
{
    int option = 0;

    // Bucle de procesamiento de parámetros
    while((option = getopt(argc, argv, "d:h")) != -1) {
        switch(option) {
            case 'd':
                g_dbg_level = atoi(optarg);
                break;
            case 'h':
            default:
                help(argc, argv);
                exit(EXIT_SUCCESS);
                break;
        }
    }
}



int main(int argc, char** argv)
{

	/* Block signal SIGSEGV */
    sigset_t blocked_signals;
	//Bloqueamos las señales
    sigemptyset(&blocked_signals);
    sigaddset(&blocked_signals, SIGQUIT);
	sigaddset(&blocked_signals, SIGINT);
	//Añadimos a la mascara las señales del conjunto. 
	//En este momento se bloquean.
    if (sigprocmask(SIG_BLOCK, &blocked_signals, NULL) == -1) {
        perror("sigprocmask");
        exit(EXIT_FAILURE);
    }

	struct sigaction sa;
	sa.sa_handler = & signal_handler;
	sigemptyset (& sa.sa_mask);
	//Definimos los flags SA_RESTART y SA_NOCLDSTOP hace que se puedan tratar las señales de llamadas al sistema y para
	//que el manejador no salte si un proceso secundario se detiene.
	sa.sa_flags = SA_RESTART | SA_NOCLDSTOP;
	//Modificamos el comportamiento por defecto de SIGCHLD para que se ejecute el manejador.
	if (sigaction(SIGCHLD, &sa, NULL) == -1 ) {
        perror("sigaction 1");
        exit(EXIT_FAILURE);
    }


   /**********************************************/
    char* buf;
    struct cmd* cmd;
	setenv("OLDPWD", "", 1);
	memset(&backPids, 0, sizeof(backPids));
	
    parse_args(argc, argv);

    DPRINTF(DBG_TRACE, "STR\n");

    // Bucle de lectura y ejecución de órdenes
    while ((buf = get_cmd()) != NULL)
    {	
        // Realiza el análisis sintáctico de la línea de órdenes
        cmd = parse_cmd(buf);
		
        // Termina en `NULL` todas las cadenas de las estructuras `cmd`
        null_terminate(cmd);

        DBLOCK(DBG_CMD, {
            printf("%s:%d:%s: print_cmd: ",
                   __FILE__, __LINE__, __func__);
            print_cmd(cmd); printf("\n"); fflush(NULL); } );

		
        // Ejecuta la línea de órdenes
        run_cmd(cmd);

        // Libera la memoria de las estructuras `cmd`
        free_cmd(cmd);
		free(cmd);
        // Libera la memoria de la línea de órdenes
        free(buf);
    }

    DPRINTF(DBG_TRACE, "END\n");

    return 0;
} 
