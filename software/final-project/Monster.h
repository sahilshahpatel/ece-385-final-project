/*
 * Monster.h
 *
 *  Created on: Apr 27, 2020
 *      Author: sahil
 */

#ifndef MONSTER_H_
#define MONSTER_H_

#include "Player.h"

class Monster {
  public:
	Monster(int x0, int y0);
	~Monster();

	int x;
	int y;
	bool active;
	void chasePlayer(Player player);
};

#endif /* MONSTER_H_ */
