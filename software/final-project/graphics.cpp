/*
 * graphics.c
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "graphics.h"
#include "system.h"
#include "stdio.h"

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

	if(GRAPHICS_PTR[4] != 1) printf("Done flag: %d", GRAPHICS_PTR[4]);

	// Lower start flag
	GRAPHICS_PTR[3] = 0;
}

#define ALPHABET_SPRITE_START 50
#define NUMERAL_SPRITE_START 76
#define QUESTION_MARK_SPRITE 86
void drawString(std::string s, int x0, int y0, int COLS, int ROWS){
	if(x0 < 0 || y0 < 0) return;

	int x = x0;
	int y = y0;

	for(std::string::size_type i = 0; i < s.size(); i++){
		// Skip spaces
		if(s[i] == ' '){
			x++;
			continue;
		}

		// If newline, jump down
		if(s[i] == '\n'){
			x = x0;
			y ++;
			continue;
		}

		// If x, y is out of bounds exit
		if(x >= COLS || y >= ROWS) return;

		char c = std::toupper(s[i]);
		int ascii = (int)c;
		int img_id;
		if(ascii >= 48 && ascii <= 57){
			img_id = ascii - 48 + NUMERAL_SPRITE_START;
		}
		else if(ascii >= 65 && ascii <= 90){
			img_id = ascii - 65 + ALPHABET_SPRITE_START;
		}
		else{
			img_id = QUESTION_MARK_SPRITE;
		}

		drawSprite(img_id, x*SPRITE_SIZE, y*SPRITE_SIZE);
		x++;
	}
}
