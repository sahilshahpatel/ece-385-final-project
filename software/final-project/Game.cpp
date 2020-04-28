/*
 * Game.cpp
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "Game.h"

#include "graphics.h"
#include <stdio.h>

// Game board is 64x64 tiles where each tile is 16x16 pixels
#define TILE_SIZE 32
#define COLS 20 // 640 pix / TILE_SIZE
#define ROWS 15 // 480 pix / TILE_SIZE

Game::Game() :
player(COLS/2, ROWS-1), light(true), prev_key(0), key(0) // Initializations
{
	// Setup board
	board = new Tile*[COLS];
	for(int x = 0; x < COLS; x++){
		board[x] = new Tile[ROWS];
		for(int y = 0; y < ROWS; y++){
			board[x][y] = TILE;
		}
	}

	// Set initial monster list
	monsters = vector<Monster>();
	monsters.push_back(Monster(0, 0)); // TODO: decide how many monsters to have
}

Game::~Game(){
	// Delete board
	for(int x = 0; x < COLS; x++){
		delete[] board[x];
	}
	delete[] board;
}

// Keycodes
#define KEYCODE_W 26
#define KEYCODE_A 4
#define KEYCODE_S 22
#define KEYCODE_D 7
#define KEYCODE_SPACE 44

// Game logic happens in update
void Game::update(int keycodes){

	updateKey(keycodes); // Update the current key (handles on-key-down behavior)

	handleInput(key); // Toggles light or moves player

	if(!validPos(player.x, player.y))
		printf("Invalid player pos: %d, %d\n", player.x, player.y);

	// If player is on spikes, they die
	if (board[player.x][player.y] == SPIKES){
		//TODO: WHAT HAPPENS ON DEATH
	}

	// If player is on EXIT, they win the level
	if (board[player.x][player.y] == EXIT){
		//TODO: WHAT HAPPENS ON WIN
	}

	// Monster logic
	for(uint i = 0; i < monsters.size(); i++){
		if(!validPos(monsters[i].x, monsters[i].y))
			printf("Invalid monster pos: %d, %d\n", monsters[i].x, monsters[i].y);

		// If player sees a monster, it activates
		if (player.facing_x == monsters[i].x && player.facing_y == monsters[i].y){
			monsters[i].active = true;
		}

		// If player is on the same tile as a monster, they die
		if (player.x == monsters[i].x && player.y == monsters[i].y){
			// TODO: WHAT HAPPENS ON DEATH
		}

		// Active monsters chase player if light is on
		if(light && monsters[i].active){
			monsters[i].chasePlayer(player);
		}

		// If a monster is on spikes, it dies
		if(board[monsters[i].x][monsters[i].y] == SPIKES){
			//TODO monster dies
		}
	}
}

// Image IDs
#define PLAYER_SPRITE 0
#define MONSTER_SPRITE 4
#define PLAYER_LIGHT_SPRITE 8
#define SPIKES_SPRITE 12
#define TILE_SPRITE 16
#define WALL_SPRTIE 20

// Draws all sprites where they should be
void Game::draw(){
	// Draw tiles only if light is on
	if(light){
		// Draw tile player is on
		drawImg(TILE_SPRITE, player.x*TILE_SIZE, player.y*TILE_SIZE);

		// Draw tile player is facing
		if(validPos(player.facing_x, player.facing_y))
			drawImg(TILE_SPRITE, player.facing_x*TILE_SIZE, player.facing_y*TILE_SIZE);
	}

	// Draw player with or without light
	drawImg(PLAYER_SPRITE, player.x*TILE_SIZE, player.y*TILE_SIZE);
}

/* Helper functions */

void Game::handleInput(int key){
	switch(key){
	case KEYCODE_SPACE: // Toggle light
		light = !light;
		break;
	case KEYCODE_W: // Move up
		if(canMove(player, player.x, player.y - 1)){
			player.y--;
		}
		player.facing_y = player.y - 1;
		player.facing_x = player.x;
		break;
	case KEYCODE_S: // Move down
		if(canMove(player, player.x, player.y + 1)){
			player.y++;
		}
		player.facing_y = player.y + 1;
		player.facing_x = player.x;
		break;
	case KEYCODE_A: // Move left
		if(canMove(player, player.x - 1, player.y)){
			player.x--;
		}
		player.facing_y = player.y;
		player.facing_x = player.x - 1;
		break;
	case KEYCODE_D: // Move right
		if(canMove(player, player.x + 1, player.y)){
			player.x++;
		}
		player.facing_y = player.y;
		player.facing_x = player.x + 1;
		break;
	}
}

// Validate movements
bool Game::canMove(Player p, int dest_x, int dest_y){
	// If moving out of bounds, deny
	if(!validPos(dest_x, dest_y)) return false;

	// If moving to a wall, deny
	if(board[dest_x][dest_y] == WALL) return false;

	if(light){
		// If light is on, must be facing destination
		return dest_y == player.facing_y && dest_x == player.facing_x;
	}
	else{
		// If light is off, facing doesn't matter
		return true;
	}
}

bool Game::validPos(int x, int y){
	return x < COLS && x >= 0 && y < ROWS && y >= 0;
}

// Key-down detector
void Game::updateKey(int keycodes){
	int key1 = keycodes & 0x0000ffff;
	//int key2 = (keycodes & 0xffff0000) >> 16;
	// Ignore key2 -- we only allow one button at a time

	// TODO: When/if we do animations, it would be nice to allow
	//	the user to hold down a key and have it activate every time
	//	an animation finishes. To do this we can get rid of this
	// "on-key-down" behavior and add a lockout time during animations!

	if(key1 == prev_key) key = 0;
	else key = key1;

	prev_key = key1;
}
