/*
 * game.c
 *
 *  Created on: Apr 24, 2020
 *      Author: sahil
 */
#include "game.h"
#include "system.h"
#include "graphics.h"
#include <iostream>

// Game board is 64x64 tiles where each tile is 16x16 pixels
#define SPRITE_SIZE 16
#define ROWS 64
#define COLS 64

Game::Game(){
	// Setup board
	board = new Tile*[ROWS];
	for(int r = 0; r < ROWS; r++){
		board[r] = new Tile[COLS];
		for(int c = 0; c < COLS; c++){
			board[r][c] = TILE;
		}
	}

	// Set initial player locations
	player.x = ROWS/2;
	player.y = COLS-1;
	player.light = true;

	// Set initial monster list
	monsters = new Monster[1]; // TODO: decide how many monsters to have
	monsters[0].x = 0;
	monsters[0].y = 0;
}

// Keycodes
#define KEYCODE_W 26
#define KEYCODE_A 4
#define KEYCODE_S 22
#define KEYCODE_D 7
#define KEYCODE_SPACE 44

// Game logic happens in update
void Game::update(int keycodes){
	std::cout << "updating game" << std::endl;

	int key1 = keycodes & 0x0000ffff;
	int key2 = (keycodes & 0xffff0000) >> 16;

	// FOR TESTING ONLY:
	if(key1 == KEYCODE_W){
		player.y--;
	}
	else if(key1 == KEYCODE_S){
		player.y++;
	}

	// Wrap-around
	if(player.y < 0){
		player.y = COLS-1;
	}
	else if(player.y > COLS-1){
		player.y = 0;
	}
}

// Image IDs
#define MAIN_CHARACTER_SPRITE 0
#define TILE_SPRITE 1

// Draws all sprites where they should be
void Game::draw(){
	// For testing, draw main character
	drawImg(MAIN_CHARACTER_SPRITE, player.x*SPRITE_SIZE, player.y*SPRITE_SIZE);
}

// Pathfinding
Monster Game::chasePlayer(Monster m, Player p){
	Monster nextMonster;

	// TODO: replace
	nextMonster.x = 0;
	nextMonster.y = 0;
	return nextMonster;
}
