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
using std::string;

// Sprite locations
const pair<int, int> TILE_SPRITE(4, 2);
const pair<int, int> WALL_SPRITE(6, 2);
const pair<int, int> SPIKES_SPRITE(8, 2);
const pair<int, int> STAIRS_SPRITE(10, 2); // Always chooses the left facing stairs
const pair<int, int> PLAYER_LIGHT_SPRITE(12, 2);
const pair<int, int> PLAYER_DARK_SPRITE(14, 2);
const pair<int, int> MONSTER_LIGHT_SPRITE(0, 4);
const pair<int, int> MONSTER_DARK_SPRITE(2, 4);
const pair<int, int> MONSTER_DEAD_SPRITE(4, 4);
const pair<int, int> TITLE_SCREEN_SPRITE(0, 8);
const pair<int, int> MOVEMENT_CONTROLS_SPRITE_0(8, 4);
const pair<int, int> MOVEMENT_CONTROLS_SPRITE_1(10, 4);
const pair<int, int> LIGHT_CONTROLS_SPRITE_0(12, 4);
const pair<int, int> LIGHT_CONTROLS_SPRITE_1(14, 4);
const pair<int, int> SKULL_SPRITE(0, 6);

enum Tile {
	TILE,
	SPIKES,
	WALL,
	STAIRS
};

enum GameState {
	START,
	LEADERBOARD,
	IN_GAME,
	POST_GAME
};

class Game {
  public:
	Game();
	~Game();
	void update(int keycode);
	void draw();
  private:
	GameState gameState;
	Player player;
	vector<Monster> monsters;
	Tile** board;
	bool light;
	int level;
	bool dead;
	bool next;

	clock_t lastLightOffTime;

	int deathCounter;
	clock_t levelStartTime;
	vector<clock_t> levelTimes;

	float totalTime;
	string playerName;
	vector<pair<float, string> > leaderboard; // Float first so it's sorted by time

	// Variables to handle key presses
	int prev_key;
	int key; // Is set only on initial press

	void updateKey(int keycodes);
	void handleInput(int key);
	bool canMove(Player player, int dest_x, int dest_y) const;
	bool validPos(int x, int y) const;
	bool validPos(pair<int, int> p) const;

	void playerNameInput(int key);
	void appendToPlayerName(char c);

	std::pair<int, int> spriteFromTile(Tile tile);
	void setupLevel();
	std::pair<int, int> findPath(int x0, int y0, int dest_x, int dest_y) const;
	std::pair<int, int> findPath(Monster m, Player p) const;

	void drawStart();
	void drawLeaderboard();
	void drawLevel();
	void drawPostGame();

	void reset();
};

#endif /* GAME_H_ */
