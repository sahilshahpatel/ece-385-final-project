/*
 * Game.cpp
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "Game.h"

#include "graphics.h"
#include <stdio.h>
#include <fstream>
#include <iostream>
#include <sstream>

// Game board is 64x64 tiles where each tile is 16x16 pixels
#define TILE_SIZE 32
#define COLS 20 // 640 pix / TILE_SIZE
#define ROWS 15 // 480 pix / TILE_SIZE

Game::Game() :
level(0), prev_key(0), key(0), win(false), dead(false)
{
	// Allocate board
	board = new Tile*[COLS];
	for(int x = 0; x < COLS; x++){
		board[x] = new Tile[ROWS];
		for(int y = 0; y < ROWS; y++){
			board[x][y] = WALL;
		}
	}

	// Setup for level 0
	setupLevel();
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
		dead = true;
	}

	// If player is on EXIT, they win the level
	if (board[player.x][player.y] == STAIRS){
		win = true;
		// TODO: increment level once we have more levels
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
			dead = true;
		}

		// Active monsters chase player if light is on
		if(light && monsters[i].active){
			monsters[i].chasePlayer(player);
		}

		// If a monster is on spikes, it dies
		if(board[monsters[i].x][monsters[i].y] == SPIKES){
			//TODO monster dies
			//increment score counter
		}
	}
}

// Draws all sprites where they should be
void Game::draw(){
	if(dead == false && win == false){
		// Draw tiles only if light is on
		if(light){
			// Draw tile player is on
			drawImg(board[player.x][player.y], player.x*TILE_SIZE, player.y*TILE_SIZE);

			// Draw tile player is facing
			if(validPos(player.facing_x, player.facing_y))
				drawImg(board[player.facing_x][player.facing_y], player.facing_x*TILE_SIZE, player.facing_y*TILE_SIZE);
		}

		// Draw monsters if applicable
		for(uint i = 0; i < monsters.size(); i++){
			if(monsters[i].x == player.facing_x && monsters[i].y == player.facing_y){
				drawImg(MONSTER_SPRITE, monsters[i].x*TILE_SIZE, monsters[i].y*TILE_SIZE);
			}
		}

		// Draw player with or without light
		drawImg(PLAYER_SPRITE, player.x*TILE_SIZE, player.y*TILE_SIZE);
	}
	//if player dies draw game over screen
	else if(dead){
		drawString("GAME OVER", 15, 12);
		drawString("Press SPACE to RESTART", 9, 17);
	}
	//if player wins draw next level or win screen //40x30 //TODO add Score
	else if(win){
		drawString("You Win CONGRATS ", 13, 12);
		drawString("Press SPACE to RESTART", 9, 17);
	}
}

/* Helper functions */

void Game::handleInput(int key){
	switch(key){
	case KEYCODE_SPACE: // Toggle light
		if(dead == false && win == false){
			light = !light;
		}
		else{
			setupLevel();
		}
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
	//if player won or died, deny
	if(win || dead) return false;
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

void Game::setupLevel(){
	// Reset game state
	dead = false;
	win = false;
	light = true;
	monsters.clear();

	// Set initial board to all walls
	for(int x = 0; x < COLS; x++){
		for(int y = 0; y < ROWS; y++){
			board[x][y] = WALL;
		}
	}

	// Switch case for level
	switch(level){
	case 0:
		// Player is at 6, 14
		board[6][14] = TILE;
		player = Player(6, 14);

		// Monster is at 6, 10
		board[6][10] = TILE;
		monsters.push_back(Monster(6, 10));

		// Spikes at 6, 16
		board[6][12] = SPIKES;

		// Exit at 6, 12
		board[6][8] = STAIRS;

		// Create rest of tile path
		board[6][13] = TILE;
		board[7][13] = TILE;
		board[8][13] = TILE;
		board[8][12] = TILE;
		board[8][11] = TILE;
		board[7][11] = TILE;
		board[6][11] = TILE;
		board[6][9] = TILE;
		break;
	}
}
