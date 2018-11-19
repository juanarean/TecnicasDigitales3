
#include <signal.h>
#include <unistd.h> 
#include <stdlib.h>
#include <sys/types.h>
#include <stdio.h>
#include <sys/wait.h>
#include <errno.h>
#include <time.h>
#include <sys/time.h>

#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>

#include <sys/shm.h>
#include <sys/ipc.h>
#include <sys/sem.h>

#define ERROR	-1
#define PORT 8000		/* El puerto donde se conectará, servidor */
#define BACKLOG 10	/* Tamaño de la cola de conexiones recibidas */
#define MEM_SIZE 40


/* ******************************************************************************************************************************************* */

void child(int);
int aceptar_pedidos(int, int);		//este es la rutina del padre, aceptar pedidos y a los hijo le manda la direccion a la que mandar la data.
void mi_sigchld(int, siginfo_t *, void *);

int fdi2c;
char dato_rx[2];
char pointer=0;
float temp;

key_t keyshm, keysem;
int shmid, semid;
struct sembuf sb = {0, -1, SEM_UNDO}; 

	union semun {
	int	val;			/* valor para SETVAL */
	struct	semid_ds *buf;		/* buffer para IPC_STAT e IPC_SET */
	unsigned short int *array;	/* valor para GETALL y SETALL */
	struct seminfo *__buf;		/* buffer para IPC_INFO */
	}arg;

int main ()
{
  pid_t pid;
  int i = 1, j, k, aux;
  struct sigaction ctrl_nuevo;
  int sockfd;			 /* File Descriptor del socket por el que el servidor "escuchará" conexiones*/
  struct sockaddr_in my_addr;	/* contendrá la dirección IP y el número de puerto local */

  int fdi2c;
  char dato_rx[2];
  char pointer=0;
  float *temp, temp_aux;
    
    if(sigemptyset(&ctrl_nuevo.sa_mask) == ERROR)		// Empiezo a setear la struct que usa el sigaction
   {
      perror("sigemptyset-sig_block_mask");
      exit(ERROR);
   };
   if(sigaddset(&ctrl_nuevo.sa_mask, SIGCHLD) == ERROR)		// para que alte solo con signal child.
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

/* **************************************************************************************************************************************
 * preparo para recivir conexiones.
 * ************************************************************************************************************************************* */
/*Crea un socket y verifica si hubo algún error*/
	if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) 
	{
	fprintf(stderr, "Error en función socket. Código de error %s\n", strerror(sockfd));
	exit(ERROR);
	}
	
/* Asignamos valores a la estructura my_addr */

	my_addr.sin_family = AF_INET;		/*familia de sockets INET para UNIX*/
	my_addr.sin_port = htons(PORT);	/*convierte el entero formato PC a entero formato network*/
	my_addr.sin_addr.s_addr = INADDR_ANY;	/* automaticamente usa la IP local */
	bzero(&(my_addr.sin_zero), 8);		/* rellena con ceros el resto de la estructura */

/* Con la estructura sockaddr_in completa, se declara en el Sistema que este proceso escuchará pedidos por la IP y el port definidos*/
	if ( (bind (sockfd, (struct sockaddr *) &my_addr, sizeof(struct sockaddr))) == -1)
	{
		perror("Error en función bind. Código de error %s\n");
		exit(ERROR);
	}

/* Habilitamos el socket para recibir conexiones, con una cola de conexiones en espera que tendrá como máximo el tamaño especificado en BACKLOG*/
	if (listen (sockfd, BACKLOG) == -1)
	{
		perror("Error en función listen. Código de error %s\n");
		exit(ERROR);
        }

/* ************************************************************************************************************************************** */
/* Shared memory: */

  if ((keyshm = ftok("server.c", 'R')) == -1) 
  {
     perror("ftok");
     exit(ERROR);
  }

  if ((shmid = shmget(keyshm, 5*sizeof(float), 0666 | IPC_CREAT)) == -1) 
  {
      perror("shmget");
      exit(ERROR);
   }
   
           temp = shmat(shmid, (void *)0, 0); //tomo la shared memory
		    if (temp == (float *)(-1)) 
				{
				perror("shmat");
				exit(1);
				}

/* ************************************************************************************************************************************** */
/* Inicio semáforo: */

if ((keysem = ftok("server.c", 'J')) == -1) {
            perror("ftok");
            exit(1);
        }

        /* crea el semáforo y lo setea en 1 */
        if ((semid = semget(keysem, 1, 0666 | IPC_CREAT)) == -1) {
            perror("semget");
            exit(1);
        }

        /* inicializa el semáforo #0 a 1: */
        arg.val = 1;
        if (semctl(semid, 0, SETVAL, arg) == -1) {
            perror("semctl");
            exit(1);
        }


/* ************************************************************************************************************************************** */
/* Proceso para leer la temperatura: */

pid = fork();
if (pid == -1)
{
  perror("fork");
  exit(ERROR);
}

if (!pid)
{
	printf("Abriendo dispositivo...\n");
   fdi2c = open("/dev/td3_i2c", O_RDWR);
        if(fdi2c < 0)
		  {
            printf("Error al abrir dispositivo\n");
            exit(ERROR);
        }
        printf("Se abrio el dispositivo correctamete\n");
       //  Escribo el pointer register en el sensor 

        aux = write(fdi2c, &pointer, sizeof(pointer));
        if(aux<=0){
            printf("Error al escribir en el dispositivo");
            return -1;
        }
        printf("Exito al escribir el pointer register\n"); 
        
        
    while(1)
	 {
        sleep(1);        
        /* Intento leer 2 bytes de temperatura */
        aux = read(fdi2c, dato_rx, 2);
    
        if(aux<=0)
		  {
            printf("Error al leer del dispositivo\n");
            exit(ERROR);
        }

        temp_aux = (float)((dato_rx[0]<<3)+(dato_rx[1]>>5));
		  temp_aux = temp_aux*0.125; 

    if (semop(semid, &sb, 1) == -1) 
  {
    perror("semop");
    exit(1);
  }
  
		  for(k=0;k<4;k++)	*(temp+k) = *(temp+k+1);
		  *(temp+4) = temp_aux;

  sb.sem_op = 1; /* Suelta el semáforo */
  if (semop(semid, &sb, 1) == -1) 
  {
    perror("semop");
    exit(1);
  }
       
		  printf("proceso de lectura: temperatura = %f\n", temp_aux);

        
	 }


  if (semctl(semid, 0, IPC_RMID, arg) == -1) 
  {
    perror("semctl");
    exit(1);
  }
  
    if (shmdt(temp) == -1) 
		{
			perror("shmdt");
			exit(ERROR);
		}
		
        close(fdi2c);
        printf("Se cerro el dispositivo correctamete\n");
    
  exit (0);
	
}

/* ************************************************************************************************************************************** */
  do{
    j=aceptar_pedidos(sockfd, i);
    if(j==i)
    {
    pid = fork();
    if (pid == -1)
    {
      perror("fork");
      exit(1);
    }
    else if (!pid)						// Si es el hijo
      child(i);
    }
    else	i = j;
    i++;
  }while(1);
      
  return(0);
}

/* ******************************************************************************************************************************************* */
/*  Proceso hijo para atender clientes: manda mensajes cada 1 segundos por el pueto PORT+i = 10000+i */

void child(int i)					
{
  int x=0;
  int sockfd, newsock;  /*File Descriptor para sockets*/
  struct sockaddr_in my_addr;	/* contendrá la dirección IP y el número de puerto local */
  unsigned int sin_size = sizeof(struct sockaddr_in);
  float *data, temp;
  
  printf("crando socket en %d\n",(PORT+i));
//*Crea un socket y verifica si hubo algún error*/
	if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) 
	{
	fprintf(stderr, "Error en función socket. Código de error %s\n", strerror(sockfd));
	exit(ERROR);
	}
	
/* Asignamos valores a la estructura my_addr */

	my_addr.sin_family = AF_INET;		/*familia de sockets INET para UNIX*/
	my_addr.sin_port = htons(PORT+i);	/*convierte el entero formato PC a entero formato network*/
	my_addr.sin_addr.s_addr = INADDR_ANY;	/* automaticamente usa la IP local */
	bzero(&(my_addr.sin_zero), 8);		/* rellena con ceros el resto de la estructura */
printf("bindeando socket en %d\n",(PORT+i));
/* Con la estructura sockaddr_in completa, se declara en el Sistema que este proceso escuchará pedidos por la IP y el port definidos*/
	if ( (bind (sockfd, (struct sockaddr *) &my_addr, sizeof(struct sockaddr))) == -1)
	{
		perror("Error en función bind. Código de error %s\n");
		exit(ERROR);
	}
printf("escuchando socket en %d\n",(PORT+i));
/* Habilitamos el socket para recibir conexiones, con una cola de conexiones en espera que tendrá como máximo el tamaño especificado en BACKLOG*/
	if (listen (sockfd, BACKLOG) == -1)
	{
		perror("Error en función listen. Código de error %s\n");
		exit(ERROR);
        }
printf("aceptando socket en %d\n",(PORT+i));
/*Se espera por conexiones ,*/
	if ((newsock = accept(sockfd, (struct sockaddr *)&my_addr, &sin_size)) == -1)
	{
		fprintf(stderr, "Error en función accept. Código de error %s\n", strerror(newsock));
		exit(ERROR);
	}

	data = shmat(shmid, (void *)0, 0);  // atacho shared memory
	if (data == (float *)(-1)) 
  {
    perror("shmat");
    exit(1);
  }
	
printf("escribiendo socket en %d\n",(PORT+i));
	while(1)
	{

	if (semop(semid, &sb, 1) == -1) 
  {
    perror("semop");
    exit(1);
  }
  
    temp = *(data+1);

  
    sb.sem_op = 1; /* Suelta el semáforo */
  if (semop(semid, &sb, 1) == -1) 
  {
    perror("semop");
    exit(1);
  }
  
	printf("escribiendo en %d, temperatura = %f\n", (PORT+i), temp);

	  if (send (newsock, &temp, sizeof (temp), MSG_DONTWAIT) == -1)
	  {
		      if((errno == EAGAIN) || (errno == EWOULDBLOCK))
		      {
					x++;
					sleep(1);
		      }
		    else
		    {
			printf("Conexion cerrada en puerto %d\n",(PORT+i));
			close(newsock);
			close(sockfd);
			if (shmdt(data) == -1) 
				{
					perror("shmdt");
					exit(1);
				}
			exit (ERROR);
		    }
	  }
	  else
	  {
		 x = 0;
	    sleep(1);
	  }
	}
			 if (shmdt(data) == -1) 
				{
					perror("shmdt");
					exit(1);
				}
	close(newsock);
	close(sockfd);
	  
  exit(0);
}

/* ******************************************************************************************************************************************* */
/*  Proceso padre. Espera por nuevos pedidos de conexion. cuando lo tiene. */

int aceptar_pedidos(int sockfd, int i)
{
  int puerto, newsock; 	/* Por este socket duplicado del inicial se transaccionará*/
  struct sockaddr_in their_addr;  /* Contendra la direccion IP y número de puerto del cliente */
  unsigned int sin_size = sizeof(struct sockaddr_in);

/*Se espera por conexiones ,*/
	if ((newsock = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size)) == -1)
	{
		if(errno == EINTR)
		{
		  i--;
		}
	else
		{
		  fprintf(stderr, "Error en función accept. Código de error %s\n", strerror(newsock));
		  exit(ERROR);
		}
		
	}
	else
	{
	printf  ("server:  conexión desde:  %s\n", inet_ntoa(their_addr.sin_addr));
	/* mando el pueto por el que debe escuchar el cliente */
		puerto = (PORT+i);
		printf("puerto asignado: %d\n", puerto);
		if (write (newsock, &puerto, sizeof (puerto)) == -1)
		    {
			perror("Error escribiendo mensaje en socket");
			exit (ERROR);
		    }
	}

  return(i);

}

/* ******************************************************************************************************************************************* */
/* Manejo de señales */

void mi_sigchld(int c, siginfo_t * a, void * b)		// handler de señal sigchld.
{
  int status;
  
waitpid(-1,&status,WNOHANG|WUNTRACED);

  return;
}
