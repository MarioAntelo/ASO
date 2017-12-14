#include "types.h"
#include "stat.h"
#include "user.h"

//miramos el error codigo error que genera el trap en x86
//http://wiki.osdev.org/Exceptions#Page_Fault
// explica el vector trap con todos los errores


int overflow(int n){
	return n++;
}

int main(int argc, char *argv[]){
	
}
