/*
 * Monster.cpp
 *
 *  Created on: Apr 27, 2020
 *      Author: sahil
 */

#include "Monster.h"

Monster::Monster(int x0, int y0) :
	x(x0),
	y(y0),
	active(false),
	alive(true),
	last_move_time(clock())
{}

Monster::~Monster() {
	// TODO Auto-generated destructor stub
}

