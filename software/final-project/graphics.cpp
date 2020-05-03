/*
 * graphics.c
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "graphics.h"
#include "system.h"
#include "stdio.h"

#define SPRITE_COLS 40
#define SPRITE_ROWS 30

// Pointer to registers inside of graphics interface
volatile unsigned int * GRAPHICS_PTR = (unsigned int *) AVALON_GRAPHICS_INTERFACE_0_BASE;

#define SPRITE_SIZE 16
void drawImg(std::pair<int, int> img, int imgX, int imgY){ //top left top right bottom left bottom right
		drawSprite(img.first, img.second , imgX , imgY);
		drawSprite(img.first + 1, img.second, imgX + SPRITE_SIZE, imgY);
		drawSprite(img.first, img.second + 1, imgX, imgY + SPRITE_SIZE);
		drawSprite(img.first + 1, img.second + 1, imgX + SPRITE_SIZE, imgY + SPRITE_SIZE);
}

void drawSprite(int spritesheetX, int spritesheetY, int imgX, int imgY){
	// Set spritesheetX, spritesheetY, imgX, and imgY
	GRAPHICS_PTR[0] = spritesheetX;
	GRAPHICS_PTR[1] = spritesheetY;
	GRAPHICS_PTR[2] = imgX;
	GRAPHICS_PTR[3] = imgY;

	// Tell accelerator to start
	GRAPHICS_PTR[4] = 1;

	while(GRAPHICS_PTR[6] == 0){
		// Wait for Done flag
	}

	// Lower start flag
	GRAPHICS_PTR[4] = 0;
}

void drawString(std::string s, int x0, int y0){
	// Ignore invalid x0, y0
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
		if(x >= SPRITE_COLS || y >= SPRITE_ROWS) return;
		std::pair<int, int> spritesheetCoords = getSpriteForChar(s[i]);

		drawSprite(spritesheetCoords.first, spritesheetCoords.second, x*SPRITE_SIZE, y*SPRITE_SIZE);
		x++;
	}
}

std::pair<int, int> getSpriteForChar(char c){
	c = std::toupper(c); // Set to uppercase

	switch(c){
	default: return std::pair<int, int>(2, 2); // Question mark
	case 'A': return std::pair<int, int>(0, 0);
	case 'B': return std::pair<int, int>(1, 0);
	case 'C': return std::pair<int, int>(0, 1);
	case 'D': return std::pair<int, int>(1, 1);
	case 'E': return std::pair<int, int>(2, 0);
	case 'F': return std::pair<int, int>(3, 0);
	case 'G': return std::pair<int, int>(2, 1);
	case 'H': return std::pair<int, int>(3, 1);
	case 'I': return std::pair<int, int>(4, 0);
	case 'J': return std::pair<int, int>(5, 0);
	case 'K': return std::pair<int, int>(4, 1);
	case 'L': return std::pair<int, int>(5, 1);
	case 'M': return std::pair<int, int>(6, 0);
	case 'N': return std::pair<int, int>(7, 0);
	case 'O': return std::pair<int, int>(6, 1);
	case 'P': return std::pair<int, int>(7, 1);
	case 'Q': return std::pair<int, int>(8, 0);
	case 'R': return std::pair<int, int>(9, 0);
	case 'S': return std::pair<int, int>(8, 1);
	case 'T': return std::pair<int, int>(9, 1);
	case 'U': return std::pair<int, int>(10, 0);
	case 'V': return std::pair<int, int>(11, 0);
	case 'W': return std::pair<int, int>(10, 1);
	case 'X': return std::pair<int, int>(11, 1);
	case 'Y': return std::pair<int, int>(12, 0);
	case 'Z': return std::pair<int, int>(13, 0);
	case '0': return std::pair<int, int>(12, 1);
	case '1': return std::pair<int, int>(13, 1);
	case '2': return std::pair<int, int>(14, 0);
	case '3': return std::pair<int, int>(15, 0);
	case '4': return std::pair<int, int>(14, 1);
	case '5': return std::pair<int, int>(15, 1);
	case '6': return std::pair<int, int>(0, 2);
	case '7': return std::pair<int, int>(1, 2);
	case '8': return std::pair<int, int>(0, 3);
	case '9': return std::pair<int, int>(1, 3);
	case '?': return std::pair<int, int>(2, 2);
	case '.': return std::pair<int, int>(3, 2);
	case ':': return std::pair<int, int>(2, 3);
	case '!': return std::pair<int, int>(3, 3);
	}
}

/*
 * Tells GPU that the next frame is ready.
 * GPU begins outputting the frame and clears a new
 * frame buffer to be drawn to.
 */
void swapFrameBuffers(){
	GRAPHICS_PTR[5] = 1; // Set clear_start flag high
	while(GRAPHICS_PTR[6] == 0){
		// Wait for done flag
	}
	GRAPHICS_PTR[5] = 0; // Lower clear_start
}
