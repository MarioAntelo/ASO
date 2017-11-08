#include "types.h"
#include "stat.h"
#include "fcntl.h"
#include "user.h"


int main(void){
//Ejemplo 1 fichero y salida estandar (1)
	int fd;
	fd = open("salida.txt", O_WRONLY | O_CREATE);
	if (fd == -1) {
		exit();
	}

	if (dup2(fd, 1) == -1) {
		exit();
	}

	if (close(fd) == -1) {
		exit();
	}

	printf(1, "Prueba salida ejemplo 1. Debe estar en salida.txt.\n");


//Ejemplo 2 ficheros
	int fd1;
	int fd2;
	fd1 = open("out.txt", O_CREATE|O_RDWR);
	fd2 = open("out2.txt", O_CREATE|O_WRONLY);

	if (fd2 == -1) {
		exit();
	}
	
	if (dup2(fd2, fd1) == -1) {
		exit();
	}

	if (close(fd2) == -1) {
		exit();
	}

	printf(fd1, "Prueba salida ejemplo 2. Debe estar en out2.txt.\n");
	
	exit();
}