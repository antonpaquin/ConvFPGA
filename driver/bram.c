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

// config: 8k (2048 x 32) per bram ctrl (2 bram blocks per bram ctrl)
// stores only 32 bit data storage support through bram ctrl blocks

/**************************	*** Include Files *********************************/

#include "xparameters.h"
#include "xbram.h"			/* xilinx bram header */
#include "bram.h"			/* project bram header */
#include <stdio.h>
#include <stdlib.h>			/* malloc, free */

/************************** Variable Definitions *****************************/

/* bram controller identifiers */
u16 bram_ids[NUM_BRAM];

/* bram ctrl blocks */
XBram brams[NUM_BRAM];

/* bram id, write pointer for "address-less" writes */
u8 curr_bram_idx;
u32 curr_write_addr;


/****************************************************************************/
/**
*
* This function is for self test .
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
	xil_printf("========== main enter ==========\r\n");
	int status;
	status = bram_init();
	if (status != XST_SUCCESS)
	{
		xil_printf("bram init error\r\n");
		return XST_FAILURE;
	}

	status = bram_selftest();
	if (status != XST_SUCCESS)
	{
		xil_printf("bram self test error\r\n");
		return XST_FAILURE;
	}

	xil_printf("========== main exit ==========\r\n");
	return XST_SUCCESS;
}


/****************************************************************************/
/**
*
* This function initializes all BRAM controllers (and thereby also the
* corresponding BRAM blocks)
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
int bram_init(void)
{
	/* set ids */
	bram_ids[0] = BRAM_0_DEVICE_ID;
	bram_ids[1] = BRAM_1_DEVICE_ID;

	int Status;

	/* get respective configs and initialize */
	XBram_Config *ConfigPtr;
	for (int i = 0; i < NUM_BRAM; ++i)
	{
		ConfigPtr = XBram_LookupConfig(bram_ids[i]);
		if (ConfigPtr == (XBram_Config *) NULL)
		{
			xil_printf("bram config lookup failed\r\n");
			return XST_FAILURE;
		}

		Status = XBram_CfgInitialize(&brams[i], ConfigPtr, ConfigPtr->CtrlBaseAddress);
		if (Status != XST_SUCCESS) {
			xil_printf("bram config init failed\r\n");
			return XST_FAILURE;
		}
	}

	/* for global use */
	curr_bram_idx = 0;
	curr_write_addr = brams[curr_bram_idx].Config.MemBaseAddress;

	return XST_SUCCESS;
}


/****************************************************************************/
/**
*
* This function writes dummy data to BRAM and reads it back to check for
* correctness
* It first tests the internal read and write functionality and then the
* custom direct write function
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
int bram_selftest(void)
{
	xil_printf("running selftest...");
	int status;
	u32 num_addr = 8192;
	u32 data = 2147483648;

	/*
	 *  internal dfunctions test
	 */
	for (int bidx = 0; bidx < NUM_BRAM; ++bidx)
	{
		for (u32 i = 0; i < num_addr; i+=4)
		{
			XBram_WriteReg(brams[bidx].Config.MemBaseAddress, i, data);
			data -= 1;
		}
	}

	data = 2147483648;
	for (int bidx = 0; bidx < NUM_BRAM; ++bidx)
	{
		for (u32 i = 0; i < num_addr; i+=4)
		{
			if (data != XBram_ReadReg(brams[bidx].Config.MemBaseAddress, i))
			{
				xil_printf("bram %d expected %lu but got %lu\r\n", bidx, data, XBram_ReadReg(brams[0].Config.MemBaseAddress, i));
				return XST_FAILURE;
			}
			data -= 1;
		}
	}

	/*
	 * custom functions test
	 */
	u32 *foo;
	u32 num_data = 5;
	foo = malloc(num_data*sizeof(u32));

	for (int i = 0; i < num_data; ++i)
	{
		foo[i] = 3*i;
	}

	status = bram_write_data(foo, num_data);
	if (status != XST_SUCCESS)
	{
		free(foo);
		xil_printf("write data fial\r\n");
		return XST_FAILURE;
	}

	for (int i = 0; i < num_data; ++i)
	{
		if (XBram_ReadReg(brams[curr_bram_idx].Config.MemBaseAddress, 4*i) != foo[i])
		{
			xil_printf("expected=%d got=%d\r\n", foo[i], XBram_ReadReg(brams[curr_bram_idx].Config.MemBaseAddress, 0));
		}
	}

	free(foo);

	xil_printf("selftest successful\r\n");
	return XST_SUCCESS;
}


/****************************************************************************/
/**
*
* Writes data to the current global write-able address in BRAM and updates
* the value of that address. If
*
* @param	data is the pointer to data array to write to BRAM
*
* @param	num_words is the number of data values to write
*
* @return
*		- XST_SUCCESS to indicate success.
*		- XST_FAILURE to indicate failure i.e. no memory available
*
* @note		None.
*
*****************************************************************************/
int bram_write_data(u32 *data, u32 num_words)
{
	u32 words_written;
	for (words_written = 0; words_written < num_words; ++words_written)
	{
		/* write to current available addr */
		XBram_WriteReg(curr_write_addr, 0, *(data + words_written));

		/* if this bram is full, change write address to base of next bram */
		curr_write_addr += 4;
		if (curr_write_addr == brams[curr_bram_idx].Config.MemHighAddress)
		{
			/* if this is the last bram, then there is no more space to write data */
			if (curr_bram_idx == NUM_BRAM-1)
			{
				xil_printf("not enough bram\r\n");
				return XST_FAILURE;
			}

			curr_bram_idx++;
			curr_write_addr = brams[curr_bram_idx].Config.MemBaseAddress;
		}
	}

	return XST_SUCCESS;
}


/****************************************************************************/
/**
*
* Writes data to the given address, if memory is available
*
* @param	addr is the starting address to write data values to
*
* @param	data is the pointer to data array to write to BRAM
*
* @param	num_words is the number of data values to write
*
* @return
*		- XST_SUCCESS to indicate success.
*		- XST_FAILURE to indicate failure i.e. no memory available
*
* @note		None.
*
*****************************************************************************/
int bram_write_data_to_addr(u32 addr, u32 *data, u32 num_words)
{
	/*
	 * find the bram in whose range the input address falls
	 */
	u32 bram_idx_to_write;
	u8 did_find_bram_idx = 0;
	for (int i = 0; i < NUM_BRAM; ++i)
	{
		if ( (addr >= brams[i].Config.MemBaseAddress) && (addr < brams[i].Config.MemHighAddress) )
		{
			bram_idx_to_write = i;
			did_find_bram_idx = 1;
		}
	}

	if (!did_find_bram_idx)
	{
		xil_printf("invalid address\r\n");
		return XST_FAILURE;
	}

	/*
	 * write to the bram
	 */
	u32 words_written;
	for (words_written = 0; words_written < num_words; ++words_written)
	{
		XBram_WriteReg(addr, 0, *(data + words_written));

		/* if this bram is full, change write address to base of next bram */
		addr += 4;
		if (addr == brams[bram_idx_to_write].Config.MemHighAddress)
		{
			/* if this is the last bram, then there is no more space to write data */
			if (bram_idx_to_write == NUM_BRAM-1)
			{
				xil_printf("not enough bram\r\n");
				return XST_FAILURE;
			}

			bram_idx_to_write++;
			addr = brams[bram_idx_to_write].Config.MemBaseAddress;
		}
	}

	return XST_SUCCESS;
}
