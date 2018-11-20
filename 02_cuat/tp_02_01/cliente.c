/* ************************************************************************************************************************
Es un solo cliente y hay que ingrasarle al ip a la cual me quiero conectar.
 *************************************************************************************************************************** */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <arpa/inet.h>
#include <netdb.h>

#include <time.h>
#include <sys/time.h>

#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>


#define BACKLOG 10	/* Tamaño de la cola de conexiones recibidas */
#define ERROR		-1

int main(int argc, char * argv[])
{
	int sockfd;  /*File Descriptor para socket*/
	int numbytes;/*Contendrá el número de bytes recibidos por read () */
	int x=0;     /*Contabilizo errores de recepci�n */
	struct data_temp{
        float temp;
        int fecha:
    } data;
	struct hostent *he;	/* Se utiliza para convertir el nombre del host a su dirección IP */
	struct sockaddr_in their_addr;  /* dirección del server donde se conectará */



/* Tratamiento de la línea de comandos. */
	if (argc < 3)
	{
		fprintf(stderr,"uso: %s hostname port\n",argv [0]);
		exit(1);
    }

	/* Convertimos el nombre del host a su dirección IP */
	if ((he = gethostbyname ((const char *) argv[1])) == NULL)
	{
		herror("Error en gethostbyname");
		exit(1);
	}
 
/* Creamos el socket */
	if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
	{
		perror("Error en creación de socket");
		exit(1);
	}

/* Establecemos their_addr con la direccion del server */
	their_addr.sin_family = AF_INET;
	their_addr.sin_port = htons(atoi(argv[2]));
	their_addr.sin_addr = *((struct in_addr *)he->h_addr);
	bzero(&(their_addr.sin_zero), 8);

/* Intentamos conectarnos con el servidor */
	if (connect(sockfd, (struct sockaddr *)&their_addr, sizeof(struct sockaddr)) == -1)
	{
		perror("Error tratando de conectar al server");
		exit(1);
	}

/* Exito al conectar */
	printf("Exito al conectar a Servidor\n");

	while(1)
	{
/* Recibimos los datos del servidor */
	  if ((numbytes = recv (sockfd, &data, sizeof(data), MSG_DONTWAIT)) == -1)
	  {
	    if((errno == EAGAIN) || (errno == EWOULDBLOCK))
	    {
	      x++;
	      if(x == 10)
	      {
            perror("No se recive nada, ERROR DE CONEXIÓN");
            close(sockfd);
            exit(1);
	      }
	      sleep(1);
	    }
	    else
	    {
		  perror("error de lectura en el socket");
		  exit(1);
	    }
	  }
	  else
	  {
	    if(numbytes == 0)
	    {
	      perror("No se recive nada, ERROR DE CONEXIÓN");
          close(sockfd);
	      exit(1);
	    }
	  
	  printf("recivido: %f | %d\n", data.temp, data.fecha);
	  sleep(1);
	  x = 0;
	  }
	}
	printf("Se termina la conexi�n\n");
    close(sockfd);
    exit (0);
}
