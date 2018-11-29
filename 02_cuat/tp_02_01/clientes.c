 
/* ********************************************************************************************************************************
  
********************************************************************************************************************************* */

#include <signal.h>
#include <unistd.h> 
#include <stdlib.h>
#include <sys/types.h>
#include <stdio.h>
#include <sys/wait.h>
#include <errno.h>
#include <time.h>
#include <sys/time.h>
#include <linux/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>

#define PORT 8000	/* El puerto donde se conectará, servidor */

#define ERROR	-1
#define PEDIR_DATO  0xa5a5a5a5
#define ESC 0x11b


/* ****************************************************************************************************************************** */

void child(struct hostent *, int, int);
void mi_sigchld(int, siginfo_t *, void *);

int hijo;

int main (int argc, char *argv[])
{
  pid_t pid;
  int i = 0;
  struct sigaction ctrl_nuevo;
  struct hostent *he;	/* Se utiliza para convertir el nombre del host a su dirección IP */
  int  t_esp;
   
  if (argc < 3)	// verifico que la cantidad de argumentos sea la correcta.
  {
    fprintf(stderr, "Argumentos insuficientes. \n");
    exit(ERROR);
  }

    if(sigemptyset(&ctrl_nuevo.sa_mask) == ERROR)		// Empiezo a setear la struct que usa el sigaction
   {
      perror("sigemptyset-sig_block_mask");
      exit(ERROR);
   };
   if(sigaddset(&ctrl_nuevo.sa_mask, SIGCHLD) == ERROR)		// para que salte solo con signal child.
   {
      perror("sigaddset-sig_block_mask");
      exit(ERROR);
   };
   ctrl_nuevo.sa_flags = SA_SIGINFO;					// defino cuando salta el sigaction
   ctrl_nuevo.sa_sigaction = mi_sigchld;				// Pongo el nuevo handler.

   if(sigaction(SIGCHLD, &ctrl_nuevo, NULL) == ERROR)			// hago el sigaction
   {
      perror("signal-SIGCHLD, sigchld_handler");
      exit(ERROR);
   };

/* ************************************************************************************************************************** */
hijo = 0;
for(i=0 ;i+2<argc ;i++)
{
	/* Convertimos el nombre del host a su dirección IP */
	if ((he = gethostbyname ((const char *) argv[1+i])) == NULL)
	{
		perror("Error en gethostbyname");
		exit(1);
	}
	
	t_esp = atoi(argv[2+i]); /*Tiempo de encuesta*/
	i++;
    hijo++;
	printf("Lanzo hijo %d\n", hijo);
    pid = fork();
    if (pid == -1)
    {
      perror("fork");
      exit(1);
    }
    else if (!pid)						// Si es el hijo
        child(he,t_esp, hijo);
}

printf("Termino el padre, espera a que terminen los hijos (%d)\n", hijo);
while(hijo)
{
	sleep(1);
}

  return(0);
}  

/* ****************************************************************************************************************************** */
/*   */

void child(struct hostent *he, int t_esp, int proceso)
{
  int x=0;       //x lleva la cuenta de intentos fallidos de lectura o escritura si es por EAGAIN o EWOULDBLOCK.
  int mensaje = PEDIR_DATO;
  pid_t pid = getpid();
  //struct tm * stamp_s;
  //time_t tiempo_aux;
  //char       buf[80];

  /*struct paquete{
	  float temperatura;
	  time_t tiempo;
  } dato;*/
  
  struct envio{
	  float temp;
	  int hora;
	  int min;
	  int seg;
  } _forrecv;

  int sockfd;  		/*File Descriptor para sockets*/
  int numbytes;		/*Contendrá el número de bytes recibidos por read () */
  struct sockaddr_in their_addr;  /* dirección del server donde se conectará */

 
/* Creamos el socket */
	if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		fprintf(stderr,"Error en creación de socket. Proceso %d, PID %d\n", proceso,  pid);
		exit(1);
	}

/* Establecemos their_addr con la direccion del server */
	their_addr.sin_family = AF_INET;
	their_addr.sin_port = htons(PORT);
	their_addr.sin_addr = *((struct in_addr *)he->h_addr);
	bzero(&(their_addr.sin_zero), 8);

/* Intentamos conectarnos con el servidor */
	if (connect(sockfd, (struct sockaddr *)&their_addr, sizeof(struct sockaddr)) == -1)
	{
		fprintf(stderr,"Error tratando de conectar al server 1. Proceso %d, PID %d\n", proceso,  pid);
        close(sockfd);
		exit(ERROR);
	}
    
    printf("Proceso %d iniciado, PID = %d, pide datos cada %d\n", proceso, pid, t_esp);
    
do{
        /* pido dato */
    do{
		printf("Pido data\n");
        if (send (sockfd, &mensaje, sizeof (mensaje), MSG_DONTWAIT) == -1)
        {
            if((errno == EAGAIN) || (errno == EWOULDBLOCK))
            {
                x++;
                sleep(1);
            }
            else
            {
                fprintf(stderr,"Conexion cerrada en el proceso: %d, PID: %d\n", proceso, pid);
                close(sockfd);
                exit (ERROR);
            }
        }
        else
            x = 0;
    }while(x != 0);
	  
	  
	  /* recibo dato */
    do{
        if ((numbytes = recv (sockfd, &_forrecv, sizeof(_forrecv), MSG_DONTWAIT)) == -1)
        {
            if((errno == EAGAIN) || (errno == EWOULDBLOCK))
            {
                x++;
                if(x == 10)
                {
                    fprintf(stderr,"No se recive nada, ERROR DE CONEXIÓN. Proceso %d, PID %d\n", proceso,  pid);
                    close(sockfd);
                    exit(ERROR);
                }
                sleep(1);
            }
            else
            {
                fprintf(stderr,"error de lectura en el socket. Proceso %d, PID %d\n", proceso,  pid);
                exit(ERROR);
            }
        }
        else
        {
            if(numbytes == 0)
            {
                    fprintf(stderr,"No se recive nada, ERROR DE CONEXIÓN. Proceso %d, PID %d\n", proceso,  pid);
                    exit(ERROR);
            }
            //recv (sockfd, &tiempo_aux, sizeof(time_t), MSG_DONTWAIT);
            //printf("dato recibido aaaaa\n");
            //tiempo_aux = dato.tiempo;
			//s_time = localtime(&tiempo_aux);
			//strftime(buf, sizeof(buf), "%a %Y-%m-%d %H:%M:%S %Z", s_time);
            //s_time = gmtime(&tiempo_aux);
			//printf("dato recibido bbbbb\n");
            printf("Proceso %d, PID %d - Recibido: Temperatura = %f ; Fecha y Hora = ",proceso, pid, _forrecv.temp);
			//stamp_s = gmtime(&dato.tiempo);
			printf("[%d : %d : %d]\n", _forrecv.hora, _forrecv.min, _forrecv.seg);
			//printf("%d\n",(int)dato.tiempo);
			//printf("%d\n",(int)tiempo_aux);
            x = 0;
            sleep(t_esp);
        }
    }while(x != 0);
	
        
}while(1);

 printf("Cerrando proceso %d, PID %d\n",proceso,pid);
 close(sockfd);
  
  exit(0);
}


/* ****************************************************************************************************************************** */
/* Manejo de señales */

void mi_sigchld(int c, siginfo_t * a, void * b)		// handler de señal sigchld.
{
  int status;

 waitpid(-1,&status,WNOHANG|WUNTRACED);
 hijo--;

  
  return;
}
