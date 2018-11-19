#define MENOR 0
#define CANT_DISP 1
#define RESERVA__MEM 4
#define ENTRADA 115
#define DEMORA_500mS 500
#define MAX_PAGINAS 5

/*Zona de registros mapeados a memoria*/

#define CONTMOD_ADD	0x44e10000		//Control Module Registers
#define CONTMOD_LEN	0x2000
#define CMPER_ADD	0x44E00000		//Clock Module Peripheral Registers
#define CMPER_LEN	0x3FFF
#define CMPER_I2C2 0x44
#define I2C_REG 0x4819C000			//I2C2 Registers
#define I2C_REG_LEN 0xFFF



#include <linux/init.h>
#include <linux/module.h>
#include <linux/kdev_t.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/slab.h>
#include <asm/uaccess.h>
#include <linux/uaccess.h>
#include <asm/io.h>
#include <linux/ioport.h>
#include <linux/delay.h>
#include <linux/interrupt.h>
#include <linux/gpio.h>
#include <linux/wait.h>
#include <linux/sched.h>
#include <linux/semaphore.h>
#include <linux/spinlock.h>
#include <linux/list.h>
#include <linux/device.h>
#include <linux/of.h>
#include <linux/of_irq.h>
#include <linux/of_platform.h>
#include <linux/of_address.h>



/* File operations*/
ssize_t i2c_read (struct file * archivo, char __user * data_user, size_t cantidad, loff_t * poffset);
ssize_t i2c_write (struct file * archivo, const char __user * data_user, size_t cantidad, loff_t * poffset);
int i2c_close (struct inode * pinodo , struct file * archivo);
int i2c_open (struct inode * pinodo , struct file * archivo);
static int i2c_probe(struct platform_device *pdev);
static int i2c_remove(struct platform_device *pdev);



/*Handler de interrupción*/
irqreturn_t i2c_int_handler (int irq, void *dev_id, struct pt_regs *regs);


/* Estructura propia para el manejo del driver*/
struct i2c_data_t {
	void * pcontmod;
	void * pi2creg;
	void * pcm_per;
	char * prx_buff;
	unsigned int rx_buff_pos;
	unsigned int rx_buff_size;
	char * ptx_buff;
	unsigned int tx_buff_size;
	unsigned int tx_buff_pos;
};
