
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
#define BACKLOG 2		/* Tamaño de la cola de conexiones recibidas */
#define PEDIDO_DATO 0xa5a5a5a5


/* ****************************************************************************************************************************** */

void mi_sigchld(int, siginfo_t *, void *);
void leer_temp(void);
void child(int, int);
int aceptar_pedidos(int, int);		//este es la rutina del padre, aceptar pedidos y a los hijo le manda el socket conectado.

int fdi2c;
char dato_rx[2];
char pointer=0;
float temp, temp_aux;

key_t keyshm, keysem;
int shmid, semid, cant_conex = 0;
struct sembuf sb = {0, -1, SEM_UNDO}; 
pid_t pid_read;

union semun {
    int	val;                     /* valor para SETVAL */
    struct	semid_ds *buf;       /* buffer para IPC_STAT e IPC_SET */
    unsigned short int *array;  /* valor para GETALL y SETALL */
    struct seminfo *__buf;      /* buffer para IPC_INFO */
    }arg;
    
    struct paquete {
	  float temperatura;
	  time_t tiempo;
  }	* dato;;

int main ()
{
  pid_t pid;
  struct sigaction ctrl_nuevo;
  int sockfd, sock_child;			 /* File Descriptor del socket por el que el servidor "escuchará" conexiones*/
  struct sockaddr_in my_addr;	/* contendrá la dirección IP y el número de puerto local */

  /*int fdi2c;
  char dato_rx[2];
  char pointer=0;
  float temp_aux;*/
    
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



/* ************************************************************************** */
/* Shared memory: */

  if ((keyshm = ftok("server.c", 'R')) == -1) 
  {
     perror("ftok");
     exit(ERROR);
  }

  if ((shmid = shmget(keyshm, sizeof(struct paquete), 0666 | IPC_CREAT)) == -1) 
  {
      perror("shmget");
      exit(ERROR);
   }
   
           dato = shmat(shmid, (void *)0, 0);	 //tomo la shared memory
		    if (dato == (struct paquete *)(-1)) 
				{
				perror("shmat");
				exit(1);
				}

/* ******************************************************************************************** */
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


pid_read = fork();
if (pid_read == -1)
{
  perror("fork");
  exit(ERROR);
}

if (!pid_read)
	leer_temp();

/* ***********************************************************************************
 * Preparo para recibir conexiones.
 * ******************************************************************************** */
/*Crea un socket y verifica si hubo algun error*/
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
		perror("Error en funciÃ³n bind. CÃ³digo de error %s\n");
		exit(ERROR);
	}

/* Habilitamos el socket para recibir conexiones, con una cola de conexiones en espera que tendría como máximo el tamaño especificado en BACKLOG*/
	if (listen (sockfd, BACKLOG) == -1)
	{
		perror("Error en funciÃ³n listen. CÃ³digo de error %s\n");
		exit(ERROR);
	}
        
/* *********************************************************** */
/*Bucle principal */
  do{
	  if(cant_conex >= 1000)
	  {
		  printf("Máximo de conexiones alcanzado\n");
		  sleep(1);
		  sock_child = 0;
	  }
	  else
		  sock_child=aceptar_pedidos(sockfd, cant_conex);
	  
    if(sock_child!=0)
    {
        cant_conex++;
        pid = fork();
        if (pid == -1)
        {
            perror("fork");
            exit(1);
        }
        else if (!pid)						// Si es el hijo
			child(sock_child, cant_conex);
    }

  }while(1);
      
  return(0);
}



/* ****************************************************************************************************************************** */
/* Proceso para leer la temperatura: */
void leer_temp(void)
{
	  int aux;
	  pid_t pid_padre;
	  time_t tiempo_aux;
	  
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
            exit(ERROR);
        }
        printf("Exito al escribir el pointer register\n"); 
        
	pid_padre = getppid();
    while(getppid() == pid_padre)
	 {
        usleep(500000);        
        /* Intento leer 2 bytes de temperatura */
        aux = read(fdi2c, dato_rx, 2);
    
        if(aux<=0)
		  {
            printf("Error al leer del dispositivo\n");
            exit(ERROR);
        }

        temp_aux = (float)((dato_rx[0]<<3)+(dato_rx[1]>>5));
        temp_aux = temp_aux*0.125; 
		time(&tiempo_aux);

        if (semop(semid, &sb, 1) == -1) 
        {
            perror("semop");
            exit(1);
        }
    

        dato->temperatura = temp_aux;
        dato->tiempo = tiempo_aux;

        sb.sem_op = 1; /* Suelta el semáforo */
        if (semop(semid, &sb, 1) == -1) 
        {
            perror("semop");
            exit(1);
        }
       
		  /*printf("proceso de lectura: temperatura = %f\n", temp_aux);*/
          
	 }

	printf("%d \n", getppid());
	if (semctl(semid, 0, IPC_RMID, arg) == -1) 
	{
		perror("semctl");
		exit(1);
	}
  
    if (shmdt(dato) == -1) 
	{
		perror("shmdt");
		exit(ERROR);
	}
		
        close(fdi2c);
        printf("Se cerro el dispositivo correctamete\n");
    
  exit (0);
	
}

/* ****************************************************************************************************************************** */
/*  Proceso hijo para atender clientes */

void child(int sock, int proceso)					
{
  int x=0;
  struct paquete * dato, dato_aux;
  struct envio{
	  float temp;
	  int hora;
	  int min;
	  int seg;
  } _forsend;
  int numbytes, mensaje = 0;
  struct tm * stamp_s;
  pid_t pid_papa;

	dato = shmat(shmid, (void *)0, 0);  // atacho shared memory
	if (dato == (struct paquete *)(-1)) 
    {
        perror("shmat");
        exit(1);
    }
pid_papa = getppid();
while(pid_papa == getppid())
{
        /* espero el pedido del dato*/
        while(mensaje != PEDIDO_DATO)
        {
			if ((numbytes = recv (sock, &mensaje, sizeof(mensaje), MSG_DONTWAIT)) == -1)
            {
                if((errno == EAGAIN) || (errno == EWOULDBLOCK))
                {
                    x++;
                    if(x == 30)
                    {
                        fprintf(stderr, "No se recibió nada por 60 segundos, ERROR DE CONEXIÓN. Proceso %d\n", proceso);
                        if (shmdt(dato) == -1) 
                        {
                            perror("shmdt");
                            exit(ERROR);
                        }
                        close (sock);
                        exit(ERROR);
                    }
                    sleep(1);
                }
                else
                {
                    perror("Error de lectura en el socket");
                    if (shmdt(dato) == -1) 
                        {
                            perror("shmdt");
                            exit(ERROR);
                        }
                    close(sock);
                    exit(ERROR);
                }
            }
            else
                x =  0;
        }
        mensaje = 0;
        
	      
	/* entro a la shared para buscar el dato*/
	if (semop(semid, &sb, 1) == -1) 
    {
        perror("semop 1");
        exit(1);
    }
  
    dato_aux = *dato;

  
    sb.sem_op = 1;      /* Suelta el semáforo */
    if (semop(semid, &sb, 1) == -1) 
    {
        perror("semop 2");
        exit(1);
    }
  
/* envio el dato */
printf("Proceso %d enviando...\n", proceso);
stamp_s = gmtime(&dato_aux.tiempo);
_forsend.hora = stamp_s->tm_hour;
_forsend.min = stamp_s->tm_min;
_forsend.seg = stamp_s->tm_sec;
_forsend.temp = dato_aux.temperatura;
printf("%f\n",_forsend.temp);
printf("[%d : %d : %d]\n", _forsend.hora, _forsend.min, _forsend.seg); 

do{
	  if (send (sock, &_forsend, sizeof(_forsend), MSG_DONTWAIT) == -1)
	  {
            if((errno == EAGAIN) || (errno == EWOULDBLOCK))
		    {
                x++;
                if(x == 60)
                {
                    printf("No se pudo enviar el dato, proceso: %d\n", proceso);
                    close(sock);
                    if (shmdt(dato) == -1) 
                    {
                        perror("shmdt");
                        exit(1);
                    }
                    exit (ERROR);
                }
                sleep(1);
            }
		    else
		    {
			printf("Conexión cerrada en el proceso: %d\n", proceso);
			close(sock);
			if (shmdt(dato) == -1) 
				{
					perror("shmdt");
					exit(1);
				}
			exit (ERROR);
		    }
	  }
	  else
          x = 0;
      
}while(x != 0);
//printf("%d\n",(int)envio.tiempo);
//send (sock, &(dato_aux.tiempo), sizeof (time_t), MSG_DONTWAIT);
      
}
/*termino el while 1*/
    if (shmdt(dato) == -1) 
    {
        perror("shmdt");
        exit(1);
    }
    printf("cierro Socket hijo\n");
	close(sock);
	  
  exit(0);
}

/* ****************************************************************************************************************************** */
/*  Proceso padre. Espera por nuevos pedidos de conexion. cuando lo tiene. */

int aceptar_pedidos(int sockfd, int cant_conex)
{
  int newsock; 	/* Por este socket duplicado del inicial se transaccionará*/
  struct sockaddr_in their_addr;  /* Contendra la direccion IP y nÃºmero de puerto del cliente */
  unsigned int sin_size = sizeof(struct sockaddr_in);

/*Se espera por conexiones ,*/
	if ((newsock = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size)) == -1)
	{
		if(errno == EINTR)
		{
		  cant_conex--;
		  newsock = 0;
		}
	else
		{
		  fprintf(stderr, "Error en función accept. Código de error %s\n", strerror(newsock));
		  close(sockfd);
		  close(newsock);
		  exit(ERROR);
		}
		
	}
	else
	{
	printf  ("server:  conexión desde:  %s\n", inet_ntoa(their_addr.sin_addr));
	}

  return(newsock);

}

/* ****************************************************************************************************************************** */
/* Manejo de señales */

void mi_sigchld(int c, siginfo_t * a, void * b)		// handler de señal sigchld.
{
  int status;
  pid_t pid_dead;
  
pid_dead = waitpid(-1,&status,WNOHANG|WUNTRACED);
if (pid_dead == pid_read)
{
	printf("Relanzo hijo para leer temperatura\n");
		pid_read = fork();
		if (pid_read == -1)
		{
			perror("fork");
            exit(1);
		}
		else if (!pid_read)
			leer_temp();
}
else
	cant_conex--;

  return;
}
