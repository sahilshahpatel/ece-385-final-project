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
} Monster;

enum Tile {
	TILE, SPIKES, WALL
};

typedef struct {
	int x;
	int y;
	int light;
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
};

#endif /* GAME_H_ */

