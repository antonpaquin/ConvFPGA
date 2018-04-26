/******************************************************************************
*
* Copyright (C) 2010 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/*****************************************************************************/
/**
* @file xbram_example.c
*
* This file contains a self test example using the BRAM driver (XBram).
*
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date	 Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a sa   05/11/10 Initial release.
* 3.01a sa   13/01/12 Changed XBram_SelfTest(InstancePtr) to
* 			 XBram_SelfTest(InstancePtr,0) as per
*			 new API (CR 639274)
* 4.1   ms   01/23/17 Modified xil_printf statement in main function to
*                     ensure that "Successfully ran" and "Failed" strings are
*                     available in all examples. This is a fix for CR-965028.
*</pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xparameters.h"
#include "xbram.h"
#include <stdio.h>

/************************** Constant Definitions *****************************/

#define FILTER_SIZE 3
#define IMG_SIZE 5

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define BRAM_DEVICE_ID		XPAR_BRAM_0_DEVICE_ID


/************************** Function Prototypes ******************************/

// int BramExample(u16 DeviceId);
// static void InitializeECC(XBram_Config *ConfigPtr, u32 EffectiveAddr);


/************************** Variable Definitions *****************************/

/*
 * The following are declared globally so they are zeroed and so they are
 * easily accessible from a debugger
 */
XBram Bram;					/* The Instance of the BRAM Driver */
XBram_Config *ConfigPtr;	/* Pointer to config for the BRAM Driver */


/****************************************************************************/
/**
*
* This function is the main function of the BRAM example.
*
* @param	None.
*
* @return
*		- XST_SUCCESS to indicate success.
*		- XST_FAILURE to indicate failure.
*
* @note		None.
*
*****************************************************************************/
int main(void)
{
	xil_printf("Starting BRAM test...\r\n");

	int Status;

	xil_printf("initializing BRAM...");
	/*
	 * Lookup configuration data in the device configuration table.
	 * Use this configuration info down below when initializing this
	 * driver.
	 */
	ConfigPtr = XBram_LookupConfig(BRAM_DEVICE_ID);
	if (ConfigPtr == (XBram_Config *) NULL) {
		xil_printf("Could not find config for bram");
		return XST_FAILURE;
	}

	/*
	 * Initialize the BRAM driver. If an error occurs then exit
	 */
	Status = XBram_CfgInitialize(&Bram, ConfigPtr, ConfigPtr->CtrlBaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("Could not initialize config for bram");
		return XST_FAILURE;
	}
	xil_printf("done\r\n");

	xil_printf("Writing image and filter data to BRAM...");
	/*
	 * Initialize filter and image with dummy data
	 * Write dummy data to bram
	 */
	u32 filter[FILTER_SIZE][FILTER_SIZE];
	for (u32 i = 0; i < FILTER_SIZE; ++i)
	{
		for (u32 j = 0; j < FILTER_SIZE; ++j)
		{
			filter[i][j] = FILTER_SIZE*i+j;
			XBram_WriteReg(ConfigPtr->CtrlBaseAddress, 4*(FILTER_SIZE*i + j),FILTER_SIZE*i+j);
		}
	}

	u32 offset_from_filter = FILTER_SIZE*FILTER_SIZE*4;	/* to write to mem loc after the last filter weight */
	u32 image[IMG_SIZE][IMG_SIZE];
	for (int i = 0; i < IMG_SIZE; ++i)
	{
		for (int j = 0; j < IMG_SIZE; ++j)
		{
			image[i][j] = IMG_SIZE*i+j;
			XBram_WriteReg(ConfigPtr->CtrlBaseAddress, offset_from_filter + 4*(IMG_SIZE*i + j), IMG_SIZE*i+j);
		}
	}
	xil_printf("done\r\n");

	xil_printf("Reading from BRAM...\r\n");
	/*
	 * Read from BRAM and check if same data
	 */
	xil_printf("--------- Filter ---------\r\n");
	for (u32 i = 0; i < FILTER_SIZE; ++i)
	{
		for (u32 j = 0; j < FILTER_SIZE; ++j)
		{
			xil_printf("%d ", XBram_ReadReg(ConfigPtr->CtrlBaseAddress, 4*(FILTER_SIZE*i + j)));
		}
		xil_printf("\r\n");
	}

	xil_printf("--------- Image ---------\r\n");
	for (u32 i = 0; i < IMG_SIZE; ++i)
	{
		for (u32 j = 0; j < IMG_SIZE; ++j)
		{
			xil_printf("%d ", XBram_ReadReg(ConfigPtr->CtrlBaseAddress, offset_from_filter + 4*(IMG_SIZE*i + j)));
		}
		xil_printf("\r\n");
	}


	xil_printf("Successfully ran BRAM test\r\n");
	return XST_SUCCESS;
}
