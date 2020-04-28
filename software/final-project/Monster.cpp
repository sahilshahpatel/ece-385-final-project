/*
 * Monster.cpp
 *
 *  Created on: Apr 27, 2020
 *      Author: sahil
 */

#include "Monster.h"

Monster::Monster(int x0, int y0) {
	x = x0;
	y = y0;
	active = false;
}

Monster::~Monster() {
	// TODO Auto-generated destructor stub
}

// Pathfinding
void Monster::chasePlayer(Player p){
	// TODO: replace
	x = 0;
	y = 0;
}

