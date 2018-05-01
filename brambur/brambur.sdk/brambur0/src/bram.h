/*
 * bram.h
 *
 *  Created on: Apr 29, 2018
 *      Author: karanraj
 */

#ifndef SRC_BRAM_H_
#define SRC_BRAM_H_


/***************************** Include Files *********************************/

#include "xparameters.h"

/************************** Constant Definitions *****************************/

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file.
 */
#define NUM_BRAM				2
#define BRAM_0_DEVICE_ID		XPAR_BRAM_0_DEVICE_ID
#define BRAM_1_DEVICE_ID		XPAR_BRAM_1_DEVICE_ID


/************************** Function Prototypes ******************************/

int bram_init(void);
int bram_selftest(void);
int bram_write_data(u32 *data, u32 num_words);
int bram_write_data_to_addr(u32 addr, u32 *data, u32 num_words);


#endif /* SRC_BRAM_H_ */
