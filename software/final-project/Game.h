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
#include <string>

#include "Monster.h"
#include "Player.h"

using std::vector;
using std::pair;

// Image IDs
#define PLAYER_SPRITE 0
#define MONSTER_SPRITE 4
#define PLAYER_LIGHT_SPRITE 8
#define SPIKES_SPRITE 12
#define TILE_SPRITE 16
#define WALL_SPRITE 20
#define STAIRS_UP_SPRITE 24
#define STAIRS_LEFT_SPRITE 28

enum Tile {
	TILE = TILE_SPRITE,
	SPIKES = SPIKES_SPRITE,
	WALL = WALL_SPRITE,
	STAIRS = STAIRS_UP_SPRITE
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
	int level;
	bool win;
	bool dead; 

	// Variables to handle key presses
	int prev_key;
	int key; // Is set only on initial press

	void updateKey(int keycodes);
	void handleInput(int key);
	bool canMove(Player player, int dest_x, int dest_y) const;
	bool validPos(int x, int y) const;
	bool validPos(pair<int, int> p) const;
	void setupLevel();
	std::pair<int, int> findPath(int x0, int y0, int dest_x, int dest_y) const;
	std::pair<int, int> findPath(Monster m, Player p) const;
};

#endif /* GAME_H_ */
