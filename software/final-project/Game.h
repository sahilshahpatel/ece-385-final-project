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

// Sprite locations
const std::pair<int, int> TILE_SPRITE(4, 2);
const std::pair<int, int> WALL_SPRITE(6, 2);
const std::pair<int, int> SPIKES_SPRITE(8, 2);
const std::pair<int, int> STAIRS_SPRITE(10, 2);
const std::pair<int, int> PLAYER_LIGHT_SPRITE(12, 2);
const std::pair<int, int> PLAYER_DARK_SPRITE(14, 2);
const std::pair<int, int> MONSTER_LIGHT_SPRITE(0, 4);
const std::pair<int, int> MONSTER_DARK_SPRITE(2, 4);
const std::pair<int, int> MONSTER_DEAD_SPRITE(4, 4);

enum Tile {
	TILE,
	SPIKES,
	WALL,
	STAIRS
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
	bool next;

	// Variables to handle key presses
	int prev_key;
	int key; // Is set only on initial press

	void updateKey(int keycodes);
	void handleInput(int key);
	bool canMove(Player player, int dest_x, int dest_y) const;
	bool validPos(int x, int y) const;
	bool validPos(pair<int, int> p) const;
	std::pair<int, int> spriteFromTile(Tile tile);
	void setupLevel();
	std::pair<int, int> findPath(int x0, int y0, int dest_x, int dest_y) const;
	std::pair<int, int> findPath(Monster m, Player p) const;
};

#endif /* GAME_H_ */
