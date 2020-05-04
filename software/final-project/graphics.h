/*
 * graphics.h
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */

#ifndef GRAPHICS_H_
#define GRAPHICS_H_

#include <string>

void drawSprite(int spritesheetX, int spritesheetY, int imgX, int imgY);
void drawImg(std::pair<int, int> sprite, int imgX, int imgY);
void drawScreen(std::pair<int, int> screen);

void drawString(std::string s, int x, int y);
std::pair<int, int> getSpriteForChar(char c);

void swapFrameBuffers();

#endif /* GRAPHICS_H_ */
