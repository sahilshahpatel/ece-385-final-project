/*
 * Player.cpp
 *
 *  Created on: Apr 27, 2020
 *      Author: sahil
 */

#include "Player.h"

Player::Player(int x0, int y0) {
	x = x0;
	y = y0;

	// Initialize facing up
	facing_x = x;
	facing_y = y - 1;
}

