// FIXME: axi stream has to have at least 32 bit wide data
// FIXME: tail ptr is 0 for bdring
// TODO: add interrupts

/***************************** Include Files *********************************/
#include <stdio.h>
#include "xaxidma.h"
#include "xparameters.h"
#include "platform.h"
#include "xil_printf.h"
#include "xdebug.h"
#include "xscugic.h"


/******************** Constant Definitions **********************************/

#define RX_INTR_ID		XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID
#define TX_INTR_ID		XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID
#define INTC_DEVICE_ID          XPAR_SCUGIC_SINGLE_DEVICE_ID

#define INTC		XScuGic
#define INTC_HANDLER	XScuGic_InterruptHandler

/* shared ddr region */
#define SHARED_DDR_BASE		0x00008000
#define SHARED_DDR_HIGH		0x3FFFFFFF

/* upper mem region */
#define MEM_BASE_ADDR 0x00100000
#define MEM_HIGH_ADDR 0x3FFFFFFF

/* dma instance */
#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

/* one buffer descriptor per matrix */
#define NUM_TX_BD 2
#define NUM_RX_BD 2

// TODO: change space for final implementation
/* memory region for buffer descriptors */
#define TX_BD_SPACE_BASE	(MEM_BASE_ADDR)
#define TX_BD_SPACE_HIGH	(MEM_BASE_ADDR + 0x00000FFF)
#define RX_BD_SPACE_BASE	(MEM_BASE_ADDR + 0x00001000)
#define RX_BD_SPACE_HIGH	(MEM_BASE_ADDR + 0x00001FFF)

/* rx buffer region */
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00020000)
#define RX_BUFFER_HIGH		(MEM_BASE_ADDR + 0x0002FFFF)

#define COALESCING_COUNT 2
#define DELAY_TIMER_COUNT 100

/* dummy value */
#define IMG_SIZE 4

/* each packet will send one matrix ie r x r x 4 bytes */
#define PKT_LEN IMG_SIZE*IMG_SIZE*4


/************************** Function Prototypes ******************************/

#define status_check(...) \
	do { if (status != XST_SUCCESS) { \
			xil_printf(__VA_ARGS__);  \
			return XST_FAILURE;       \
		 }                            \
	} while (0)

static int init_rx_bd_ring(XAxiDma *dma_inst_ptr);
static int init_tx_bd_ring(XAxiDma *dma_inst_ptr);
static int init_interrupts(INTC *intc_inst_ptr, XAxiDma *dma_inst_ptr, u16 tx_intr_id, u16 rx_intr_id);
static int send_tx_data(XAxiDma *dma_inst_ptr);


/************************** Variable Definitions *****************************/

/* dma */
XAxiDma AxiDma;

/* interrupt controller */
static INTC intr_ctrl;

/*
 * Flags interrupt handlers use to notify the application context the events.
 */
volatile int TxDone;
volatile int RxDone;
volatile int Error;

/*
 * Dummy packets to be sent over dma
 */
u32 *matrix0;
u32 *matrix1;


/*****************************************************************************
*
* Main function
*
* @param	None
*
* @return
*		- XST_SUCCESS if test passes
*		- XST_FAILURE if test fails.
*
* @note		None.
*
******************************************************************************/

int main(int argc, char const *argv[])
{
	xil_printf("--------------- start ---------------\r\n");
#ifdef __aarch64__
	xil_printf("Disable cache");
	Xil_SetTlbAttributes(TX_BD_SPACE_BASE, MARK_UNCACHEABLE);
	Xil_SetTlbAttributes(RX_BD_SPACE_BASE, MARK_UNCACHEABLE);
#endif

	int status;

	XAxiDma_Config *dma_config_ptr;

	/*
	 * Initialize config for dma
	 */
	dma_config_ptr = XAxiDma_LookupConfig(DMA_DEV_ID);
	if (!dma_config_ptr) {
		xil_printf("No config found for %d\r\n", DMA_DEV_ID);
		return XST_FAILURE;
	}

	/* Initialize dma */
	status = XAxiDma_CfgInitialize(&AxiDma, dma_config_ptr);
	if (status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", status);
		return XST_FAILURE;
	}

	/*
	 * Ensure scatter gather mode
	 */
	if(!XAxiDma_HasSg(&AxiDma)) {
		xil_printf("Device configured as Simple mode \r\n");
		return XST_FAILURE;
	}

	/*
	 * Allocate region for image and filters
	 */
	matrix0 = malloc(4*IMG_SIZE*IMG_SIZE);
	for (int i = 0; i < IMG_SIZE*IMG_SIZE; ++i) {
		*(matrix0 + i) = i;
	}
	xil_printf("matrix0 is at 0x%x\r\n", matrix0);

	matrix1 = malloc(4*IMG_SIZE*IMG_SIZE);
	for (int i = 0; i < IMG_SIZE*IMG_SIZE; ++i) {
		*(matrix1 + i) = i;
	}
	xil_printf("matrix1 is at 0x%x\r\n", matrix1);


	/*
	 * Initialize tx and rx bd ring
	 */
	status = init_tx_bd_ring(&AxiDma);
	if (status != XST_SUCCESS) {
		xil_printf("tx setup failed");
		return XST_FAILURE;
	}

	status = init_rx_bd_ring(&AxiDma);
	if (status != XST_SUCCESS) {
		xil_printf("rx setup failed");
		return XST_FAILURE;
	}

	/* Set up Interrupt system  */
	status = init_interrupts(&intr_ctrl, &AxiDma, TX_INTR_ID, RX_INTR_ID);
	if (status != XST_SUCCESS) {
		xil_printf("Failed intr setup\r\n");
		return XST_FAILURE;
	}

	/* Initialize flags before start transfer test  */
	TxDone = 0;
	RxDone = 0;
	Error = 0;

	/* Send all data */
	status = send_tx_data(&AxiDma);
	if (status != XST_SUCCESS) {
		xil_printf("Failed send packet\r\n");
		return XST_FAILURE;
	}

	/* wait till data is transferred */
	u64 count = 0;
	xil_printf("counting...");
	while (count++ < 100000000);
	xil_printf("done\r\n");

	xil_printf("--------------- end ---------------\r\n");

	return 0;
}


/*****************************************************************************
*
* This function sets up TX channel of the DMA engine to be ready for packet
* reception
*
* @param	AxiDmaInstPtr is the pointer to the instance of the DMA engine.
*
* @return	XST_SUCCESS if the setup is successful, XST_FAILURE otherwise.
*
* @note		None.
*
******************************************************************************/
static int init_tx_bd_ring(XAxiDma *dma_inst_ptr)
{

	XAxiDma_BdRing *tx_bd_ring_ptr;
	int Delay = 0;
	int Coalesce = 1;
	int status;

	tx_bd_ring_ptr = XAxiDma_GetTxRing(&AxiDma);

	/* Disable all TX interrupts before TxBD space setup */
	XAxiDma_BdRingIntDisable(tx_bd_ring_ptr, XAXIDMA_IRQ_ALL_MASK);

	/* Set TX delay and coalesce */
	XAxiDma_BdRingSetCoalesce(tx_bd_ring_ptr, Coalesce, Delay);

	/* Setup bd ring in memory */
	status = XAxiDma_BdRingCreate(tx_bd_ring_ptr,
									TX_BD_SPACE_BASE,
									TX_BD_SPACE_BASE,
									XAXIDMA_BD_MINIMUM_ALIGNMENT,
									NUM_RX_BD);
	if (status != XST_SUCCESS) {
		xil_printf("failed create BD ring in txsetup\r\n");
		return XST_FAILURE;
	}

	/* we want only 1 interrupt per two transfers */
	status = XAxiDma_BdRingSetCoalesce(tx_bd_ring_ptr, COALESCING_COUNT, DELAY_TIMER_COUNT);
	if (status != XST_SUCCESS) {
		xil_printf("Failed set coalescing"
		" %d/%d\r\n",COALESCING_COUNT, DELAY_TIMER_COUNT);
		return XST_FAILURE;
	}

	/* Enable all TX interrupts */
	XAxiDma_BdRingIntEnable(tx_bd_ring_ptr, XAXIDMA_IRQ_ALL_MASK);

	/* Start the TX channel */
	status = XAxiDma_BdRingStart(tx_bd_ring_ptr);
	if (status != XST_SUCCESS) {
		xil_printf("failed start bdring txsetup %d\r\n", status);
		return XST_FAILURE;
	}

	// XAxiDma_DumpBd(first_bd_ptr);
	// XAxiDma_DumpBd(0x100040);
	// xil_printf("dma mm2s ctrl reg = 0x%x\r\n", Xil_In32(XPAR_AXI_DMA_0_BASEADDR+0x00));
	// XAxiDma_BdRingDumpRegs(tx_bd_ring_ptr);

	return XST_SUCCESS;
}

/*****************************************************************************
*
* This function sets up RX channel of the DMA engine to be ready for packet
* reception
*
* @param	AxiDmaInstPtr is the pointer to the instance of the DMA engine.
*
* @return	- XST_SUCCESS if the setup is successful.
*		- XST_FAILURE if fails.
*
* @note		None.
*
******************************************************************************/
static int init_rx_bd_ring(XAxiDma * AxiDmaInstPtr)
{
	XAxiDma_BdRing *rx_bd_ring_ptr;
	int status;
	XAxiDma_Bd *bd_ptr;
	XAxiDma_Bd *curr_bd_ptr;
	// int FreeBdCount;
	u32 rx_buffer_ptr;
	int Index;

	rx_bd_ring_ptr = XAxiDma_GetRxRing(&AxiDma);

	/* Disable all RX interrupts before RxBD space setup */
	XAxiDma_BdRingIntDisable(rx_bd_ring_ptr, XAXIDMA_IRQ_ALL_MASK);

	/* Setup Rx BD space */
	status = XAxiDma_BdRingCreate(rx_bd_ring_ptr,
									RX_BD_SPACE_BASE,
									RX_BD_SPACE_BASE,
									XAXIDMA_BD_MINIMUM_ALIGNMENT,
									NUM_RX_BD);
	if (status != XST_SUCCESS) {
		xil_printf("Rx bd create failed with %d\r\n", status);
		return XST_FAILURE;
	}

	// /* Attach buffers to RxBD ring so we are ready to receive packets */
	// FreeBdCount = XAxiDma_BdRingGetFreeCnt(rx_bd_ring_ptr);

	status = XAxiDma_BdRingAlloc(rx_bd_ring_ptr, NUM_RX_BD, &bd_ptr);
	if (status != XST_SUCCESS) {
		xil_printf("Rx bd alloc failed with %d\r\n", status);
		return XST_FAILURE;
	}

	curr_bd_ptr = bd_ptr;
	rx_buffer_ptr = RX_BUFFER_BASE;

	for (Index = 0; Index < NUM_RX_BD; Index++) {

		status = XAxiDma_BdSetBufAddr(curr_bd_ptr, rx_buffer_ptr);
		if (status != XST_SUCCESS) {
			xil_printf("Rx set buffer addr %x on BD %x failed %d\r\n",
			(unsigned int)rx_buffer_ptr,
			(UINTPTR)curr_bd_ptr, status);

			return XST_FAILURE;
		}

		status = XAxiDma_BdSetLength(curr_bd_ptr, PKT_LEN,
										rx_bd_ring_ptr->MaxTransferLen);
		if (status != XST_SUCCESS) {
			xil_printf("Rx set length %d on BD %x failed %d\r\n",
			    PKT_LEN, (UINTPTR)curr_bd_ptr, status);

			return XST_FAILURE;
		}

		/* Receive BDs do not need to set anything for the control
		 * The hardware will set the SOF/EOF bits per stream status
		 */
		XAxiDma_BdSetCtrl(curr_bd_ptr, 0);

		XAxiDma_BdSetId(curr_bd_ptr, rx_buffer_ptr);

		rx_buffer_ptr += PKT_LEN;
		curr_bd_ptr = (XAxiDma_Bd *)XAxiDma_BdRingNext(rx_bd_ring_ptr, curr_bd_ptr);
	}

	/*
	 * Set the coalescing threshold, so only one receive interrupt
	 * occurs for this example
	 */
	status = XAxiDma_BdRingSetCoalesce(rx_bd_ring_ptr, COALESCING_COUNT, DELAY_TIMER_COUNT);
	if (status != XST_SUCCESS) {
		xil_printf("Rx set coalesce failed with %d\r\n", status);
		return XST_FAILURE;
	}

	status = XAxiDma_BdRingToHw(rx_bd_ring_ptr, NUM_RX_BD, bd_ptr);
	if (status != XST_SUCCESS) {
		xil_printf("Rx ToHw failed with %d\r\n", status);
		return XST_FAILURE;
	}

	/* Enable all RX interrupts */
	XAxiDma_BdRingIntEnable(rx_bd_ring_ptr, XAXIDMA_IRQ_ALL_MASK);

	/* Start RX DMA channel */
	status = XAxiDma_BdRingStart(rx_bd_ring_ptr);
	if (status != XST_SUCCESS) {
		xil_printf("Rx start BD ring failed with %d\r\n", status);
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


/*****************************************************************************/
/*
*
* This function setups the interrupt system so interrupts can occur for the
* DMA, it assumes INTC component exists in the hardware system.
*
* @param	IntcInstancePtr is a pointer to the instance of the INTC.
* @param	AxiDmaPtr is a pointer to the instance of the DMA engine
* @param	TxIntrId is the TX channel Interrupt ID.
* @param	RxIntrId is the RX channel Interrupt ID.
*
* @return
*		- XST_SUCCESS if successful,
*		- XST_FAILURE.if not succesful
*
* @note		None.
*
******************************************************************************/
static int init_interrupts(INTC *intc_inst_ptr, XAxiDma *dma_inst_ptr, u16 tx_intr_id, u16 rx_intr_id)
{
	xil_printf("interrupts in fiture verison\r\n");
	return XST_SUCCESS;
}


/*****************************************************************************
*
* This function non-blockingly transmits all packets through the DMA engine.
*
* @param	AxiDmaInstPtr points to the DMA engine instance
*
* @return
* 		- XST_SUCCESS if the DMA accepts all the packets successfully,
* 		- XST_FAILURE if error occurs
*
* @note		None.
*
******************************************************************************/
static int send_tx_data(XAxiDma *dma_inst_ptr)
{
	int status;

	XAxiDma_BdRing *tx_bd_ring_ptr = XAxiDma_GetTxRing(dma_inst_ptr);

	/* Flush the SrcBuffer before the DMA transfer, in case the Data Cache
	 * is enabled
	 */
	// Xil_DCacheFlushRange((UINTPTR)TxPacket, PKT_LEN * NUM_TX_BD);

	/*
	 * Configure first available buffer descriptor
	 */
	XAxiDma_Bd *first_avail_bd_ptr, *curr_avail_bd_ptr;
	u32 ctrl_bits;

	status = XAxiDma_BdRingAlloc(tx_bd_ring_ptr, NUM_TX_BD, &first_avail_bd_ptr);
	status_check("Failed bd alloc\r\n");

	curr_avail_bd_ptr = first_avail_bd_ptr;
	ctrl_bits = 0;
	status = XAxiDma_BdSetBufAddr(curr_avail_bd_ptr, (UINTPTR)matrix0);
	status_check("matrix0 buffer allocate fial");

	status = XAxiDma_BdSetLength(curr_avail_bd_ptr, IMG_SIZE*IMG_SIZE*4, IMG_SIZE*IMG_SIZE*4);
	status_check("matrix0 bd length fail");

	/* start of data stream */
	ctrl_bits |= XAXIDMA_BD_CTRL_TXSOF_MASK;
	XAxiDma_BdSetCtrl(curr_avail_bd_ptr, ctrl_bits);

	XAxiDma_BdSetId(curr_avail_bd_ptr, matrix0);

	/* get the next available bd and reset control mask */
	curr_avail_bd_ptr = (XAxiDma_Bd*) XAxiDma_BdRingNext(tx_bd_ring_ptr, curr_avail_bd_ptr);
	ctrl_bits = 0;

	status = XAxiDma_BdSetBufAddr(curr_avail_bd_ptr, (UINTPTR)matrix1);
	status_check("matrix1 buffer allocate fial");

	status = XAxiDma_BdSetLength(curr_avail_bd_ptr, IMG_SIZE*IMG_SIZE*4, IMG_SIZE*IMG_SIZE*4);
	status_check("matrix1 bd length fail");

	/* end of data stream */
	ctrl_bits |= XAXIDMA_BD_CTRL_TXEOF_MASK;
	XAxiDma_BdSetCtrl(curr_avail_bd_ptr, ctrl_bits);

	XAxiDma_BdSetId(curr_avail_bd_ptr, matrix1);

	/* transfer to pl */
	status = XAxiDma_BdRingToHw(tx_bd_ring_ptr, NUM_TX_BD, first_avail_bd_ptr);
	status_check("ring to hw fail");

	return XST_SUCCESS;
}
