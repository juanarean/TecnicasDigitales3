
/* Include del driver */
#include "i2c.h"


/*Licencia "Dual BSD/GPL"*/
MODULE_LICENSE("Dual BSD/GPL");


/* Declaro las file operations*/
static struct file_operations i2c_ops = {
	.owner = THIS_MODULE,
	.read = i2c_read,
	.write = i2c_write,
	.open = i2c_open,
	.release = i2c_close,
};

static const struct of_device_id i2c_of_match[] = {
	{ .compatible = "td3" },
	{},
};
MODULE_DEVICE_TABLE(of, i2c_of_match);

static struct platform_driver i2c_driver = {
	.probe          = i2c_probe,
	.remove         = i2c_remove,
	.driver		= {
		.name	= "td3_i2c",
		.of_match_table = of_match_ptr(i2c_of_match),
	},
};




static int i2c_remove(struct platform_device *pdev)
{

	printk(KERN_ALERT "td3_i2c: entre a la remove\n");
	return 0;
}


/* Declaración de variables globales*/
static dev_t	dispo;
static struct cdev * i2c_cdev;
static struct class * pdev_class;
static struct device * pdev_dev;
static struct i2c_data_t i2c_data=
{
	.rx_buff_pos=0,
};
static int i2c_irq=0;
static struct resource mem_res;
static int cond_wake_up_rx=0;
static int cond_wake_up_tx=0;
/*Declaracion de los spinlocks*/
//static DEFINE_SPINLOCK(td3_i2c_rx_lock);
/*Variables atómicas*/
//static atomic_t read_dormido = ATOMIC_INIT(0);
/*Wait queues*/
static DECLARE_WAIT_QUEUE_HEAD (td3_i2c_rx_q);
static DECLARE_WAIT_QUEUE_HEAD (td3_i2c_tx_q);
/*Semaforos*/
static struct semaphore i2c_sem = __SEMAPHORE_INITIALIZER(i2c_sem, 1); 


static int i2c_probe(struct platform_device *pdev)
{
	int aux, contador = 0;

	printk(KERN_ALERT "td3_i2c: ingreso a la funcion probe\n");
	/*Obtengo un virq para la interrupción de mi dispositivo*/
	i2c_irq = platform_get_irq(pdev, 0);
	if(i2c_irq==0)
	{
		platform_driver_unregister(&i2c_driver);
		device_destroy(pdev_class, dispo);
		class_destroy(pdev_class);
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: Error al intentar obtener el VIRQ\n");
		return EBUSY;
	}
 	printk(KERN_ALERT "td3_i2c: VIRQ obtenido para td3_i2c = %d\n", i2c_irq);
	/*Implanto el handler de IRQ*/
  	aux =request_irq(i2c_irq, (irq_handler_t) i2c_int_handler,  IRQF_TRIGGER_RISING  , pdev->name, NULL);
	if(aux!=0)
	{
		platform_driver_unregister(&i2c_driver);
		device_destroy(pdev_class, dispo);
		class_destroy(pdev_class);
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: Error al intentar implantar handler de IRQ\n");
		return EBUSY;
	}
 	printk(KERN_ALERT "td3_i2c: handler de IRQ implantado OK\n");
	/*Leo la zona de memoria asociada al td3_i2c del device tree*/
	aux = of_address_to_resource((pdev->dev).of_node, 0, &mem_res);
	if (aux)
	{
		free_irq(i2c_irq, NULL);
		platform_driver_unregister(&i2c_driver);
		device_destroy(pdev_class, dispo);
		class_destroy(pdev_class);
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: Error al obtener zona de memoria del device tree\n");
		return EBUSY;
	}
	/*Registro la zona de memoria como IO asociada al dispositivo*/
	if  (!request_mem_region(mem_res.start, resource_size(&mem_res), "/ocp/td3_i2c"))
	{
		free_irq(i2c_irq, NULL);
		platform_driver_unregister(&i2c_driver);
		device_destroy(pdev_class, dispo);
		class_destroy(pdev_class);
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: Error al registrar zona de memoria\n");
		return EBUSY;
 	}
	/*Pido memoria física en la zona del pad de pines*/
	i2c_data.pcontmod = ioremap (CONTMOD_ADD, CONTMOD_LEN);
	if (i2c_data.pcontmod == NULL)
	{
		free_irq(i2c_irq, NULL);
		platform_driver_unregister(&i2c_driver);
		device_destroy(pdev_class, dispo);
		class_destroy(pdev_class);
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: no puedo acceder al control module\n");
		return -EBUSY;
	}
	/*Pido memoria física en la zona de los registros, obteniedo la zona del device tree*/
	i2c_data.pi2creg = of_iomap ((pdev->dev).of_node, 0);
	if (i2c_data.pi2creg == NULL)
	{
		iounmap(i2c_data.pcontmod);
		free_irq(i2c_irq, NULL);
		platform_driver_unregister(&i2c_driver);
		device_destroy(pdev_class, dispo);
		class_destroy(pdev_class);
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: no puedo acceder a los registros de I2C2\n");
		return -EBUSY;
	}

	/*Pido memoria física en la zona de los registros de la CMPER*/
	i2c_data.pcm_per = ioremap (CMPER_ADD, CMPER_LEN);
	if (i2c_data.pcm_per == NULL)
	{
		iounmap(i2c_data.pcontmod);
		iounmap(i2c_data.pi2creg);
		free_irq(i2c_irq, NULL);
		platform_driver_unregister(&i2c_driver);
		device_destroy(pdev_class, dispo);
		class_destroy(pdev_class);
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: no puedo acceder al clock managment per\n");
		return -EBUSY;
	}
	/*Configuro el clock del i2c2*/
	iowrite32 (2, i2c_data.pcm_per + CMPER_I2C2);
	aux = ioread32 (i2c_data.pcm_per + CMPER_I2C2);
	while (aux!=2)
	{
		msleep(1);
		aux = ioread32 (i2c_data.pcm_per + CMPER_I2C2);
		if (contador > 4)
		{
			printk(KERN_ALERT "td3_i2c: No puedo configurar el clock del I2C2\n");
			return -EBUSY;
		}
		contador++;
	}
	/*Todo salió bien por suerte*/
	return 0;
}


/*Función de inicialización del módulo (se ejecuta cuando se llama a insmod)*/
int i2c_init (void)
{
	int aux2;
	//static struct platform_device * pdev; NOOOO, ESTA ESTRUCTURA LA MANDA EL KERNEL CUANDO LLAMA A MI PROBE!!!

  	/*Instancio el dispositivo*/
	/*Primero pido el numero mayor de forma dinámica*/
	i2c_cdev = cdev_alloc();
	if (  (alloc_chrdev_region(&dispo, MENOR, CANT_DISP, "td3_i2c")) < 0)
	{
		printk(KERN_ALERT "td3_i2c: Error no es posible asignar numero mayor\n");
		return -EBUSY;
	}
	printk(KERN_ALERT "td3_i2c: Numero mayor asignado: %d\n", MAJOR(dispo));

	/*Registro el dispositivo en el sistema*/
	i2c_cdev->ops = &i2c_ops;
	i2c_cdev->owner = THIS_MODULE;
	i2c_cdev->dev = dispo;
	if ((cdev_add (i2c_cdev, dispo, CANT_DISP)) < 0)
	{
		unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: No es posible registrar el dispositivo\n");
		return -EBUSY;
	}

	/*Creo la clase*/
	pdev_class = class_create(THIS_MODULE, "td3dev");
	if (IS_ERR(pdev_class))
	{
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		return PTR_ERR(pdev_class);
	}

	/*Creo el device dentro de la clase*/
	pdev_dev = device_create(pdev_class, NULL, dispo, NULL,   "td3_i2c");
	if (IS_ERR(pdev_dev))
	{
		class_destroy(pdev_class);
		cdev_del (i2c_cdev);
		unregister_chrdev_region(dispo, CANT_DISP);
		return PTR_ERR(pdev_dev);
	}


	 /*Registro el driver, una vez realizado esto, EL KERNEL LLAMA a la función probe que yo escribi y declare en i2c_driver*/
	 aux2 =	platform_driver_register(&i2c_driver);
	 if (aux2 != 0)
	 {
		device_destroy(pdev_class, dispo);
	 	class_destroy(pdev_class);
	 	cdev_del (i2c_cdev);
	 	unregister_chrdev_region(dispo, CANT_DISP);
		printk(KERN_ALERT "td3_i2c: No paso el platform_driver_register\n");
		return -EBUSY;
	 }

	/*Todo salió bien, :)*/
	return 0;
}


/* Función exit (se ejecuta cuando se llama a rmmod)*/
static void i2c_exit (void)
{
  	/*Retiro el dispositivo del sistema*/
	iounmap(i2c_data.pcontmod);
	iounmap(i2c_data.pi2creg);
	iounmap(i2c_data.pcm_per);
	release_mem_region(mem_res.start, resource_size(&mem_res));
	free_irq(i2c_irq, NULL);
	platform_driver_unregister(&i2c_driver);
	device_destroy(pdev_class, dispo);
	class_destroy(pdev_class);
	cdev_del (i2c_cdev);
	unregister_chrdev_region(dispo, CANT_DISP);
	printk(KERN_ALERT "td3_i2c: Modulo removido\n");
}


/* Función open */
int i2c_open (struct inode * pinodo , struct file * archivo)
{
	/*seteo un semaforo, si otro proceso lo quiere abrir devuelve queda en espera, en WAIT_INTERRUMPIBLE*/
	if(down_interruptible(&i2c_sem))
	{
		printk(KERN_ALERT "td3_i2c: problema con el semaforo de OPEN");
		return -1;
	}
	
	/*configuro el pad para los dos pines de la i2c*/
	iowrite32 (0x2b ,i2c_data.pcontmod + 0x978);
	iowrite32 (0x2b ,i2c_data.pcontmod + 0x97c);
	
	/*Inicializo registros del i2c2 (prescalers, etc)
	 * Mas detalle en la hoja de datos del sitara aam335
	 * La direccion del slave es siempre 0x22 que es la que usa el ftdi*/
	iowrite32 (0, i2c_data.pi2creg + 0xA4); // Modulo I2C Deshabilitado
	iowrite32 (3, i2c_data.pi2creg + 0xB0); // Escribo el registro de Prescaler del I2C. El 3 es porque tengo que dividir de 48MHz a 12MHz, y el 48MHz se divide por el valor del Prescaler + 1.
	iowrite32 (5, i2c_data.pi2creg + 0xB4); // Este registro determinada el flanco de bajada del SCL
	iowrite32 (7, i2c_data.pi2creg + 0xB8); // Este registro determinada el flanco de subida del SCL
	iowrite32 (0x36, i2c_data.pi2creg + 0xA8); // Cargo la direccion de 7 bits del I2C2
	iowrite32 (0, i2c_data.pi2creg + 0x10); // Cargo el System Configuration Register
	iowrite32 (0x48, i2c_data.pi2creg + 0xAC); // Cargo la direccion de 7 bits del esclavo LM75. 1001000   / Los cuatro MSB son 1001 fijos y los 3 LSB se sueldan en el sensor. Sueldo los 3 pines a masa. 
	iowrite32 (0x8000, i2c_data.pi2creg + 0xA4); // Habilito el modulo I2C (seteo bit 15 del I2C_CON)
	
	/*Pido la primera página de memoria*/
	if ((i2c_data.prx_buff = (char *) __get_free_page (GFP_KERNEL)) < 0)
	{
		printk(KERN_ALERT "td3_i2c: no se puede pedir memoria para el rxbuff\n");
		return -ENOMEM;
	}
	
	printk(KERN_ALERT "td3_i2c: open dispositivo\n");
	return 0;
}


/*Función para liberar recursos al cerrar el dispositivo*/
int i2c_close (struct inode * pinodo , struct file * archivo)
{
	free_page((unsigned long) i2c_data.prx_buff);
	up(&i2c_sem);
	printk(KERN_ALERT "td3_i2c: cerrando dispositivo\n");
	return 0;
}




/*Handler de la interrupción*/
irqreturn_t i2c_int_handler (int irq, void *dev_id, struct pt_regs *regs)
{
	int aux = 0;
	
	aux = ioread32 (i2c_data.pi2creg + 0x28);
	
	/* rx */
	if (aux & 8)
	{
		i2c_data.prx_buff [i2c_data.rx_buff_pos] = ioread32(i2c_data.pi2creg + 0x9c);
		aux = i2c_data.prx_buff [i2c_data.rx_buff_pos];
		printk(KERN_ALERT "td3_i2c: int rx -> leo = %x\n", aux);
		aux = ioread32 (i2c_data.pi2creg + 0xA4);
		printk (KERN_ALERT "td3_i2c: int rx -> valor aux = %x\n", aux);
		/* Me fijo si llegue al final de buffer*/
		if (i2c_data.rx_buff_size == i2c_data.rx_buff_pos + 1)
		{
			/*Desactivo la IRQ de RX*/
			iowrite32 (8, i2c_data.pi2creg + 0x30);
			aux = ioread32 (i2c_data.pi2creg + 0xa4);
			printk(KERN_ALERT "td3_i2c: int rx -> valor aux (saliendo)= %x\n", aux);
			/*despertando*/
			cond_wake_up_rx = 1;
			wake_up_interruptible(&td3_i2c_rx_q);
		}
		i2c_data.rx_buff_pos++;
		goto end_irq;
	}
	
	/* tx */
	if (aux & 0x10)
	{
		if ( (i2c_data.tx_buff_size == i2c_data.tx_buff_pos) )
		{
			/*desactivo irq de tx*/
			iowrite32 (0x10, i2c_data.pi2creg + 0x30);
			aux = ioread32 (i2c_data.pi2creg + 0xA4);
			printk(KERN_ALERT "td3_i2c: int tx -> valor aux = %x\n", aux);
			cond_wake_up_tx = 1;
			wake_up_interruptible(&td3_i2c_tx_q);
			goto end_irq;
		}
		iowrite32 ((int) i2c_data.ptx_buff[i2c_data.tx_buff_pos] , i2c_data.pi2creg + 0x9C);
		aux = ioread32 (i2c_data.pi2creg + 0xA4);
		printk(KERN_ALERT "td3_i2c: int tx -> valor aux = %x\n", aux);
		
		i2c_data.tx_buff_pos++;
		
	}
	end_irq:
	printk(KERN_ALERT "td3_i2c: interrupcion dispositivo\n");
	return IRQ_HANDLED;
}


/* Función para hacer el read*/
ssize_t i2c_read (struct file * archivo, char __user * data_user, size_t cantidad, loff_t * poffset)
{
	int aux;
	
	/*Verifico si el buffer que me envio el usuario está bien*/
	if(!(access_ok(VERIFY_WRITE, data_user, cantidad)))
	{
		printk(KERN_ALERT "td3_i2c: buffer recibido por el usuario invalido\n");
		return -ENOMEM;
	}
	
	/*Espero que el bus este libre*/
	while((ioread32 (i2c_data.pi2creg + 0x24) & 0x1000))
		msleep(1);
	
	/*seteo cuanto es lo que tengo que copiar*/
	i2c_data.rx_buff_size = cantidad;
	i2c_data.rx_buff_pos = 0;
	cond_wake_up_rx = 0;
	iowrite32 (cantidad, i2c_data.pi2creg + 0x98);
	iowrite32 (0x8400, i2c_data.pi2creg + 0xa4);
	printk(KERN_ALERT "td3_i2c: activo interrupcion");
	/*activo la irq de rx y mando start*/
	iowrite32 (8, i2c_data.pi2creg + 0x2c);
	aux = ioread32 (i2c_data.pi2creg + 0xa4);
	aux = aux | 1;
	iowrite32 ((int)aux, i2c_data.pi2creg + 0xa4);
	
	/*pongo a dormir hasta que temine la rx*/
	if((aux = wait_event_interruptible (td3_i2c_rx_q, cond_wake_up_rx > 0 )))
	{
		printk(KERN_ALERT "td3_i2c: Error en wait de rx %d", aux);
		return aux;
	}
	printk(KERN_ALERT "td3_i2c: mando stop");
	/* mando condicion de stop*/
	aux = ioread32 (i2c_data.pi2creg + 0xa4);
	aux = aux | 2;
	iowrite32 ((int)aux, i2c_data.pi2creg + 0xa4);
	
	/* copio a usuario*/
	if((aux = (__copy_to_user(data_user , i2c_data.prx_buff, cantidad))) < 0)
	{
		printk(KERN_ALERT "td3_i2c: Error en la copia del read\n");
		return -ENOMEM;
	}
	
	printk(KERN_ALERT "td3_i2c: read dispositivo\n");
	return cantidad;
}


/* Función para hacer el write*/
ssize_t i2c_write (struct file * archivo, const char __user * data_user, size_t cantidad, loff_t * poffset)
{
	int aux;

	printk(KERN_ALERT "td3_i2c: Entre al Write");
	/*Verifico si el buffer que me envio el usuario está bien*/
	if(!(access_ok(VERIFY_WRITE, data_user, cantidad)))
	{
		printk(KERN_ALERT "td3_i2c: buffer recibido por el usuario invalido\n");
		return -ENOMEM;
	}
	
	/* Pido memoria para el buffer*/
	if ( (i2c_data.ptx_buff = (char *)  kmalloc ( cantidad , GFP_KERNEL )) == NULL)
	{
		printk(KERN_ALERT "td3_i2c: no hay memoria disponible el buffer de tx\n");
		return -ENOMEM;
	}
	
	if ((aux = (__copy_from_user(i2c_data.ptx_buff, data_user, cantidad))) < 0)
	{
		printk(KERN_ALERT "td3_i2c: Error en la copia del write\n");
		return -ENOMEM;
	}
	printk(KERN_ALERT "td3_i2c: WRITE\n");	
	/* Espero que se libere el bus */
	while ((ioread32 (i2c_data.pi2creg + 0x24) & 0x1000))
		msleep(1);
	
	/* Seteo cuanto tengo que copiar */
	i2c_data.tx_buff_size = cantidad;
	i2c_data.tx_buff_pos = 0;
	cond_wake_up_tx = 0;
	iowrite32 (cantidad, i2c_data.pi2creg + 0x98);
	iowrite32 (0x8600, i2c_data.pi2creg + 0xA4);
	
	/*Activo IRQ de Tx y start */
	iowrite32 (0x10, i2c_data.pi2creg + 0x2C);
	aux = ioread32 (i2c_data.pi2creg + 0xA4);
	aux = aux | 1;
	iowrite32 ((int)aux, i2c_data.pi2creg + 0xA4);
	
	/* Pongo a dormir hasta que termine Tx */
	if((aux = wait_event_interruptible (td3_i2c_tx_q, cond_wake_up_tx > 0 )))
	{
		printk(KERN_ALERT "td3_i2c: Eror en wait de tx");
		return aux;
	}
	
	/* mando condicion de stop*/
	aux = ioread32 (i2c_data.pi2creg + 0xa4);
	aux = aux | 2;
	iowrite32 ((int)aux, i2c_data.pi2creg + 0xa4);
	
	printk(KERN_ALERT "td3_i2c: Dato transmitido\n");
	return cantidad;
}


/*Cargo las funciones de inicialización*/
module_init(i2c_init);
module_exit(i2c_exit);
