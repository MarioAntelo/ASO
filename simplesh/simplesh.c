/*
 * Shell `simplesh` (basado en el shell de xv6)
 *
 * Ampliación de Sistemas Operativos
 * Departamento de Ingeniería y Tecnología de Computadores
 * Facultad de Informática de la Universidad de Murcia
 *
 * Alumnos: ANTELO RIBERA, MARIO
 *          PIÑAS AYALA, MARTIN
 *
 * Convocatoria: JULIO
 */

/*
 * Ficheros de cabecera
 */


//#define NDEBUG // Translate asserts and DMACROS into no ops
#define _POSIX_SOURCE
#define _GNU_SOURCE
#include <assert.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/stat.h>
#include <pwd.h>
#include <libgen.h>
#include <sys/wait.h>


// Librería readline
#include <readline/readline.h>
#include <readline/history.h>


/******************************************************************************
* Constantes, macros y variables globales
******************************************************************************/


static const char* VERSION = "0.17";
static const size_t PATH_MAX = 100;
static const size_t TAM_MAX = 100;
static const int low_read =8;
static const int high_read = 1048576; // 1 MB
static int hijo_fin = 0; // 1 MB

// Niveles de depuración
#define DBG_CMD   (1 << 0)
#define DBG_TRACE (1 << 1)
// . . .
static int g_dbg_level = 0;

#ifndef NDEBUG
#define DPRINTF(dbg_level, fmt, ...)                                                        \
        do {                                                                                                                \
                if (dbg_level & g_dbg_level)                                                        \
                        fprintf(stderr, "%s:%d:%s(): " fmt,                                 \
                                __FILE__, __LINE__, __func__, ## __VA_ARGS__);              \
        } while ( 0 )

#define DBLOCK(dbg_level, block)                                                                \
        do {                                                                                                                \
                if (dbg_level & g_dbg_level)                                                        \
                        block;                                                                                            \
        } while( 0 );
#else
#define DPRINTF(dbg_level, fmt, ...)
#define DBLOCK(dbg_level, block)
#endif

#define TRY(x)                                                                                                    \
        do {                                                                                                                \
                int __rc = (x);                                                                                 \
                if( __rc < 0 ) {                                                                                \
                        fprintf(stderr, "%s:%d:%s: TRY(%s) failed\n",             \
                                __FILE__, __LINE__, __func__, # x);                   \
                        fprintf(stderr, "ERROR: rc=%d errno=%d (%s)\n",         \
                                __rc, errno, strerror(errno));                            \
                        exit(EXIT_FAILURE);                                                                 \
                }                                                                                                             \
        } while( 0 )


// Número máximo de argumentos de un comando
#define MAXARGS 16


static const char WHITESPACE[] = " \t\r\n\v";
static const char SYMBOLS[] = "<|>&;()";


/******************************************************************************
* Funciones auxiliares
******************************************************************************/
int run_command_interno(char**);
void run_cwd();
int run_cd(char*);
int run_trod(char**);
int run_args(char**);

// Estructura con las opciones que contiene el comando trod
struct opc_trod {
        int flag_t;
        int flag_d;
        int flag_c;
        int valor_t;
};

// Estructura con las opciones que contiene el comando args
struct opc_args{
  int flag_d;
  int flag_p;
  int valor_p;
  char* valor_d;
};

//variables necesarias
static struct opc_trod opc;
static struct opc_args opc_arg;
int run_bjobs(char**);

//Declaraciones para variables de entorno
extern char **environ;
int setenv(const char *, const char *, int);
int unsetenv(const char *);
int clearenv(void);
int sigemptyset(sigset_t *);
int sigaddset(sigset_t *s, int );
int sigprocmask(int, const sigset_t *, sigset_t *);
pid_t waitpid(pid_t, int *, int );

typedef struct proc {
        int pid;
        struct proc * sig;
}proc;

typedef struct ListaProceso {
        int procesos;
        struct proc *inicio;
}ListaProceso;

struct ListaProceso *lista;
void crea_listaProc();
void insertarProceso(int pid);
void eliminarProceso(int pid);


// Imprime el mensaje de error
void error(const char *fmt, ...)
{
        va_list arg;

        fprintf(stderr, "%s: ", __FILE__);
        va_start(arg, fmt);
        vfprintf(stderr, fmt, arg);
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
enum cmd_type { EXEC=1, REDR=2, PIPE=3, LIST=4, BACK=5, SUBS=6, INV=7 };

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

void print_cmd(struct cmd* cmd);
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
                    int flags, int fd)
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
                assert(delimiter == '<' || delimiter == '>'|| delimiter == '+');

                // El siguiente token tiene que ser el nombre del fichero de la
                // redirección entre `start_of_token` y `end_of_token`.
                if ('a' != get_token(start_of_str, end_of_str, &start_of_token, &end_of_token))
                        error("%s: error sintáctico: se esperaba un fichero", __func__);

                // Construye el `cmd` para la redirección
                switch(delimiter)
                {
                case '<':
                        cmd = redrcmd(cmd, start_of_token, end_of_token, O_RDONLY, 0);
                        break;
                case '>':
                        cmd = redrcmd(cmd, start_of_token, end_of_token, O_RDWR|O_CREAT|O_TRUNC, 1);
                        break;
                case '+': // >>
                        cmd = redrcmd(cmd, start_of_token, end_of_token, O_RDWR|O_CREAT|O_APPEND, 1);
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


void exec_cmd(struct execcmd* ecmd)
{
        assert(ecmd->type == EXEC);

        if (ecmd->argv[0] == 0) exit(EXIT_SUCCESS);

        //compruebo si el comando introducido es un comando interno
        int result = run_command_interno(ecmd->argv);
        if (result != -1)
                exit(EXIT_SUCCESS);
        else
                execvp(ecmd->argv[0], ecmd->argv);

        panic("no se encontró el comando '%s'\n", ecmd->argv[0]);
}


int run_cmd(struct cmd* cmd)
{
        struct execcmd* ecmd;
        struct redrcmd* rcmd;
        struct listcmd* lcmd;
        struct pipecmd* pcmd;
        struct backcmd* bcmd;
        struct subscmd* scmd;
        int p[2];
        int fd;
        pid_t pid;

        DPRINTF(DBG_TRACE, "STR\n");

        if(cmd == 0) return 0;

        switch(cmd->type)
        {
        case EXEC:
                ecmd = (struct execcmd*) cmd;

                //compruebo si el comando introducido es un comando interno
                int result = run_command_interno(ecmd->argv);
                if (result != -1)
                        return result;
                //comandos no internos
                pid = fork_or_panic("fork EXEC");
                if ( pid == 0)
                        exec_cmd(ecmd);
                else{
                        if(waitpid(pid,NULL ,0) < 0) {
                                perror("waitpid");
                        }

                }
                break;

        case REDR:
                rcmd = (struct redrcmd*) cmd;
                pid = fork_or_panic("fork REDR");
                if ( pid == 0)
                {
                        TRY( close(rcmd->fd) );
                        //a la llamada open se agrega el modo S_IRWX_
                        if ((fd = open(rcmd->file, rcmd->flags, S_IRWXU)) < 0) {
                                perror("open");
                                exit(EXIT_FAILURE);
                        }

                        if (rcmd->cmd->type == EXEC)
                                exec_cmd((struct execcmd*) rcmd->cmd);
                        else
                                run_cmd(rcmd->cmd);
                        exit(EXIT_SUCCESS);
                }else{
                        if(waitpid(pid,NULL,0) < 0) {
                                perror("waitpid");
                        }
                }
                break;

        case LIST:
                lcmd = (struct listcmd*) cmd;
                if(run_cmd(lcmd->left)==1)
                        return 1;
                if(run_cmd(lcmd->right)==1)
                        return 1;
                break;

        case PIPE:
                pcmd = (struct pipecmd*)cmd;
                if (pipe(p) < 0) {
                        perror("pipe");
                        exit(EXIT_FAILURE);
                }

                // Ejecución del hijo de la izquierda
                if (fork_or_panic("fork PIPE left") == 0) {
                        TRY( close(1) );
                        TRY( dup(p[1]) );
                        TRY( close(p[0]) );
                        TRY( close(p[1]) );
                        if (pcmd->left->type == EXEC)
                                exec_cmd((struct execcmd*) pcmd->left);
                        else
                                run_cmd(pcmd->left);
                        exit(EXIT_SUCCESS);
                }

                // Ejecución del hijo de la derecha
                if (fork_or_panic("fork PIPE right") == 0)
                {
                        TRY( close(0) );
                        TRY( dup(p[0]) );
                        TRY( close(p[0]) );
                        TRY( close(p[1]) );
                        if (pcmd->right->type == EXEC)
                                exec_cmd((struct execcmd*) pcmd->right);
                        else
                                run_cmd(pcmd->right);
                        exit(EXIT_SUCCESS);
                }
                TRY( close(p[0]) );
                TRY( close(p[1]) );

                // Esperar a ambos hijos
                TRY( wait(NULL) );
                TRY( wait(NULL) );
                break;

        case BACK:
                bcmd = (struct backcmd*)cmd;
                pid = fork_or_panic("fork BACK");
                if (pid == 0)
                {
                        if (bcmd->cmd->type == EXEC)
                                exec_cmd((struct execcmd*) bcmd->cmd);
                        else
                                run_cmd(bcmd->cmd);
                        exit(EXIT_SUCCESS);
                }
                else{
                        insertarProceso(pid);
                        printf("[%d]\n", pid);
                }
                break;

        case SUBS:
                scmd = (struct subscmd*) cmd;
                if (fork_or_panic("fork SUBS") == 0)
                {
                        run_cmd(scmd->cmd);
                        exit(EXIT_SUCCESS);
                }
                TRY( wait(NULL) );
                break;

        case INV:
        default:
                panic("%s: estructura `cmd` desconocida\n", __func__);
        }

        DPRINTF(DBG_TRACE, "END\n");
        return 0;
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
        struct passwd* pw;
        char ruta[PATH_MAX];

        uid_t uid = getuid();
        pw = getpwuid(uid);

        if(!pw) {
                perror("getpwuid");
                exit(EXIT_FAILURE); //ABORTAMOS LA APLICACION
        }

        if(!getcwd(ruta, PATH_MAX)) {
                perror("getcwd");
                exit(EXIT_FAILURE);
        }

        char *dirname = basename(ruta);
        if(!dirname) {
                perror("basename");
                exit(EXIT_FAILURE);
        }
        //conformamos la linea a mostrar en el prompt
        char prompt[PATH_MAX];   //= malloc();// @ > space y el 0 al final
        int i = sprintf(prompt, "%s@%s> ", pw->pw_name, dirname);
        //comprobamos que el tamaño del buffer sea suficiente
        if(i <=0 ) {
                perror("sprintf");
                exit(EXIT_FAILURE);
        }else if(i >= PATH_MAX) {
                perror("sprintf necesita buffer con mayor tamaño");
                exit(EXIT_FAILURE);
        }
        // Lee la orden tecleada por el usuario
        buf = readline (prompt);

        // Si el usuario ha escrito una orden, almacenarla en la historia.
        if(buf)
                add_history (buf);

        return buf;
}


/******************************************************************************
* Bucle principal de `simplesh`
******************************************************************************/


void help(int argc, char **argv){
        fprintf(stdout, "Usage: %s [-d N] [-h]\n\
          shell simplesh v%s\n\
          Options: \n\
          -d set debug level to N\n\
          -h help\n\n",
                argv[0], VERSION);
}


void parse_args(int argc, char** argv){
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
/*
 * Sub-rutinas para Comandos internos
 */
int run_command_interno(char **command){
        if (command[0] != 0) {
                //trato comandos internos
                if(strcmp(command[0], "cwd") == 0) {
                        run_cwd();
                }else if(strcmp(command[0], "exit") == 0) {
                        return 1;
                }else if(strcmp(command[0], "cd") == 0) {
                        run_cd(command[1]);
                }else if(strcmp(command[0], "trod") == 0) {
                        run_trod(command);
                }else if(strcmp(command[0], "args") == 0){
                	run_args(command);
                }else if(strcmp(command[0], "bjobs") == 0) {
                        run_bjobs(command);
                }else
                        return -1;
        }
        return EXIT_SUCCESS;
}

/*
 * Muestra la ruta actual
 */
void run_cwd(){
        char buff[PATH_MAX];
        char* ruta = getcwd(buff, PATH_MAX);
        if (!ruta) {
                perror("getcwd");
                exit(EXIT_FAILURE);
        }
        fprintf(stderr, "simplesh: cwd: ");
        printf("%s\n", ruta);
}

int run_cd(char* dir){
        int error = 0;
        char* ruta;
        char* ruta_act;

        if(!dir) {
                ruta = getenv("HOME");
                if(!ruta) {
                        fprintf(stderr, "run_cd: Variable $HOME no está definida");
                        exit(EXIT_FAILURE);
                }
        }else if(strcmp(dir, "-")==0) {
                ruta = getenv("OLDPWD");
                if(!ruta) {
                        fprintf(stderr, "run_cd: Variable $OLDPWD no está definida");
                        return -1;
                }
        }else
                ruta = dir;

        //recupera la ruta actual para guardarla
        ruta_act = getenv("PWD");
        if(!ruta_act) {
                fprintf(stderr, "run_cd: Variable $PWD no está definida");
        }

        if(chdir(ruta) == -1)
                perror(ruta);
        else{
                error = setenv("OLDPWD", ruta_act, 1);
                if(error!=0) {
                        perror("run_cd");
                }
        }
        return 0;
}
//******************
//***comando trod
void help_trod(){
        printf("Uso: trod [-t TAMAÑO] [-d] [-c] SET1 [SET2]\n");
        printf("\tSET1 y SET2 son conjuntos de caracteres\n");
        printf("\tOpciones:\n");
        printf("\t-t TAMAÑO en bytes de los bloques leídos de \'stdin\'\n");
        printf("\t-d Borra los contenidos de SET1\n");
        printf("\t-c Comprime  los caracteres de SET1\n");
        printf("\t-h help\n");
}

int procesa_getopt(char **command){
        int cant_param=0;
        int opt =0;
        char *valor=NULL;

        for(int i=0; command[i] != NULL; i++)
                cant_param+=1;

        //borro los valores anteriores de opc
        opc.flag_t = 0;
        opc.flag_d = 0;
        opc.flag_c = 0;
        //los : son para decir que la opcion requiere un parametro
        while((opt=getopt(cant_param,command,"t:dch")) != -1) {
                switch(opt) {
                case 't':
                        opc.flag_t = 1;
                        valor = optarg;
                        //guardo el valor en bytes
                        opc.valor_t = atoi(valor)*8;
                        break;
                case 'd':
                        opc.flag_d = 1;
                        break;
                case 'c':
                        opc.flag_c = 1;
                        break;
                case 'h':
                        help_trod();
                        return 1;
                        break;
                default:
                        fprintf(stderr, "Opción -%c desconocida.\n", optopt);
                        return -1;
                        break;
                }
        }

        return 0;   //si hemos procesado los argumentos se devuelve 0
}

//Función trod

int run_trod(char **command){
        char* set1;
        char* set2;
        char* c;
        char ant;
        char*  write_char;
        int tam_read = 1;
        //guardo las opciones en la estructura opc
        optind = 1;
        if (procesa_getopt(command)!=0)
                return -1;

        //asigno los bytes que leere
        if (opc.flag_t == 1) {
                tam_read = opc.valor_t;
                if (tam_read < low_read || tam_read >= high_read) {
                        fprintf(stderr, "run_trod: Tamaño no válido\n");
                        return -1;
                }
        }
        if (command[optind] != NULL) {
                //leo los 2 subconjuntos
                set1 = command[optind];
                optind++;
                if (command[optind] != NULL) {
                        set2 = command[optind];
                        int len1 = strlen(set1);
                        int len2 = strlen(set2);
                        if (len1 != len2 ) {
                                fprintf(stderr, "run_trod: SET1 y SET2 deben tener el mismo tamaño\n");
                                return -1;
                        }
                        if ( opc.flag_d == 1 || opc.flag_c == 1) {
                                fprintf(stderr, "run_trod: Se debe especificar sólo SET1\n");
                                return -1;
                        }
                }else{
                  if ( opc.flag_c == 0  && opc.flag_d == 0){
                    fprintf(stderr, "run_trod: Se debe especificar tanto SET1 como SET2\n");
                    return -1;
                  }else if ( opc.flag_d == 1 && opc.flag_c == 1){
                    fprintf(stderr, "run_trod: Parámetros incompatibles\n");
                    return -1;
                  }

                }
                //Error cuando hay mas de 2 cadenas
                optind++;
                if (command[optind] != NULL) {
                   fprintf(stderr, "run_trod: Se debe especificar tanto SET1 como SET2\n");
                   return -1;
                }
                //procedo con la lectura de stdin
                char buf[tam_read];
                for (size_t i = 0; i < tam_read; i++)
                        buf[i] = 0;

                int bytesLeidos=0;

                while( (bytesLeidos = read(STDIN_FILENO, buf, tam_read))!= 0) {
                        if (bytesLeidos == -1) {
                                perror("read stdin");
                                return -1;
                        }
                        for(size_t i =0; i < bytesLeidos; i++) {
                                //compruebo todos los byte leidos
                                c = strchr(set1, buf[i]);
                                if(c != NULL) {
                                        if( opc.flag_d != 1) {
                                             if(opc.flag_c == 1){
                                               if ( *c != ant){
                                                 ant = *c;
                                                 write(1, c, 1);
                                                }
                                             }else{
                                                write_char = &set2[c-set1];
                                                write(1, write_char, 1);
                                             }
                                        }
                                }else
                                        write(1, &buf[i], 1);
                                if (fsync(1) == -1) {
                                   if( errno != EINVAL){
                                     perror("run_trod");
                                     return -1;
                                   }
                                }
                        }
                }
        }else{
                fprintf(stderr, "Comando trod no valido");
        }

        return 0;
}
//******************
//***Comando args
void help_args(){
        printf("Uso: args [-d DELIMS] [-p NPROCS ] [-h ] [COMANDO [PARAMETROS]] ...\n");
        printf("\tOpciones:\n");
        printf("\t-d DELIMS Caracteres delimitadores entre cadenas para COMANDO\n");
        printf("\t-p NPROCS Número máximo de ejecuciones en paralelo de COMANDO\n");
        printf("\t-h help\n");
}

int args_getopt(char **command){
        int cant_param=0;
        int opt = 0;

        for(int i=0; command[i] != NULL; i++)
                cant_param+=1;

        //borro los valores anteriores de opc
        opc_arg.flag_d = 0;
        opc_arg.valor_d = NULL;

        opc_arg.flag_p = 0;
        opc_arg.valor_p = 0;
        //los : son para decir que la opcion requiere un parametro
        while((opt=getopt(cant_param,command,"d:p:h")) != -1) {
           switch(opt) {
                 //Cambio de delimitadores
              case 'd':
                  opc_arg.flag_d = 1;
                  opc_arg.valor_d = optarg;
              				break;
              case 'p':
                  opc_arg.flag_p = 1;
                  opc_arg.valor_p = atoi(optarg);
              				break;
              case 'h':
                  help_args();
                  return -1;
                  break;
              default:
                      fprintf(stderr, "Opción -%c desconocida.\n", optopt);
                      return -1;
                      break;
                }
        }

        return 0;  //si hemos procesado los argumentos se devuelve 0
}


//Función args
int run_args(char **command){
      char*  args;
      struct cmd* cmd;
      struct execcmd* ecmd;
      int pid ;
      int indice = 0;
      int status = 0;
      int procesos = 1;
      char *delims =(char*) WHITESPACE;

      char line[TAM_MAX];
      for (size_t i = 0; i < TAM_MAX; i++)
              line[i] = 0;

      ecmd = (struct execcmd*) execcmd();
      //Guardamos las opciones en la estructura opc
      optind = 1;
      if (args_getopt(command)!=0)
              return -1;
      //Asignamos los bytes que se van a leer
      if (opc_arg.flag_d == 1) {
          delims = opc_arg.valor_d;
      }

      if (command[optind]==NULL){
           ecmd->argv[0] = "echo";
           indice++;
      }else{
         while (command[optind] != NULL) {
           ecmd->argv[indice] = command[optind];
           indice++;
           optind++;
         }
      }

      int bytesLeidos=0;
      while((bytesLeidos = read(STDIN_FILENO, line, TAM_MAX))!=0){
          if (opc_arg.flag_p == 1)
            procesos = opc_arg.valor_p;
          else
            procesos = 1;

         char *pChr = strtok (line, delims);

         while (pChr != NULL) {
             ecmd->argv[indice] = pChr;
             ecmd->argv[indice+1] = '\0';
             if ( fork_or_panic("fork ARGS") == 0){
                 exec_cmd(ecmd);
                 exit(EXIT_SUCCESS);
             }
             else{
               procesos--;
               if(procesos == 0){
                 wait(&status);
                 procesos++;
                 if (status != 0 )
                    exit(EXIT_SUCCESS);
               }
             }
             pChr = strtok (NULL, delims);
         }
      }

      return 0;
}

// Manejador de señal CHLD

void signal_handler(int sig, siginfo_t *info, void *context){
        //para matar todos los procesos zombie
        while (waitpid(-1, NULL, WNOHANG) > 0) {
        }
        switch(sig) {
          case SIGCHLD:
                eliminarProceso(info->si_pid);
                break;
        }
}
void crea_listaProc(){
        lista=(ListaProceso*)malloc(sizeof(ListaProceso*));
        lista->procesos= 0;
        lista->inicio = NULL;
}
void insertarProceso(int pid){
        proc *pp = lista->inicio;
        //creo la proc que contendra la informacion del proceso
        proc *aux = (proc *)malloc(sizeof(proc));
        aux->pid = pid;
        aux->sig = NULL;

        //compruebo si la lista esta vacia
        if(lista->procesos == 0)
                lista->inicio = aux;
        else{
                while(pp->sig != NULL)
                        pp = pp->sig;
                pp->sig =  aux;
        }
        //aumento la cantidad de procesos en segundo plano
        lista->procesos++;
}
void eliminarProceso(int pid){
        proc *pp = lista->inicio;
        proc *ppAnt = lista->inicio;

        if(lista->procesos !=0) {
                //Con esto comprobamos si el proceso a eliminar es el primero y lo quitamos de la lista sino se busca
                if(lista->inicio->pid == pid)
                        lista->inicio = lista->inicio->sig;
                else
                        while( (pp != NULL) && (pp->pid != pid) ) {
                                ppAnt=pp;
                                pp = pp->sig;
                        }

                if (pp != NULL) {
                        lista->procesos--;
                        printf("[%d]\n", pid);
                        proc *aux = pp;
                        pp = pp->sig;
                        ppAnt->sig=pp;
                        free(aux);
                }
                if (lista->procesos==0)
                        lista->inicio= NULL;
        }
}

void help_bjobs(){
        printf("Uso: bjobs [-k] [-h] \n");
        printf("\tOpciones:\n");
        printf("\t-k Mata todos los procesos en segundo plano\n");
        printf("\t-h help\n");
}
int run_bjobs(char **command){
        proc *pp = lista->inicio;
        int pid;
        int cant_param=0;
        int opt =1;

        for(int i=0; command[i] != NULL; i++)
                cant_param+=1;

        //borro los valores anteriores de opc
        int flag_k = 0;
        //los : son para decir que la opcion requiere un parametro
        if ( cant_param > 1) {
                while((opt=getopt(cant_param,command,"kh")) != -1) {
                        switch(opt) {
                        case 'k':
                                flag_k = 1;
                                break;
                        case 'h':
                                help_bjobs();
                                return 0;
                                break;
                        default:
                                if(isprint(optopt))
                                        fprintf(stderr, "Opción -%c desconocida.\n", optopt);
                                else
                                        fprintf(stderr, "Caracter `\\x%x' de opción desconocida.\n", optopt);
                                return 0;
                                break;
                        }
                }
        }
        if(lista->procesos > 0)
                //printf("0\n");
        {
          while(pp != NULL) {
                  pid=pp->pid;
                  pp=pp->sig;
                  if (flag_k ==1) {
                          kill(pid, SIGKILL);
                  }else
                          printf("[%d]\n", pid);
          }
         }
        return 0;
}

int main(int argc, char** argv){
        char* buf;
        struct cmd* cmd;
        int salir = 0;

        //borro la variable OLDPWD
        int result = unsetenv("OLDPWD");
        if (result!=0) {
                perror("error");
        }
        crea_listaProc();
        sigset_t blocked;
        sigemptyset(&blocked);
        sigaddset(&blocked, SIGQUIT);
        sigaddset(&blocked, SIGINT);

       if (sigprocmask(SIG_BLOCK, &blocked, NULL) == -1) {
            perror("sigprocmask");
            exit(EXIT_FAILURE);
        }

        //Práctica. Boletin 5. Instalar manejador de señal para señal SIGCHLD
        struct sigaction sa;
        memset(&sa, 0, sizeof(sa));
        sa.sa_sigaction = &signal_handler;
        sa.sa_flags = SA_RESTART | SA_SIGINFO;
        sigemptyset(&sa.sa_mask);
        if (sigaction(SIGCHLD, &sa, NULL) == -1) {
                perror("sigaction 1");
                exit(EXIT_FAILURE);
        }

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
                               print_cmd(cmd); printf("\n"); fflush(NULL);
                       } );

                // Ejecuta la línea de órdenes
                //guardo el resultado de la ejecución
                salir = run_cmd(cmd);

                // Libera la memoria de las estructuras `cmd`
                free_cmd(cmd);

                // Libera la memoria de la línea de órdenes
                free(buf);
                //saldo despues de liberar memoria si se ha introducido un exit
                if (salir == 1 )
                        exit(EXIT_SUCCESS);

        }

        DPRINTF(DBG_TRACE, "END\n");

        return 0;
}
