/*
 * graphics.h
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */

#ifndef GRAPHICS_H_
#define GRAPHICS_H_

#include <string>
#include "system.h"

void drawImg(int img_id, int imgX, int imgY);
void drawSprite(int img_id, int imgX, int imgY);
void drawString(std::string s, int x, int y);

void clearScreen();

#endif /* GRAPHICS_H_ */
