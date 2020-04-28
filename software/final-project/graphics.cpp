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

#define SPRITE_SIZE 16
void drawImg(int img_id, int imgX, int imgY){ //top left top right bottom left bottom right
		drawSprite(img_id , imgX , imgY);
		drawSprite(img_id +1, imgX + SPRITE_SIZE, imgY);
		drawSprite(img_id +2, imgX, imgY + SPRITE_SIZE);
		drawSprite(img_id +3, imgX + SPRITE_SIZE, imgY + SPRITE_SIZE);
}

void drawSprite(int img_id, int imgX, int imgY){
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
