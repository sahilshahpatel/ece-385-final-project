/*
 * game.h
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */

#ifndef GAME_H_
#define GAME_H_

// Game structs
typedef struct {
	int x;
	int y;
	bool active;
} Monster;

enum Tile {
	TILE, SPIKES, WALL
};

typedef struct {
	int x;
	int y;
	bool light;

	int facing_x;
	int facing_y;
} Player;

class Game {
public:
	Game();
	void update(int keycode);
	void draw();
private:
	Player player;
	Monster* monsters;
	Tile** board;

	int key; // Is set only on initial press

	Monster chasePlayer(Monster m, Player p);
	void updateKey(int keycodes);
};

#endif /* GAME_H_ */

