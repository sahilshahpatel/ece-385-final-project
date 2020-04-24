/*
 * graphics.c
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "graphics.h"
#include "system.h"

// Pointer to registers inside of graphics interface
volatile unsigned int * GRAPHICS_PTR = (unsigned int *) AVALON_GRAPHICS_INTERFACE_0_BASE;

void drawImg(int img_id, int imgX, int imgY){
	// Set img_id, imgX, and imgY
	GRAPHICS_PTR[0] = img_id;
	GRAPHICS_PTR[1] = imgX;
	GRAPHICS_PTR[2] = imgY;

	// Tell accelerator to start
	GRAPHICS_PTR[3] = 1;

	while(GRAPHICS_PTR[4] == 0){
		// Wait for Done flag
	}

	// Lower start flag
	GRAPHICS_PTR[3] = 0;
}


