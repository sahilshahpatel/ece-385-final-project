/*
 * Game.h
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */

#ifndef GAME_H_
#define GAME_H_

#include <vector>
#include <time.h>

#include "Monster.h"
#include "Player.h"

using std::vector;

// Game data types
enum Tile {
	TILE, SPIKES, WALL, EXIT
};

class Game {
  public:
	Game();
	~Game();
	void update(int keycode);
	void draw();
  private:
	Player player;
	vector<Monster> monsters;
	Tile** board;
	bool light;
	bool win;
	bool dead; 

	// Variables to handle key presses
	int prev_key;
	int key; // Is set only on initial press

	void updateKey(int keycodes);
	void handleInput(int key);
	bool canMove(Player player, int dest_x, int dest_y);
	bool validPos(int x, int y);
};

#endif /* GAME_H_ */
