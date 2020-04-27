//io_handler.c
#include "io_handler.h"
#include <stdio.h>

void IO_init(void)
{
	*otg_hpi_reset = 1;
	*otg_hpi_cs = 1;
	*otg_hpi_r = 1;
	*otg_hpi_w = 1;
	*otg_hpi_address = 0;
	*otg_hpi_data = 0;
	// Reset OTG chip
	*otg_hpi_cs = 0;
	*otg_hpi_reset = 0;
	*otg_hpi_reset = 1;
	*otg_hpi_cs = 1;
}

void IO_write(alt_u8 Address, alt_u16 Data)
{
//*************************************************************************//
//									TASK								   //
//*************************************************************************//
//							Write this function							   //
//*************************************************************************//
	*otg_hpi_address = Address; // Tell chip which address to write to
	*otg_hpi_cs = 0; // Enable chip
	*otg_hpi_w = 0; // Go into write mode
	*otg_hpi_data = Data; // Tell chip what data to write

	*otg_hpi_w = 1; // Leave write mode
	*otg_hpi_cs = 1; // Disable chip
}

alt_u16 IO_read(alt_u8 Address)
{
	alt_u16 data;
//*************************************************************************//
//									TASK								   //
//*************************************************************************//
//							Write this function							   //
//*************************************************************************//
	*otg_hpi_address = Address; // Tell chip which address to read from
	*otg_hpi_cs = 0; // Enable chip
	*otg_hpi_r = 0; // Go into read mode
	data = *otg_hpi_data; // Read data

	*otg_hpi_r = 1; // Leave read mode
	*otg_hpi_cs = 1; // Disable chip

	return data;
}
